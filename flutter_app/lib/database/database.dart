import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../utils/format_utils.dart';
import 'tables.dart';
export 'tables.dart' show GradeScale, Role, newId;

part 'database.g.dart';

/// Thrown when a wall would share its name with another, ignoring case.
class WallNameTaken implements Exception {
  final String name;
  const WallNameTaken(this.name);

  @override
  String toString() => 'A wall called "$name" already exists';
}

/// Thrown when a wall's grade scale would change while one of its problems,
/// in any layout, has a grade from the old scale.
class GradeScaleLocked implements Exception {
  const GradeScaleLocked();

  @override
  String toString() =>
      "The grade scale can't change while any of the wall's problems has a grade";
}

/// Everything [AppDatabase.deleteWall] removed, so [AppDatabase.restoreWall]
/// can put it back with the same ids.
class DeletedWall {
  final Wall                 wall;
  final List<Layout>         layouts;
  final List<WallPhoto>      photos;
  final List<WallPhotoImage> images;
  final List<Problem>        problems;
  final List<Mark>           marks;

  const DeletedWall({
    required this.wall,
    required this.layouts,
    required this.photos,
    required this.images,
    required this.problems,
    required this.marks,
  });
}

/// [name] if no name in [taken] matches it ignoring case, otherwise the first
/// free `name (2)`, `name (3)`, …
String freeName(String name, Iterable<String> taken) {
  final lower = {for (final t in taken) t.toLowerCase()};
  if (!lower.contains(name.toLowerCase())) return name;
  for (var n = 2;; n++) {
    final candidate = '$name ($n)';
    if (!lower.contains(candidate.toLowerCase())) return candidate;
  }
}

@DriftDatabase(tables: [Walls, Layouts, WallPhotos, WallPhotoBytes, Problems, Marks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(
    name: 'spraywall',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ));

  /// Test-only: run against a caller-supplied executor (e.g. in-memory).
  AppDatabase.forTesting(super.e);

  /// A schema version is frozen once a release carries it: change the tables
  /// only by bumping this, dumping the schema and adding a migration step.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // sqlite3 ignores foreign keys unless asked. Without this, a delete that
      // forgets to clean up its children fails silently instead of throwing.
      // Must run outside a transaction — the pragma is a no-op inside one,
      // which is why it lives here rather than in onCreate/onUpgrade.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ── Walls ──────────────────────────────────────────────────────────────

  /// Walls in the user's order.
  Stream<List<Wall>> watchWalls() =>
      (select(walls)..orderBy([(w) => OrderingTerm(expression: w.sortOrder)]))
          .watch();

  /// One wall, or null once it is gone (or never existed).
  Stream<Wall?> watchWall(String id) =>
      (select(walls)..where((w) => w.id.equals(id))).watchSingleOrNull();

  /// The wall's current layout. Every wall has one from the moment it is
  /// created, so this only emits null for a wall that doesn't exist.
  Stream<Layout?> watchCurrentLayout(String wallId) => (select(layouts)
        ..where((l) => l.wallId.equals(wallId) & l.endedOn.isNull()))
      .watchSingleOrNull();

  /// Whether [name] is taken by a wall other than [exceptId], ignoring case.
  ///
  /// Compared in Dart: SQLite's NOCASE only folds ASCII, and a wall called
  /// "Låven" should clash with "LÅVEN".
  Future<bool> wallNameTaken(String name, {String? exceptId}) async {
    final wanted = name.trim().toLowerCase();
    final all    = await select(walls).get();
    return all.any((w) => w.id != exceptId && w.name.toLowerCase() == wanted);
  }

  /// Creates a wall at the end of the list, with its first (empty) current
  /// layout starting on [today]. Returns the new wall's id.
  ///
  /// Throws [WallNameTaken] if the name is in use, ignoring case.
  Future<String> createWall({
    required String     name,
    required GradeScale gradeScale,
    DateTime?           today,
  }) {
    final trimmed = name.trim();
    final date    = dateStrFrom(today ?? DateTime.now());
    return transaction(() async {
      if (await wallNameTaken(trimmed)) throw WallNameTaken(trimmed);
      final maxOrder = walls.sortOrder.max();
      final last     = await (selectOnly(walls)..addColumns([maxOrder]))
          .map((row) => row.read(maxOrder))
          .getSingle();
      final wallId = newId();
      await into(walls).insert(WallsCompanion.insert(
        id:         Value(wallId),
        name:       trimmed,
        gradeScale: gradeScale,
        createdOn:  date,
        sortOrder:  (last ?? -1) + 1,
      ));
      await into(layouts).insert(LayoutsCompanion.insert(
        wallId:    wallId,
        startedOn: date,
      ));
      return wallId;
    });
  }

  /// Whether any problem on the wall, in any layout, has a grade. While one
  /// does, the wall's grade scale is locked.
  Future<bool> wallHasGrades(String wallId) async {
    final query = select(problems).join([
      innerJoin(layouts, layouts.id.equalsExp(problems.layoutId)),
    ])
      ..where(layouts.wallId.equals(wallId) & problems.grade.isNotNull())
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// Renames the wall and sets its grade scale.
  ///
  /// Throws [WallNameTaken] if another wall has the name, ignoring case, and
  /// [GradeScaleLocked] if the scale changes while a problem has a grade.
  Future<void> editWall(
    String id, {
    required String     name,
    required GradeScale gradeScale,
  }) {
    final trimmed = name.trim();
    return transaction(() async {
      if (await wallNameTaken(trimmed, exceptId: id)) {
        throw WallNameTaken(trimmed);
      }
      final wall = await (select(walls)..where((w) => w.id.equals(id)))
          .getSingle();
      if (gradeScale != wall.gradeScale && await wallHasGrades(id)) {
        throw const GradeScaleLocked();
      }
      await (update(walls)..where((w) => w.id.equals(id))).write(
          WallsCompanion(name: Value(trimmed), gradeScale: Value(gradeScale)));
    });
  }

  /// Puts the walls in the order of [ids], which lists every wall.
  Future<void> reorderWalls(List<String> ids) => batch((b) {
        for (var i = 0; i < ids.length; i++) {
          b.update(walls, WallsCompanion(sortOrder: Value(i)),
              where: (w) => w.id.equals(ids[i]));
        }
      });

  /// Deletes the wall and everything under it: its layouts, their photos and
  /// problems, and the problems' marks. Returns what it removed for
  /// [restoreWall].
  Future<DeletedWall> deleteWall(String id) => transaction(() async {
        final wall = await (select(walls)..where((w) => w.id.equals(id)))
            .getSingle();
        final ls = await (select(layouts)..where((l) => l.wallId.equals(id)))
            .get();
        final layoutIds = [for (final l in ls) l.id];
        final ps = await (select(wallPhotos)
              ..where((p) => p.layoutId.isIn(layoutIds)))
            .get();
        final photoIds = [for (final p in ps) p.id];
        final images = await (select(wallPhotoBytes)
              ..where((b) => b.photoId.isIn(photoIds)))
            .get();
        final probs = await (select(problems)
              ..where((p) => p.layoutId.isIn(layoutIds)))
            .get();
        final problemIds = [for (final p in probs) p.id];
        final ms = await (select(marks)
              ..where((m) => m.problemId.isIn(problemIds)))
            .get();

        // Children first: foreign keys are on and nothing cascades.
        await (delete(marks)..where((m) => m.problemId.isIn(problemIds))).go();
        await (delete(problems)..where((p) => p.id.isIn(problemIds))).go();
        await (delete(wallPhotoBytes)..where((b) => b.photoId.isIn(photoIds)))
            .go();
        await (delete(wallPhotos)..where((p) => p.id.isIn(photoIds))).go();
        await (delete(layouts)..where((l) => l.id.isIn(layoutIds))).go();
        await (delete(walls)..where((w) => w.id.equals(id))).go();

        return DeletedWall(
          wall: wall, layouts: ls, photos: ps, images: images,
          problems: probs, marks: ms,
        );
      });

  /// Puts back what [deleteWall] removed, ids and list position included.
  /// If another wall took the name meanwhile, the restored one becomes
  /// `Name (2)`.
  Future<void> restoreWall(DeletedWall d) => transaction(() async {
        final taken = (await select(walls).get()).map((w) => w.name);
        final wall  = d.wall.copyWith(name: freeName(d.wall.name, taken));
        await batch((b) {
          // Parents first.
          b.insert(walls, wall);
          b.insertAll(layouts,        d.layouts);
          b.insertAll(wallPhotos,     d.photos);
          b.insertAll(wallPhotoBytes, d.images);
          b.insertAll(problems,       d.problems);
          b.insertAll(marks,          d.marks);
        });
      });
}

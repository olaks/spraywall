import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../photos/photo_import.dart';
import '../utils/format_utils.dart';
import '../utils/grades.dart';
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

/// Everything [AppDatabase.deleteLayout] removed from an archived layout, so
/// [AppDatabase.restoreLayout] can put it back with the same ids.
class DeletedLayout {
  final Layout               layout;
  final List<WallPhoto>      photos;
  final List<WallPhotoImage> images;
  final List<Problem>        problems;
  final List<Mark>           marks;

  const DeletedLayout({
    required this.layout,
    required this.photos,
    required this.images,
    required this.problems,
    required this.marks,
  });
}

/// What a backup holds, read in one transaction so it is consistent: rows in
/// the order the app shows them, marks in drawing order, and each photo's
/// stored JPEG (not its thumbnail, which import regenerates).
class BackupRows {
  final List<Wall>             walls;
  final List<Layout>           layouts;
  final List<WallPhoto>        photos;
  final List<Problem>          problems;
  final List<Mark>             marks;
  final Map<String, Uint8List> photoData;

  const BackupRows({
    required this.walls,
    required this.layouts,
    required this.photos,
    required this.problems,
    required this.marks,
    required this.photoData,
  });
}

/// How many walls, layouts, photos and problems, for an import's summary.
class BackupCounts {
  final int walls, layouts, photos, problems;
  const BackupCounts({
    this.walls    = 0,
    this.layouts  = 0,
    this.photos   = 0,
    this.problems = 0,
  });
}

/// What [AppDatabase.importBackup] did, for the summary dialog.
class ImportSummary {
  final BackupCounts added;

  /// Rows whose id was already on the device, left as they are (the device
  /// wins). An existing problem's marks are skipped with it.
  final BackupCounts alreadyHere;

  /// New walls and problems whose name was taken: (from, to).
  final List<(String, String)> renamed;

  /// Problems whose grade wasn't on their wall's scale, imported ungraded.
  final int ungraded;

  /// Layouts no longer current because another was on the same wall.
  final int archived;

  const ImportSummary({
    required this.added,
    required this.alreadyHere,
    required this.renamed,
    required this.ungraded,
    required this.archived,
  });
}

/// Thrown, rolling the import back, when a backup's row has an id that is
/// already on this device under a different parent: not the same row.
class BackupClash implements Exception {
  final String what;
  const BackupClash(this.what);

  @override
  String toString() => "This backup can't be merged: $what";
}

/// What a reset did, for [AppDatabase.undoReset].
typedef LayoutReset = ({String archivedId, String newId});

/// An archived layout with what it holds, for the Past layouts list.
typedef PastLayout = ({Layout layout, int problems, int photos});

/// Thrown when a problem would share its name with another in its layout,
/// ignoring case (retired problems included).
class ProblemNameTaken implements Exception {
  final String name;
  const ProblemNameTaken(this.name);

  @override
  String toString() => 'This layout already has a problem called "$name"';
}

/// A mark to write, normalised like a stored [Mark] (see tables.dart).
typedef MarkInput = ({
  String id,
  String photoId,
  Role   role,
  double cx,
  double cy,
  double r,
  String? outline,
});

/// What a problem is besides its marks: the details sheet's fields.
typedef ProblemDetails = ({
  String   name,
  String?  grade,
  String   description,
  DateTime setOn,
});

/// What [AppDatabase.deleteProblem] removed, for [AppDatabase.restoreProblem].
class DeletedProblem {
  final Problem    problem;
  final List<Mark> marks; // in drawing order
  const DeletedProblem({required this.problem, required this.marks});
}

/// Thrown when a photo would be deleted while marks sit on it.
class PhotoInUse implements Exception {
  /// The problems with marks on the photo, by name, retired ones included.
  final List<String> problems;
  const PhotoInUse(this.problems);

  @override
  String toString() => 'Marks on this photo belong to ${problems.join(', ')}';
}

/// What [AppDatabase.deletePhoto] removed, for [AppDatabase.restorePhoto].
class DeletedPhoto {
  final WallPhoto      photo;
  final WallPhotoImage image;
  const DeletedPhoto({required this.photo, required this.image});
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: a mark can be a hold's outline. Existing marks stay circles.
      if (from < 2) await m.addColumn(marks, marks.outline);
    },
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

  /// One layout, current or archived, or null if it doesn't exist.
  Future<Layout?> layout(String id) =>
      (select(layouts)..where((l) => l.id.equals(id))).getSingleOrNull();

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
        final tree = await _takeLayouts([for (final l in ls) l.id]);
        await (delete(walls)..where((w) => w.id.equals(id))).go();
        return DeletedWall(
          wall: wall, layouts: ls, photos: tree.photos, images: tree.images,
          problems: tree.problems, marks: tree.marks,
        );
      });

  /// Reads, then deletes, the layouts [layoutIds] and everything under them,
  /// children first: foreign keys are on and nothing cascades.
  Future<({
    List<WallPhoto>      photos,
    List<WallPhotoImage> images,
    List<Problem>        problems,
    List<Mark>           marks,
  })> _takeLayouts(List<String> layoutIds) async {
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
          ..where((m) => m.problemId.isIn(problemIds))
          ..orderBy([(_) => OrderingTerm(expression: _rowid)]))
        .get();

    await (delete(marks)..where((m) => m.problemId.isIn(problemIds))).go();
    await (delete(problems)..where((p) => p.id.isIn(problemIds))).go();
    await (delete(wallPhotoBytes)..where((b) => b.photoId.isIn(photoIds))).go();
    await (delete(wallPhotos)..where((p) => p.id.isIn(photoIds))).go();
    await (delete(layouts)..where((l) => l.id.isIn(layoutIds))).go();
    return (photos: ps, images: images, problems: probs, marks: ms);
  }

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

  // ── Layouts ────────────────────────────────────────────────────────────

  /// Archives the wall's current layout and starts an empty one on
  /// [startedOn], named [name] (blank is no name), in one transaction. The
  /// old layout ends on the new one's start date, so [startedOn] can't be
  /// before the old layout started.
  Future<LayoutReset> resetLayout(
    String wallId, {
    String?           name,
    required DateTime startedOn,
  }) =>
      transaction(() async {
        final current = await (select(layouts)
              ..where((l) => l.wallId.equals(wallId) & l.endedOn.isNull()))
            .getSingle();
        final start = dateStrFrom(startedOn);
        if (start.compareTo(current.startedOn) < 0) {
          throw ArgumentError.value(start, 'startedOn',
              'is before the current layout started (${current.startedOn})');
        }
        // End the old one first: the partial unique index allows one
        // current layout per wall at any moment.
        await (update(layouts)..where((l) => l.id.equals(current.id)))
            .write(LayoutsCompanion(endedOn: Value(start)));
        final trimmed = name?.trim() ?? '';
        final id = newId();
        await into(layouts).insert(LayoutsCompanion.insert(
          id:        Value(id),
          wallId:    wallId,
          name:      Value(trimmed.isEmpty ? null : trimmed),
          startedOn: start,
        ));
        return (archivedId: current.id, newId: id);
      });

  /// Takes back [reset]: the new layout goes and the archived one is current
  /// again. Only while the new layout is still empty, since undo never
  /// deletes work; returns whether it was undone.
  Future<bool> undoReset(LayoutReset reset) => transaction(() async {
        final fresh = await layout(reset.newId);
        if (fresh == null || fresh.endedOn != null) return false;
        final hasPhoto = await (select(wallPhotos)
              ..where((p) => p.layoutId.equals(reset.newId))
              ..limit(1))
            .getSingleOrNull();
        if (hasPhoto != null) return false;
        await (delete(layouts)..where((l) => l.id.equals(reset.newId))).go();
        await (update(layouts)..where((l) => l.id.equals(reset.archivedId)))
            .write(const LayoutsCompanion(endedOn: Value(null)));
        return true;
      });

  /// The wall's archived layouts, newest first, with their problem and
  /// photo counts.
  Stream<List<PastLayout>> watchPastLayouts(String wallId) => customSelect(
        'SELECT l.*, '
        '(SELECT COUNT(*) FROM problems p WHERE p.layout_id = l.id) AS n_problems, '
        '(SELECT COUNT(*) FROM wall_photos w WHERE w.layout_id = l.id) AS n_photos '
        'FROM layouts l '
        'WHERE l.wall_id = ? AND l.ended_on IS NOT NULL '
        'ORDER BY l.ended_on DESC, l.started_on DESC, l.id DESC',
        variables: [Variable.withString(wallId)],
        readsFrom: {layouts, problems, wallPhotos},
      ).watch().map((rows) => [
            for (final r in rows)
              (
                layout:   layouts.map(r.data),
                problems: r.read<int>('n_problems'),
                photos:   r.read<int>('n_photos'),
              ),
          ]);

  /// Deletes an archived layout with its photos, their bytes, its problems
  /// and their marks. Returns what it removed for [restoreLayout]. The
  /// current layout can't be deleted: a wall always has one.
  Future<DeletedLayout> deleteLayout(String id) => transaction(() async {
        final l = (await layout(id))!;
        if (l.endedOn == null) {
          throw StateError("The current layout can't be deleted");
        }
        final tree = await _takeLayouts([id]);
        return DeletedLayout(
          layout: l, photos: tree.photos, images: tree.images,
          problems: tree.problems, marks: tree.marks,
        );
      });

  /// Puts back what [deleteLayout] removed, ids and drawing order included.
  Future<void> restoreLayout(DeletedLayout d) => batch((b) {
        // Parents first.
        b.insert(layouts, d.layout);
        b.insertAll(wallPhotos,     d.photos);
        b.insertAll(wallPhotoBytes, d.images);
        b.insertAll(problems,       d.problems);
        b.insertAll(marks,          d.marks);
      });

  // ── Wall photos ────────────────────────────────────────────────────────

  /// A layout's photos in the user's order, without their bytes.
  Stream<List<WallPhoto>> watchPhotos(String layoutId) => (select(wallPhotos)
        ..where((p) => p.layoutId.equals(layoutId))
        ..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
      .watch();

  /// One photo's metadata, or null once it is gone.
  Stream<WallPhoto?> watchPhoto(String id) =>
      (select(wallPhotos)..where((p) => p.id.equals(id))).watchSingleOrNull();

  /// How many problems have marks on each of the layout's photos. Photos no
  /// mark uses are missing from the map.
  Stream<Map<String, int>> watchPhotoUsage(String layoutId) {
    final count = marks.problemId.count(distinct: true);
    final query = selectOnly(marks).join([
      innerJoin(wallPhotos, wallPhotos.id.equalsExp(marks.photoId)),
    ])
      ..addColumns([marks.photoId, count])
      ..where(wallPhotos.layoutId.equals(layoutId))
      ..groupBy([marks.photoId]);
    return query.watch().map((rows) => {
          for (final r in rows) r.read(marks.photoId)!: r.read(count)!,
        });
  }

  /// A photo's thumbnail alone, for lists: never loads the full JPEG.
  Future<Uint8List?> photoThumb(String photoId) async {
    final query = selectOnly(wallPhotoBytes)
      ..addColumns([wallPhotoBytes.thumb])
      ..where(wallPhotoBytes.photoId.equals(photoId));
    return (await query.getSingleOrNull())?.read(wallPhotoBytes.thumb);
  }

  /// A photo's JPEG and thumbnail, or null if it is gone.
  Future<WallPhotoImage?> photoImage(String photoId) =>
      (select(wallPhotoBytes)..where((b) => b.photoId.equals(photoId)))
          .getSingleOrNull();

  /// Adds an imported photo at the end of the layout's photos. Returns its id.
  Future<String> addPhoto(
    String        layoutId,
    ImportedPhoto photo, {
    String?       label,
    DateTime?     today,
  }) =>
      transaction(() async {
        final maxOrder = wallPhotos.sortOrder.max();
        final last     = await (selectOnly(wallPhotos)
              ..addColumns([maxOrder])
              ..where(wallPhotos.layoutId.equals(layoutId)))
            .map((row) => row.read(maxOrder))
            .getSingle();
        final id = newId();
        await into(wallPhotos).insert(WallPhotosCompanion.insert(
          id:        Value(id),
          layoutId:  layoutId,
          sortOrder: (last ?? -1) + 1,
          width:     photo.width,
          height:    photo.height,
          addedOn:   dateStrFrom(today ?? DateTime.now()),
          label:     Value(label),
        ));
        await into(wallPhotoBytes).insert(WallPhotoBytesCompanion.insert(
          photoId: id, data: photo.data, thumb: photo.thumb));
        return id;
      });

  /// Sets a photo's label; blank clears it.
  Future<void> setPhotoLabel(String id, String? label) {
    final trimmed = label?.trim();
    return (update(wallPhotos)..where((p) => p.id.equals(id))).write(
        WallPhotosCompanion(
            label: Value(trimmed == null || trimmed.isEmpty ? null : trimmed)));
  }

  /// Puts a layout's photos in the order of [ids], which lists all of them.
  Future<void> reorderPhotos(List<String> ids) => batch((b) {
        for (var i = 0; i < ids.length; i++) {
          b.update(wallPhotos, WallPhotosCompanion(sortOrder: Value(i)),
              where: (p) => p.id.equals(ids[i]));
        }
      });

  /// Deletes a photo no mark sits on. Throws [PhotoInUse], naming the
  /// problems, if any mark does (retired problems count too).
  Future<DeletedPhoto> deletePhoto(String id) => transaction(() async {
        final users = await (selectOnly(problems, distinct: true).join([
          innerJoin(marks, marks.problemId.equalsExp(problems.id)),
        ])
              ..addColumns([problems.name])
              ..where(marks.photoId.equals(id))
              ..orderBy([OrderingTerm(expression: problems.name)]))
            .map((r) => r.read(problems.name)!)
            .get();
        if (users.isNotEmpty) throw PhotoInUse(users);

        final photo = await (select(wallPhotos)..where((p) => p.id.equals(id)))
            .getSingle();
        final image = (await photoImage(id))!;
        await (delete(wallPhotoBytes)..where((b) => b.photoId.equals(id))).go();
        await (delete(wallPhotos)..where((p) => p.id.equals(id))).go();
        return DeletedPhoto(photo: photo, image: image);
      });

  /// Puts back what [deletePhoto] removed, in its old place.
  Future<void> restorePhoto(DeletedPhoto d) => batch((b) {
        b.insert(wallPhotos,     d.photo);
        b.insert(wallPhotoBytes, d.image);
      });

  // ── Problems ───────────────────────────────────────────────────────────

  /// A layout's problems, retired ones included, by name.
  Stream<List<Problem>> watchProblems(String layoutId) => (select(problems)
        ..where((p) => p.layoutId.equals(layoutId))
        ..orderBy([(p) => OrderingTerm(
            expression: p.name.collate(Collate.noCase))]))
      .watch();

  /// One problem, or null once it is gone.
  Stream<Problem?> watchProblem(String id) =>
      (select(problems)..where((p) => p.id.equals(id))).watchSingleOrNull();

  /// Every mark of a layout's problems, in drawing order, for the list's
  /// thumbnails: one query for the whole list rather than one per row.
  Stream<List<Mark>> watchLayoutMarks(String layoutId) => (select(marks)
        ..where((m) => m.problemId.isInQuery(selectOnly(problems)
          ..addColumns([problems.id])
          ..where(problems.layoutId.equals(layoutId))))
        ..orderBy([(_) => OrderingTerm(expression: _rowid)]))
      .watch();

  /// A problem's marks in the order they were placed, which is the order
  /// they draw in.
  Future<List<Mark>> marksOf(String problemId) => _marksOf(problemId).get();

  Stream<List<Mark>> watchMarksOf(String problemId) =>
      _marksOf(problemId).watch();

  SimpleSelectStatement<$MarksTable, Mark> _marksOf(String problemId) =>
      select(marks)
        ..where((m) => m.problemId.equals(problemId))
        ..orderBy([(_) => OrderingTerm(expression: _rowid)]);

  static const _rowid = CustomExpression<int>('rowid');

  /// Whether [name] is taken in [layoutId] by a problem other than
  /// [exceptId], ignoring case. Compared in Dart, like [wallNameTaken].
  Future<bool> problemNameTaken(String layoutId, String name,
      {String? exceptId}) async {
    final wanted = name.trim().toLowerCase();
    final all = await (select(problems)
          ..where((p) => p.layoutId.equals(layoutId)))
        .get();
    return all.any((p) => p.id != exceptId && p.name.toLowerCase() == wanted);
  }

  /// Writes a new problem and its marks in one transaction. Returns its id.
  ///
  /// Throws [ProblemNameTaken] for a name in use in the layout, and
  /// [ArgumentError] for a blank name, no marks, a grade off the wall's
  /// scale, or a mark on a photo from another layout.
  Future<String> createProblem({
    required String          layoutId,
    required String          name,
    String?                  grade,
    String                   description = '',
    required DateTime        setOn,
    required List<MarkInput> marks,
  }) {
    final trimmed = name.trim();
    return transaction(() async {
      await _checkProblem(layoutId, trimmed, grade, marks);
      final id = newId();
      await into(problems).insert(ProblemsCompanion.insert(
        id:          Value(id),
        layoutId:    layoutId,
        name:        trimmed,
        grade:       Value(grade),
        description: Value(description.trim()),
        setOn:       dateStrFrom(setOn),
      ));
      await _insertMarks(id, marks);
      return id;
    });
  }

  /// Replaces a problem's details and marks in one transaction, with the
  /// same checks as [createProblem]. Mark ids are kept where given.
  Future<void> updateProblem(
    String id, {
    required ProblemDetails  details,
    required List<MarkInput> marks,
  }) {
    final trimmed = details.name.trim();
    return transaction(() async {
      final problem = await (select(problems)..where((p) => p.id.equals(id)))
          .getSingle();
      await _checkProblem(problem.layoutId, trimmed, details.grade, marks,
          exceptId: id);
      await (update(problems)..where((p) => p.id.equals(id))).write(
          ProblemsCompanion(
            name:        Value(trimmed),
            grade:       Value(details.grade),
            description: Value(details.description.trim()),
            setOn:       Value(dateStrFrom(details.setOn)),
          ));
      await (delete(this.marks)..where((m) => m.problemId.equals(id))).go();
      await _insertMarks(id, marks);
    });
  }

  /// Deletes a problem and its marks. Returns what it removed for
  /// [restoreProblem].
  Future<DeletedProblem> deleteProblem(String id) => transaction(() async {
        final problem = await (select(problems)..where((p) => p.id.equals(id)))
            .getSingle();
        final ms = await marksOf(id);
        await (delete(marks)..where((m) => m.problemId.equals(id))).go();
        await (delete(problems)..where((p) => p.id.equals(id))).go();
        return DeletedProblem(problem: problem, marks: ms);
      });

  /// Puts back what [deleteProblem] removed, marks in their drawing order. If
  /// another problem in the layout took the name meanwhile, the restored one
  /// becomes `Name (2)`.
  Future<void> restoreProblem(DeletedProblem d) => transaction(() async {
        final taken = (await (select(problems)
                  ..where((p) => p.layoutId.equals(d.problem.layoutId)))
                .get())
            .map((p) => p.name);
        await into(problems).insert(
            d.problem.copyWith(name: freeName(d.problem.name, taken)));
        await batch((b) => b.insertAll(marks, d.marks));
      });

  /// Takes a problem out of use, usually because a hold moved: it stays,
  /// hidden from the list unless "Show retired" is on. Only on the current
  /// layout: an archived one is read-only. Throws [StateError] otherwise.
  Future<void> retireProblem(String id, {DateTime? today}) =>
      _setRetired(id, dateStrFrom(today ?? DateTime.now()));

  /// Puts a retired problem back in use.
  Future<void> unretireProblem(String id) => _setRetired(id, null);

  Future<void> _setRetired(String id, String? on) => transaction(() async {
        final problem = await (select(problems)..where((p) => p.id.equals(id)))
            .getSingle();
        final layout  = await (select(layouts)
              ..where((l) => l.id.equals(problem.layoutId)))
            .getSingle();
        if (layout.endedOn != null) {
          throw StateError("An archived layout's problems are read-only");
        }
        await (update(problems)..where((p) => p.id.equals(id)))
            .write(ProblemsCompanion(retiredOn: Value(on)));
      });

  /// Throws as [createProblem] documents, unless the problem is fine to
  /// write into [layoutId].
  Future<void> _checkProblem(
    String          layoutId,
    String          name,
    String?         grade,
    List<MarkInput> marks, {
    String?         exceptId,
  }) async {
    if (name.isEmpty) throw ArgumentError.value(name, 'name', 'is blank');
    if (marks.isEmpty) throw ArgumentError('A problem needs at least one mark');
    if (await problemNameTaken(layoutId, name, exceptId: exceptId)) {
      throw ProblemNameTaken(name);
    }
    await _checkGrade(layoutId, grade);
    final photoIds = {
      for (final p in await (select(wallPhotos)
            ..where((p) => p.layoutId.equals(layoutId)))
          .get())
        p.id,
    };
    if (!marks.every((m) => photoIds.contains(m.photoId))) {
      throw ArgumentError("A mark's photo must belong to the problem's layout");
    }
  }

  Future<void> _insertMarks(String problemId, List<MarkInput> ms) =>
      batch((b) => b.insertAll(marks, [
            for (final m in ms) _markRow(problemId, m),
          ]));

  /// Appends one mark to a saved problem: a trash undone after the editor
  /// that offered it has saved and closed. Returns false if the problem or
  /// the photo has gone since.
  Future<bool> addMark(String problemId, MarkInput mark) =>
      transaction(() async {
        final problem = await (select(problems)
              ..where((p) => p.id.equals(problemId)))
            .getSingleOrNull();
        final photo = await (select(wallPhotos)
              ..where((p) => p.id.equals(mark.photoId)))
            .getSingleOrNull();
        if (problem == null || photo == null ||
            photo.layoutId != problem.layoutId) {
          return false;
        }
        await into(marks).insert(_markRow(problemId, mark),
            mode: InsertMode.insertOrIgnore);
        return true;
      });

  MarksCompanion _markRow(String problemId, MarkInput m) =>
      MarksCompanion.insert(
        id: Value(m.id), problemId: problemId, photoId: m.photoId,
        role: m.role, cx: m.cx, cy: m.cy, r: m.r,
        outline: Value(m.outline),
      );

  // ── Backups ────────────────────────────────────────────────────────────

  /// Everything, or the wall [wallId] with all its layouts, for a backup. A
  /// fixed number of statements, however much there is.
  Future<BackupRows> backupRows({String? wallId}) => transaction(() async {
        final ws = await (select(walls)
              ..where((w) => wallId == null
                  ? const Constant(true)
                  : w.id.equals(wallId))
              ..orderBy([(w) => OrderingTerm(expression: w.sortOrder)]))
            .get();
        final wallIds = [for (final w in ws) w.id];
        final ls = await (select(layouts)
              ..where((l) => l.wallId.isIn(wallIds))
              ..orderBy([(l) => OrderingTerm(expression: l.startedOn),
                         (l) => OrderingTerm(expression: l.id)]))
            .get();
        final layoutIds = [for (final l in ls) l.id];
        final ps = await (select(wallPhotos)
              ..where((p) => p.layoutId.isIn(layoutIds))
              ..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
            .get();
        final probs = await (select(problems)
              ..where((p) => p.layoutId.isIn(layoutIds))
              ..orderBy([(p) => OrderingTerm(expression: p.name)]))
            .get();
        final ms = await (select(marks)
              ..where((m) => m.problemId.isIn([for (final p in probs) p.id]))
              ..orderBy([(_) => OrderingTerm(expression: _rowid)]))
            .get();
        // Only the full-size bytes: a thumbnail is a quarter of the size
        // again, and import makes its own.
        final data = await (selectOnly(wallPhotoBytes)
              ..addColumns([wallPhotoBytes.photoId, wallPhotoBytes.data])
              ..where(wallPhotoBytes.photoId.isIn([for (final p in ps) p.id])))
            .map((r) => MapEntry(
                r.read(wallPhotoBytes.photoId)!, r.read(wallPhotoBytes.data)!))
            .get();
        return BackupRows(
          walls: ws, layouts: ls, photos: ps, problems: probs, marks: ms,
          photoData: Map.fromEntries(data),
        );
      });

  /// Which of [photoIds] aren't on this device yet: the photos an import
  /// needs thumbnails for.
  Future<Set<String>> newPhotoIds(Iterable<String> photoIds) async {
    final ids  = photoIds.toSet();
    final here = await (selectOnly(wallPhotos)
          ..addColumns([wallPhotos.id])
          ..where(wallPhotos.id.isIn(ids)))
        .map((r) => r.read(wallPhotos.id)!)
        .get();
    return ids.difference(here.toSet());
  }

  /// Merges a checked backup in, all or nothing, and says what it did.
  ///
  /// Rows match by id and the device wins: an id already here is left as it
  /// is, and an existing problem's marks are skipped with it. A new wall, or
  /// a new problem in its layout, whose name is taken becomes `Name (2)`;
  /// new walls go after the device's in the list. A grade off the wall's
  /// scale is dropped. A wall left with two current layouts keeps the later
  /// one current and ends the other on that date (a tie keeps the device's):
  /// the only change made to a row already here. [thumbs] holds a thumbnail
  /// for each new photo.
  ///
  /// Every lookup is made before the loop and the writes go in one batch, so
  /// the statement count doesn't grow with the backup. Throws [BackupClash]
  /// for an id that is here under a different parent.
  Future<ImportSummary> importBackup(
      BackupRows b, Map<String, Uint8List> thumbs) => transaction(() async {
        // ── Lookups ──
        final wallIds    = {for (final w in b.walls) w.id};
        final layoutIds  = {for (final l in b.layouts) l.id};
        final allWalls   = await select(walls).get();
        final hereWalls  = {for (final w in allWalls) w.id: w};
        final hereLayouts = {
          for (final l in await (select(layouts)
                ..where((l) => l.id.isIn(layoutIds)))
              .get())
            l.id: l,
        };
        final currents = {
          for (final l in await (select(layouts)
                ..where((l) => l.wallId.isIn(wallIds) & l.endedOn.isNull()))
              .get())
            l.wallId: l,
        };
        final herePhotos = {
          for (final p in await (select(wallPhotos)
                ..where((p) => p.id.isIn([for (final p in b.photos) p.id])))
              .get())
            p.id: p,
        };
        final hereProblems = {
          for (final p in await (select(problems)
                ..where((p) => p.id.isIn([for (final p in b.problems) p.id])))
              .get())
            p.id: p,
        };
        final hereMarks = (await (selectOnly(marks)
                  ..addColumns([marks.id])
                  ..where(marks.id.isIn([for (final m in b.marks) m.id])))
                .map((r) => r.read(marks.id)!)
                .get())
            .toSet();
        // What the layouts already here hold: photo order and problem names.
        final photoOrders = <String, List<int>>{};
        for (final r in await (selectOnly(wallPhotos)
              ..addColumns([wallPhotos.layoutId, wallPhotos.sortOrder])
              ..where(wallPhotos.layoutId.isIn(hereLayouts.keys)))
            .get()) {
          final String layoutId = r.read(wallPhotos.layoutId)!;
          (photoOrders[layoutId] ??= []).add(r.read(wallPhotos.sortOrder)!);
        }
        final namesIn = <String, List<String>>{};
        for (final r in await (selectOnly(problems)
              ..addColumns([problems.layoutId, problems.name])
              ..where(problems.layoutId.isIn(hereLayouts.keys)))
            .get()) {
          final String layoutId = r.read(problems.layoutId)!;
          (namesIn[layoutId] ??= []).add(r.read(problems.name)!);
        }

        // ── Merge ──
        final renamed  = <(String, String)>[];
        var   ungraded = 0, archived = 0;
        final scaleOf  = <String, GradeScale>{};   // wall id → its scale
        final wallOf   = {for (final l in b.layouts) l.id: l.wallId};

        // New walls keep their order among themselves, after the device's.
        final newWalls = [
          for (final w in b.walls) if (!hereWalls.containsKey(w.id)) w,
        ];
        final wallShift = _appendShift(
            [for (final w in allWalls) w.sortOrder],
            [for (final w in newWalls) w.sortOrder]);
        final takenWalls = [for (final w in allWalls) w.name];
        final addWalls   = <Wall>[];
        for (final w in b.walls) {
          final here = hereWalls[w.id];
          if (here != null) {
            scaleOf[w.id] = here.gradeScale;
            continue;
          }
          final name = freeName(w.name, takenWalls);
          if (name != w.name) renamed.add((w.name, name));
          takenWalls.add(name);
          scaleOf[w.id] = w.gradeScale;
          addWalls.add(w.copyWith(name: name, sortOrder: w.sortOrder + wallShift));
        }

        final endHere    = <(String, String)>[];   // (layout id, ended on)
        final addLayouts = <Layout>[];
        for (var l in b.layouts) {
          final here = hereLayouts[l.id];
          if (here != null) {
            if (here.wallId != l.wallId) {
              throw BackupClash('a layout is on a different wall here');
            }
            continue;
          }
          final current = currents[l.wallId];
          if (l.endedOn == null && current != null) {
            archived++;
            if (l.startedOn.compareTo(current.startedOn) > 0) {
              endHere.add((current.id, l.startedOn));
              currents[l.wallId] = l;
            } else {
              l = l.copyWith(endedOn: Value(current.startedOn));
            }
          } else if (l.endedOn == null) {
            currents[l.wallId] = l;
          }
          addLayouts.add(l);
        }

        // Photos added to a layout already here go after its own.
        final newPhotosIn = <String, List<int>>{};
        for (final p in b.photos) {
          if (!herePhotos.containsKey(p.id)) {
            (newPhotosIn[p.layoutId] ??= []).add(p.sortOrder);
          }
        }
        final photoShift = {
          for (final MapEntry(key: id, value: orders) in newPhotosIn.entries)
            id: _appendShift(photoOrders[id] ?? const [], orders),
        };
        final addPhotos = <WallPhoto>[];
        final addBytes  = <WallPhotoImage>[];
        for (final p in b.photos) {
          final here = herePhotos[p.id];
          if (here != null) {
            if (here.layoutId != p.layoutId) {
              throw BackupClash('a photo is in a different layout here');
            }
            continue;
          }
          addPhotos.add(p.copyWith(sortOrder: p.sortOrder + photoShift[p.layoutId]!));
          addBytes.add(WallPhotoImage(
            photoId: p.id,
            data:    b.photoData[p.id]!,
            thumb:   thumbs[p.id] ??
                (throw StateError('No thumbnail for the new photo ${p.id}')),
          ));
        }

        final skipped     = <String>{};   // problems here: their marks too
        final addProblems = <Problem>[];
        for (var p in b.problems) {
          final here = hereProblems[p.id];
          if (here != null) {
            if (here.layoutId != p.layoutId) {
              throw BackupClash('a problem is in a different layout here');
            }
            skipped.add(p.id);
            continue;
          }
          final taken = namesIn[p.layoutId] ??= [];
          final name  = freeName(p.name, taken);
          if (name != p.name) renamed.add((p.name, name));
          taken.add(name);
          final scale = gradesFor(scaleOf[wallOf[p.layoutId]]!);
          final off   = p.grade != null && !scale.contains(p.grade);
          if (off) ungraded++;
          addProblems.add(p.copyWith(
              name: name, grade: off ? const Value(null) : Value(p.grade)));
        }

        final addMarks = <Mark>[];
        for (final m in b.marks) {
          if (skipped.contains(m.problemId)) continue;
          if (hereMarks.contains(m.id)) {
            throw BackupClash('a mark is on a different problem here');
          }
          addMarks.add(m);
        }

        // ── Write: one batch, layouts ended before the new current ones go
        // in (one current layout per wall at every statement), parents
        // first, marks in drawing order. ──
        await batch((bt) {
          for (final (id, on) in endHere) {
            bt.update(layouts, LayoutsCompanion(endedOn: Value(on)),
                where: (l) => l.id.equals(id));
          }
          bt.insertAll(walls,          addWalls);
          bt.insertAll(layouts,        addLayouts);
          bt.insertAll(wallPhotos,     addPhotos);
          bt.insertAll(wallPhotoBytes, addBytes);
          bt.insertAll(problems,       addProblems);
          bt.insertAll(marks,          addMarks);
        });

        return ImportSummary(
          added: BackupCounts(
            walls: addWalls.length, layouts: addLayouts.length,
            photos: addPhotos.length, problems: addProblems.length,
          ),
          alreadyHere: BackupCounts(
            walls:    b.walls.length    - addWalls.length,
            layouts:  b.layouts.length  - addLayouts.length,
            photos:   b.photos.length   - addPhotos.length,
            problems: b.problems.length - addProblems.length,
          ),
          renamed:  renamed,
          ungraded: ungraded,
          archived: archived,
        );
      });

  /// How far to move [incoming] sort orders so they follow [here]'s, keeping
  /// their own order and gaps. Nothing here: they stay as they are, so a
  /// backup restored into an empty app comes back identical.
  static int _appendShift(List<int> here, List<int> incoming) {
    if (here.isEmpty || incoming.isEmpty) return 0;
    final top = here.reduce((a, b) => a > b ? a : b);
    final low = incoming.reduce((a, b) => a < b ? a : b);
    return top + 1 - low;
  }

  /// Throws [ArgumentError] unless [grade] is null or on the scale of the
  /// layout's wall.
  Future<void> _checkGrade(String layoutId, String? grade) async {
    if (grade == null) return;
    final wall = await (select(walls).join([
      innerJoin(layouts, layouts.wallId.equalsExp(walls.id)),
    ])..where(layouts.id.equals(layoutId)))
        .map((r) => r.readTable(walls))
        .getSingle();
    if (!gradesFor(wall.gradeScale).contains(grade)) {
      throw ArgumentError.value(grade, 'grade', 'is not on the wall\'s scale');
    }
  }
}

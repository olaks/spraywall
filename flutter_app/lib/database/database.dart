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
}

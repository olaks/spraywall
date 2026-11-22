import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/photos/photo_import.dart';

import 'images.dart';

/// A fresh in-memory database. Foreign keys are on, as in the app: the pragma
/// runs in `beforeOpen`, which drift calls on first use.
AppDatabase openTestDb({QueryInterceptor? interceptor}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final executor = NativeDatabase.memory();
  return AppDatabase.forTesting(
      interceptor == null ? executor : executor.interceptWith(interceptor));
}

/// A wall with its first current layout, made through the app's own API so the
/// seed can't drift from the schema. Returns the wall's id.
Future<String> seedWall(
  AppDatabase db, {
  String     name       = 'Home wall',
  GradeScale gradeScale = GradeScale.font,
  DateTime?  today,
}) =>
    db.createWall(name: name, gradeScale: gradeScale, today: today);

/// A wall photo added to [layoutId] through the real import, from a small
/// generated JPEG. Returns the photo's id.
Future<String> seedPhoto(
  AppDatabase db,
  String      layoutId, {
  String?     label,
  int         width  = 40,
  int         height = 30,
}) =>
    db.addPhoto(layoutId, importPhoto(jpegFixture(width: width, height: height)),
        label: label);

/// A problem on [layoutId] through the real create. [marks] are
/// (photo id, role) pairs, placed in order across the photo; by default one
/// hand mark on the layout's first photo, which is seeded if there is none.
/// Returns the problem's id.
Future<String> seedProblem(
  AppDatabase          db,
  String               layoutId, {
  String               name  = 'Arête',
  String?              grade,
  DateTime?            setOn,
  List<(String, Role)>? marks,
}) async {
  final pairs = marks ?? [
    ((await db.watchPhotos(layoutId).first).firstOrNull?.id ??
        await seedPhoto(db, layoutId), Role.hand),
  ];
  return db.createProblem(
    layoutId: layoutId,
    name:     name,
    grade:    grade,
    setOn:    setOn ?? DateTime(2026, 11, 22),
    marks: [
      for (final (i, (photoId, role)) in pairs.indexed)
        (id: newId(), photoId: photoId, role: role,
         cx: (i + 1) / (pairs.length + 1), cy: 0.5, r: 0.02),
    ],
  );
}

/// The id of the wall's current layout.
Future<String> currentLayoutId(AppDatabase db, String wallId) async =>
    (await db.watchCurrentLayout(wallId).first)!.id;

/// Counts every statement that reaches the database, so a test can check
/// that an import's cost doesn't grow with its row count.
class StatementCounter extends QueryInterceptor {
  var count = 0;

  @override
  Future<void> runBatched(QueryExecutor executor, BatchedStatements statements) {
    count++;
    return super.runBatched(executor, statements);
  }

  @override
  Future<void> runCustom(QueryExecutor executor, String statement, List<Object?> args) {
    count++;
    return super.runCustom(executor, statement, args);
  }

  @override
  Future<int> runInsert(QueryExecutor executor, String statement, List<Object?> args) {
    count++;
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(QueryExecutor executor, String statement, List<Object?> args) {
    count++;
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(QueryExecutor executor, String statement, List<Object?> args) {
    count++;
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    count++;
    return super.runSelect(executor, statement, args);
  }
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:spraywall/database/database.dart';

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

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/test_db.dart';

/// Deletes clear their own children and hand back a snapshot for undo. That
/// only stays honest if the database refuses to orphan a row, so a delete that
/// forgets a child fails loudly instead of leaving it behind.
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  test('a layout can only point at a wall that exists', () async {
    await expectLater(
      db.into(db.layouts).insert(LayoutsCompanion.insert(
          wallId: newId(), startedOn: '2026-11-22')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a wall with a layout cannot be deleted out from under it', () async {
    final wallId = await seedWall(db);
    await expectLater(
      (db.delete(db.walls)..where((w) => w.id.equals(wallId))).go(),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a mark needs both its problem and its photo', () async {
    final wallId = await seedWall(db);
    final layout = (await db.watchCurrentLayout(wallId).first)!;
    final problemId = newId();
    await db.into(db.problems).insert(ProblemsCompanion.insert(
        id: Value(problemId), layoutId: layout.id, name: 'P',
        setOn: '2026-11-22'));
    await expectLater(
      db.into(db.marks).insert(MarksCompanion.insert(
          problemId: problemId, photoId: newId(), role: Role.start,
          cx: 0.5, cy: 0.5, r: 0.02)),
      throwsA(isA<SqliteException>()),
    );
  });
}

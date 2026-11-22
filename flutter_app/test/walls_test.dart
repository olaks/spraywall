import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/test_db.dart';

/// Creating a wall: it lands at the end of the list with an empty current
/// layout, and its name never clashes with another wall's, ignoring case.
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  test('a new wall gets a current layout starting today', () async {
    final id = await db.createWall(
        name: '  Home wall ', gradeScale: GradeScale.v,
        today: DateTime(2026, 11, 22));

    final wall = (await db.watchWall(id).first)!;
    expect(wall.name, 'Home wall', reason: 'the name is trimmed');
    expect(wall.gradeScale, GradeScale.v);
    expect(wall.createdOn, '2026-11-22');

    final layout = (await db.watchCurrentLayout(id).first)!;
    expect(layout.startedOn, '2026-11-22');
    expect(layout.endedOn, isNull);
    expect(layout.name, isNull);
  });

  test('ids are UUIDv7', () async {
    final id = await seedWall(db);
    expect(id, matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });

  test('new walls go to the end of the list', () async {
    await seedWall(db, name: 'B');
    await seedWall(db, name: 'A');
    await seedWall(db, name: 'C');
    expect((await db.watchWalls().first).map((w) => w.name), ['B', 'A', 'C']);
  });

  test('a name taken ignoring case is refused, beyond ASCII too', () async {
    await seedWall(db, name: 'Låven');
    await expectLater(seedWall(db, name: 'LÅVEN'),
        throwsA(isA<WallNameTaken>()));
    await expectLater(seedWall(db, name: ' låven '),
        throwsA(isA<WallNameTaken>()));
    expect(await db.watchWalls().first, hasLength(1),
        reason: 'a refused wall leaves nothing behind');
  });
}

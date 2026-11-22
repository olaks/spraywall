import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/test_db.dart';

/// Reset and past layouts: a reset archives the current layout and starts an
/// empty one, undoable while that one is still empty; archived layouts list
/// with their counts, and delete and restore whole.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      first;
  setUp(() async {
    db    = openTestDb();
    wall  = await seedWall(db);
    first = await currentLayoutId(db, wall);
  });
  tearDown(() => db.close());

  Future<String> current() => currentLayoutId(db, wall);
  Future<List<PastLayout>> past() => db.watchPastLayouts(wall).first;

  group('reset', () {
    test('archives the current layout, with everything on it, and starts an '
        'empty one', () async {
      final photo = await seedPhoto(db, first);
      await seedProblem(db, first, marks: [(photo, Role.start)]);

      final reset = await db.resetLayout(wall,
          name: '  Winter set ', startedOn: DateTime(2026, 12, 1));

      final now = (await db.layout(await current()))!;
      expect(now.id, reset.newId);
      expect(now.name, 'Winter set');
      expect(now.startedOn, '2026-12-01');
      expect(await db.watchPhotos(now.id).first, isEmpty);
      expect(await db.watchProblems(now.id).first, isEmpty);

      final old = (await db.layout(first))!;
      expect(old.endedOn, '2026-12-01', reason: 'ends as the new one starts');
      expect(await db.watchProblems(first).first, hasLength(1),
          reason: 'archived, not deleted');
    });

    test('a blank name is no name', () async {
      await db.resetLayout(wall, name: '  ', startedOn: DateTime(2026, 12, 1));
      expect((await db.layout(await current()))!.name, isNull);
    });

    test('may start the same day, not before the current layout started',
        () async {
      final started = (await db.layout(first))!.startedOn;
      await expectLater(
          db.resetLayout(wall, startedOn: DateTime(2000)),
          throwsArgumentError);
      expect(await current(), first, reason: 'nothing changed');

      await db.resetLayout(wall, startedOn: DateTime.parse(started));
      expect(await current(), isNot(first));
    });

    test('undo makes the archived layout current again', () async {
      await seedProblem(db, first, name: 'Arête');
      final reset = await db.resetLayout(wall, startedOn: DateTime(2026, 12, 1));

      expect(await db.undoReset(reset), isTrue);
      expect(await current(), first);
      expect((await db.layout(first))!.endedOn, isNull);
      expect(await db.layout(reset.newId), isNull);
      expect(await past(), isEmpty);
    });

    test('undo refuses once the new layout has a photo', () async {
      final reset = await db.resetLayout(wall, startedOn: DateTime(2026, 12, 1));
      await seedPhoto(db, reset.newId);

      expect(await db.undoReset(reset), isFalse);
      expect(await current(), reset.newId, reason: 'no work is deleted');
      expect((await db.layout(first))!.endedOn, '2026-12-01');
    });
  });

  test('past layouts: newest first, with problem and photo counts, never '
      'the current one', () async {
    await seedPhoto(db, first);
    await seedProblem(db, first, name: 'A');
    await seedProblem(db, first, name: 'B');
    final r1 = await db.resetLayout(wall, startedOn: DateTime(2026, 12, 1));
    final r2 = await db.resetLayout(wall,
        name: 'Spring', startedOn: DateTime(2027, 3, 1));
    // Another wall's layouts stay out.
    await db.resetLayout(await seedWall(db, name: 'Other'),
        startedOn: DateTime(2027, 1, 1));

    final list = await past();
    expect(list.map((p) => p.layout.id), [r2.archivedId, r1.archivedId]);
    expect(list.map((p) => p.layout.id), isNot(contains(r2.newId)));
    expect((list.last.problems, list.last.photos), (2, 1));
    expect((list.first.problems, list.first.photos), (0, 0));
    expect(list.first.layout.endedOn, '2027-03-01');
  });

  group('delete', () {
    test('an archived layout goes with everything under it, and undo '
        'restores identical rows', () async {
      final photo = await seedPhoto(db, first);
      await seedProblem(db, first, name: 'A',
          marks: [(photo, Role.start), (photo, Role.hand), (photo, Role.finish)]);
      await seedProblem(db, first, name: 'B', marks: [(photo, Role.foot)]);
      await db.resetLayout(wall, startedOn: DateTime(2026, 12, 1));
      // The new current layout keeps its own photo through all this.
      await seedPhoto(db, await current());

      Future<List<Object>> rows() async => [
            ...await db.select(db.layouts).get(),
            ...await db.select(db.wallPhotos).get(),
            ...await db.select(db.wallPhotoBytes).get(),
            ...await db.select(db.problems).get(),
            ...await db.select(db.marks).get(),
          ];
      final before = await rows();
      final drawn  = (await db.watchLayoutMarks(first).first).map((m) => m.id);

      final deleted = await db.deleteLayout(first);
      expect(await db.layout(first), isNull);
      expect(await db.select(db.marks).get(), isEmpty);
      expect(await db.select(db.wallPhotos).get(), hasLength(1));
      expect(await past(), isEmpty);

      await db.restoreLayout(deleted);
      expect((await rows()).toSet(), before.toSet());
      expect((await db.watchLayoutMarks(first).first).map((m) => m.id), drawn,
          reason: 'marks keep their drawing order');
    });

    test("the current layout can't be deleted", () async {
      await seedPhoto(db, first);
      await expectLater(db.deleteLayout(first), throwsStateError);
      expect(await db.watchPhotos(first).first, hasLength(1));
    });
  });
}

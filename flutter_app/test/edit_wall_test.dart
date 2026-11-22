
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/test_db.dart';

/// Editing a wall: rename, grade scale (locked once anything is graded),
/// order, and delete with an undo that puts back every row it took.
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  Future<Wall> wallById(String id) async => (await db.watchWall(id).first)!;

  // Photos and problems have no API until tickets 03 and 04, so these insert
  // rows directly. Swap them for the real calls once those land.
  Future<String> addLayout(String wallId, {String? endedOn}) async {
    final id = newId();
    await db.into(db.layouts).insert(LayoutsCompanion.insert(
        id: Value(id), wallId: wallId, startedOn: '2025-01-01',
        endedOn: Value(endedOn)));
    return id;
  }

  Future<String> addPhoto(String layoutId, {int sortOrder = 0}) async {
    final id = newId();
    await db.into(db.wallPhotos).insert(WallPhotosCompanion.insert(
        id: Value(id), layoutId: layoutId, sortOrder: sortOrder,
        width: 2560, height: 1920, addedOn: '2025-01-02'));
    await db.into(db.wallPhotoBytes).insert(WallPhotoBytesCompanion.insert(
        photoId: id,
        data: Uint8List.fromList([1, 2, 3, sortOrder]),
        thumb: Uint8List.fromList([4, 5, sortOrder])));
    return id;
  }

  Future<String> addProblem(String layoutId, String name, {String? grade}) async {
    final id = newId();
    await db.into(db.problems).insert(ProblemsCompanion.insert(
        id: Value(id), layoutId: layoutId, name: name,
        grade: Value(grade), setOn: '2025-01-03'));
    return id;
  }

  Future<void> addMark(String problemId, String photoId, Role role) =>
      db.into(db.marks).insert(MarksCompanion.insert(
          problemId: problemId, photoId: photoId, role: role,
          cx: 0.25, cy: 0.5, r: 0.03));

  Future<String> currentLayoutId(String wallId) async =>
      (await db.watchCurrentLayout(wallId).first)!.id;

  group('rename', () {
    test('trims, and may change only the case of its own name', () async {
      final id = await seedWall(db, name: 'Home wall');
      await db.editWall(id, name: ' HOME WALL ', gradeScale: GradeScale.font);
      expect((await wallById(id)).name, 'HOME WALL');
    });

    test("refuses another wall's name, ignoring case", () async {
      await seedWall(db, name: 'Låven');
      final id = await seedWall(db, name: 'Garage');
      await expectLater(
          db.editWall(id, name: 'LÅVEN', gradeScale: GradeScale.font),
          throwsA(isA<WallNameTaken>()));
      expect((await wallById(id)).name, 'Garage');
    });
  });

  group('grade scale', () {
    test('changes while no problem has a grade', () async {
      final id = await seedWall(db);
      await addProblem(await currentLayoutId(id), 'Ungraded');
      expect(await db.wallHasGrades(id), isFalse);
      await db.editWall(id, name: 'Home wall', gradeScale: GradeScale.v);
      expect((await wallById(id)).gradeScale, GradeScale.v);
    });

    test('is locked by a grade in a past layout too', () async {
      final id   = await seedWall(db);
      final past = await addLayout(id, endedOn: '2025-06-01');
      await addProblem(past, 'Old one', grade: '6A');
      expect(await db.wallHasGrades(id), isTrue);

      await expectLater(
          db.editWall(id, name: 'Renamed', gradeScale: GradeScale.v),
          throwsA(isA<GradeScaleLocked>()));
      expect((await wallById(id)).name, 'Home wall',
          reason: 'a refused edit changes nothing');

      // Renaming alone is still fine.
      await db.editWall(id, name: 'Renamed', gradeScale: GradeScale.font);
      expect((await wallById(id)).name, 'Renamed');
    });

    test("another wall's grades don't lock it", () async {
      final other = await seedWall(db, name: 'Other');
      await addProblem(await currentLayoutId(other), 'P', grade: '7A');
      expect(await db.wallHasGrades(await seedWall(db)), isFalse);
    });
  });

  test('reordering persists', () async {
    final a = await seedWall(db, name: 'A');
    final b = await seedWall(db, name: 'B');
    final c = await seedWall(db, name: 'C');
    await db.reorderWalls([c, a, b]);
    expect((await db.watchWalls().first).map((w) => w.name), ['C', 'A', 'B']);
  });

  group('delete', () {
    /// A wall with a current and a past layout, photos, problems and marks.
    Future<String> fullWall(String name) async {
      final id      = await seedWall(db, name: name);
      final current = await currentLayoutId(id);
      final past    = await addLayout(id, endedOn: '2025-06-01');
      for (final layout in [current, past]) {
        final p1 = await addPhoto(layout);
        final p2 = await addPhoto(layout, sortOrder: 1);
        final a  = await addProblem(layout, 'Arête', grade: '6B');
        final b  = await addProblem(layout, 'Crimps');
        await addMark(a, p1, Role.start);
        await addMark(a, p2, Role.finish);
        await addMark(b, p1, Role.foot);
      }
      return id;
    }

    /// Every row of every table, so a round trip can be compared whole.
    Future<List<List<Object>>> everything() async => [
          await db.select(db.walls).get(),
          await db.select(db.layouts).get(),
          await db.select(db.wallPhotos).get(),
          await db.select(db.wallPhotoBytes).get(),
          await db.select(db.problems).get(),
          await db.select(db.marks).get(),
        ];

    test('takes everything under the wall, and undo restores identical rows',
        () async {
      final id    = await fullWall('Home wall');
      await fullWall('Other wall');
      final before = await everything();

      final deleted = await db.deleteWall(id);
      expect(deleted.layouts,  hasLength(2));
      expect(deleted.photos,   hasLength(4));
      expect(deleted.images,   hasLength(4));
      expect(deleted.problems, hasLength(4));
      expect(deleted.marks,    hasLength(6));

      final after = await everything();
      expect(after.map((rows) => rows.length), [1, 2, 4, 4, 4, 6],
          reason: 'only the other wall is left');

      await db.restoreWall(deleted);
      final restored = await everything();
      for (var t = 0; t < before.length; t++) {
        expect(restored[t].toSet(), before[t].toSet(), reason: 'table $t');
      }
    });

    test('undo goes back to the same place in the list', () async {
      await seedWall(db, name: 'A');
      final b = await seedWall(db, name: 'B');
      await seedWall(db, name: 'C');
      await db.restoreWall(await db.deleteWall(b));
      expect((await db.watchWalls().first).map((w) => w.name), ['A', 'B', 'C']);
    });

    test('undo after the name was reused restores as "Name (2)"', () async {
      final id      = await seedWall(db, name: 'Home wall');
      final deleted = await db.deleteWall(id);
      await seedWall(db, name: 'home wall');
      await db.restoreWall(deleted);
      expect((await db.watchWalls().first).map((w) => w.name),
          containsAll(['home wall', 'Home wall (2)']));
    });
  });

  test('freeName counts up past taken names, ignoring case', () {
    expect(freeName('Wall', []), 'Wall');
    expect(freeName('Wall', ['wall']), 'Wall (2)');
    expect(freeName('Wall', ['WALL', 'wall (2)']), 'Wall (3)');
  });
}

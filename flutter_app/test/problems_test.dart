import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/test_db.dart';

/// Creating a problem: one transaction for the problem and its marks, a name
/// unique in its layout ignoring case, a grade from the wall's scale, and
/// marks only on the layout's own photos.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  late String      photo;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, gradeScale: GradeScale.font);
    layout = await currentLayoutId(db, wall);
    photo  = await seedPhoto(db, layout);
  });
  tearDown(() => db.close());

  MarkInput mark(Role role, {String? onPhoto, double cx = 0.5}) => (
        id: newId(), photoId: onPhoto ?? photo, role: role,
        cx: cx, cy: 0.5, r: 0.02,
      );

  Future<String> create(String name, {String? grade, List<MarkInput>? marks}) =>
      db.createProblem(
        layoutId: layout, name: name, grade: grade,
        description: '  Sit start. ', setOn: DateTime(2026, 11, 22),
        marks: marks ?? [mark(Role.start)],
      );

  test("a layout's marks: all its problems', in drawing order, and no "
      "other layout's", () async {
    final a = await create('A', marks: [mark(Role.start), mark(Role.foot)]);
    final b = await create('B', marks: [mark(Role.hand)]);
    final other  = await currentLayoutId(db, await seedWall(db, name: 'Other'));
    await seedProblem(db, other, marks: [(await seedPhoto(db, other), Role.hand)]);

    final ms = await db.watchLayoutMarks(layout).first;
    expect(ms.map((m) => (m.problemId, m.role)),
        [(a, Role.start), (a, Role.foot), (b, Role.hand)]);
  });

  test('stores the details and the marks in the order placed', () async {
    final roles = [Role.start, Role.hand, Role.foot, Role.hand, Role.finish];
    final id = await create(' Arête ', grade: '6B', marks: [
      for (final (i, r) in roles.indexed) mark(r, cx: i / 10),
    ]);

    final p = (await db.watchProblems(layout).first).single;
    expect((p.id, p.name, p.grade, p.description, p.setOn, p.retiredOn),
        (id, 'Arête', '6B', 'Sit start.', '2026-11-22', null));
    final stored = await db.marksOf(id);
    expect(stored.map((m) => m.role), roles);
    expect(stored.map((m) => m.cx), [0.0, 0.1, 0.2, 0.3, 0.4]);
  });

  test('a name taken in the layout is refused ignoring case, beyond ASCII',
      () async {
    await create('Åsen');
    await expectLater(create('ÅSEN'), throwsA(isA<ProblemNameTaken>()));
    expect(await db.watchProblems(layout).first, hasLength(1));
    expect(await db.select(db.marks).get(), hasLength(1),
        reason: 'a refused problem writes no marks');
  });

  test('the same name is fine on another wall', () async {
    await create('Arête');
    final other = await currentLayoutId(db, await seedWall(db, name: 'Other'));
    await seedProblem(db, other, name: 'Arête');
  });

  test('needs a name and at least one mark', () async {
    await expectLater(create('   '), throwsArgumentError);
    await expectLater(create('Empty', marks: []), throwsArgumentError);
    expect(await db.watchProblems(layout).first, isEmpty);
  });

  test("the grade must be on the wall's scale, or none", () async {
    await expectLater(create('V-graded', grade: 'V4'), throwsArgumentError);
    await create('Ungraded');
    expect((await db.watchProblems(layout).first).single.grade, isNull);
  });

  test("a mark on another layout's photo is refused", () async {
    final other = await currentLayoutId(db, await seedWall(db, name: 'Other'));
    final elsewhere = await seedPhoto(db, other);
    await expectLater(
        create('Stray', marks: [mark(Role.start, onPhoto: elsewhere)]),
        throwsArgumentError);
  });

  group('addMark (a trash undone after the editor saved)', () {
    test('appends the mark to the saved problem', () async {
      final id = await create('Arête');
      final m  = mark(Role.finish, cx: 0.9);
      expect(await db.addMark(id, m), isTrue);
      expect((await db.marksOf(id)).last.id, m.id);
    });

    test('does nothing once the photo is gone or belongs elsewhere', () async {
      final id    = await create('Arête');
      final other = await currentLayoutId(db, await seedWall(db, name: 'Other'));
      expect(await db.addMark(id, mark(Role.hand, onPhoto: await seedPhoto(db, other))),
          isFalse);
      expect(await db.addMark(newId(), mark(Role.hand)), isFalse,
          reason: 'no such problem');
      expect(await db.marksOf(id), hasLength(1));
    });
  });

  group('update', () {
    test('replaces details and marks, keeping mark ids where given', () async {
      final id   = await create('Arête', grade: '6A');
      final kept = (await db.marksOf(id)).single;
      final next = mark(Role.finish, cx: 0.9);
      await db.updateProblem(id,
          details: (name: 'Arête direct', grade: '6B+',
                    description: 'Stand start', setOn: DateTime(2026, 11, 1)),
          marks: [
            (id: kept.id, photoId: kept.photoId, role: Role.hand,
             cx: kept.cx, cy: kept.cy, r: kept.r),
            next,
          ]);

      final p = (await db.watchProblem(id).first)!;
      expect((p.name, p.grade, p.description, p.setOn),
          ('Arête direct', '6B+', 'Stand start', '2026-11-01'));
      final stored = await db.marksOf(id);
      expect(stored.map((m) => (m.id, m.role)),
          [(kept.id, Role.hand), (next.id, Role.finish)]);
    });

    test('may keep its own name in another case, not take another', () async {
      final id = await create('Arête');
      await create('Crimps');
      ProblemDetails named(String n) =>
          (name: n, grade: null, description: '', setOn: DateTime(2026, 11, 22));
      await db.updateProblem(id, details: named('ARÊTE'), marks: [mark(Role.start)]);
      await expectLater(
          db.updateProblem(id, details: named('crimps'), marks: [mark(Role.start)]),
          throwsA(isA<ProblemNameTaken>()));
      expect((await db.watchProblem(id).first)!.name, 'ARÊTE');
      expect(await db.marksOf(id), hasLength(1),
          reason: 'a refused update leaves the marks as they were');
    });
  });

  group('delete', () {
    test('takes the marks too, and undo restores identical rows', () async {
      final id = await create('Arête', marks: [
        mark(Role.start, cx: 0.1), mark(Role.hand, cx: 0.2), mark(Role.finish, cx: 0.3),
      ]);
      await create('Crimps');
      final problemsBefore = await db.select(db.problems).get();
      final marksBefore    = await db.marksOf(id);

      final deleted = await db.deleteProblem(id);
      expect(await db.watchProblem(id).first, isNull);
      expect(await db.select(db.marks).get(), hasLength(1),
          reason: "only Crimps' mark is left");

      await db.restoreProblem(deleted);
      expect((await db.select(db.problems).get()).toSet(), problemsBefore.toSet());
      expect(await db.marksOf(id), marksBefore, reason: 'same rows, same order');
    });

    test('undo after the name was reused restores as "Name (2)"', () async {
      final deleted = await db.deleteProblem(await create('Arête'));
      await create('arête');
      await db.restoreProblem(deleted);
      expect((await db.watchProblems(layout).first).map((p) => p.name),
          containsAll(['arête', 'Arête (2)']));
    });
  });
}

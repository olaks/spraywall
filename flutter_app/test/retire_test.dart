import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/utils/format_utils.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// Retiring a problem whose hold moved: hidden from the list unless "Show
/// retired" is on, read-only apart from Un-retire and Delete.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  late String      arete;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, name: 'Home wall');
    layout = await currentLayoutId(db, wall);
    final photo = await seedPhoto(db, layout);
    arete  = await seedProblem(db, layout, name: 'Arête', grade: '6B',
        marks: [(photo, Role.start)]);
    await seedProblem(db, layout, name: 'Crimps', marks: [(photo, Role.hand)]);
  });
  tearDown(() => db.close());

  Future<Problem> read(String id) async => (await db.watchProblem(id).first)!;

  group('database', () {
    test('retire sets the date, un-retire clears it', () async {
      await db.retireProblem(arete, today: DateTime(2026, 11, 22));
      expect((await read(arete)).retiredOn, '2026-11-22');
      expect(await db.watchProblems(layout).first, hasLength(2),
          reason: 'kept, not deleted');

      await db.unretireProblem(arete);
      expect((await read(arete)).retiredOn, isNull);
    });

    test("a retired problem's name stays taken", () async {
      await db.retireProblem(arete);
      expect(await db.problemNameTaken(layout, 'ARÊTE'), isTrue);
    });

    test("an archived layout's problems can't be retired or un-retired",
        () async {
      await db.retireProblem(arete);
      await db.resetLayout(wall, startedOn: DateTime(2026, 12, 1));
      await expectLater(db.unretireProblem(arete), throwsStateError);
      final crimps = (await db.watchProblems(layout).first)
          .firstWhere((p) => p.name == 'Crimps');
      await expectLater(db.retireProblem(crimps.id), throwsStateError);
      expect((await read(crimps.id)).retiredOn, isNull);
      expect((await read(arete)).retiredOn, isNotNull);
    });
  });

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Problem menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<List<String>> menuItems(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Problem menu'));
    await tester.pumpAndSettle();
    final items = [
      for (final i in tester.widgetList<PopupMenuItem<void>>(
          find.byType(PopupMenuItem<void>)))
        (i.child! as Text).data!,
    ];
    await tester.tapAt(Offset.zero);   // close the menu
    await tester.pumpAndSettle();
    return items;
  }

  testApp('retire hides it from the list, Show retired shows it greyed '
      'with a badge, un-retire restores it', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/$arete');
    expect(await menuItems(tester), ['Edit', 'Share', 'Retire', 'Delete']);

    await menu(tester, 'Retire');
    expect(find.text('6B · Retired ${dateStrFrom(DateTime.now())}'),
        findsOneWidget);
    expect(await menuItems(tester), ['Share', 'Un-retire', 'Delete'],
        reason: 'read-only apart from Share, Un-retire and Delete');

    await goTo(tester, '/walls/$wall');
    expect(find.text('Arête'), findsNothing);
    expect(find.text('Crimps'), findsOneWidget);

    await tester.tap(find.text('Show retired'));
    await tester.pumpAndSettle();
    final row = find.byKey(ValueKey('problem-$arete'));
    expect(find.descendant(of: row, matching: find.text('Retired')),
        findsOneWidget);
    expect(find.ancestor(of: row, matching: find.byType(Opacity)),
        findsOneWidget, reason: 'greyed');

    await tester.tap(find.text('Arête'));
    await tester.pumpAndSettle();
    await menu(tester, 'Un-retire');
    expect(find.text('6B'), findsOneWidget);
    expect(await menuItems(tester), ['Edit', 'Share', 'Retire', 'Delete']);

    await goTo(tester, '/walls/$wall');
    await tester.tap(find.text('Show retired'));   // off again
    await tester.pumpAndSettle();
    expect(find.text('Arête'), findsOneWidget);
    expect(find.text('Retired'), findsNothing);
  });

  testApp("retire's snackbar undoes it", (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/$arete');
    await menu(tester, 'Retire');
    expect(find.text('Retired "Arête"'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('6B'), findsOneWidget);
    expect(await tester.runAsync(() => read(arete)),
        isA<Problem>().having((p) => p.retiredOn, 'retiredOn', isNull));
  });

  group('all retired', () {
    // Seeded before the app starts: a write from the test body doesn't
    // reach the app's streams under fake time.
    setUp(() async {
      for (final p in await db.watchProblems(layout).first) {
        await db.retireProblem(p.id);
      }
    });

    testApp('the list says so and offers Show retired', (tester) async {
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall');
      expect(find.text('Every problem here is retired'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Show retired'));
      await tester.pumpAndSettle();
      expect(find.text('Arête'), findsOneWidget);
      expect(find.text('Crimps'), findsOneWidget);
    });

    testApp("a retired problem's editor is not found", (tester) async {
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/problems/$arete/edit');
      expect(find.text('Not found'), findsOneWidget);
    });
  });
}

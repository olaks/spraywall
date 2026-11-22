import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/utils/format_utils.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// Reset from the wall screen with its undo snackbar, the Past layouts list,
/// and an archived layout shown read-only.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      first;
  setUp(() async {
    db    = openTestDb();
    wall  = await seedWall(db, name: 'Home wall', today: DateTime(2026, 9, 1));
    first = await currentLayoutId(db, wall);
    final photo = await seedPhoto(db, first);
    await seedProblem(db, first, name: 'Arête', grade: '6B',
        marks: [(photo, Role.start)]);
    await seedProblem(db, first, name: 'Crimps', marks: [(photo, Role.hand)]);
  });
  tearDown(() => db.close());

  Future<void> wallMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Wall menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testApp('reset archives the layout, shows the empty new one, and the '
      'snackbar undoes it', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall');
    await wallMenu(tester, 'Reset');

    expect(find.text('Start a new layout?'), findsOneWidget);
    expect(find.text('The current one will be archived with its 2 problems.'),
        findsOneWidget);
    expect(find.text('Starts ${dateStrFrom(DateTime.now())}'), findsOneWidget,
        reason: 'today by default');
    await tester.enterText(find.byKey(const ValueKey('layout-name')), 'Winter');
    await tester.tap(find.text('Reset'));
    await settleDb(tester);

    expect(find.text('Winter'), findsOneWidget, reason: 'the app bar');
    expect(find.text('No wall photos yet'), findsOneWidget);
    expect(find.text('Add a wall photo'), findsOneWidget);
    expect(find.text('Arête'), findsNothing);
    expect(find.text('Started a new layout'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await settleDb(tester);
    expect(find.text('Arête'), findsOneWidget);
    expect(find.text('Since 2026-09-01'), findsOneWidget);
    expect(await tester.runAsync(() => currentLayoutId(db, wall)), first);
  });

  testApp('cancel changes nothing', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall');
    await wallMenu(tester, 'Reset');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Arête'), findsOneWidget);
    expect(await tester.runAsync(() => currentLayoutId(db, wall)), first);
  });

  group('past layouts', () {
    // Seeded before the app starts: a write from the test body doesn't
    // reach the app's streams under fake time.
    setUp(() => db.resetLayout(wall, startedOn: DateTime(2026, 11, 1)));

    testApp('lists each archived layout with its dates and counts, and '
        'opens it read-only', (tester) async {
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall');
      await wallMenu(tester, 'Past layouts');

      expect(find.text('2026-09-01 – 2026-11-01'), findsOneWidget);
      expect(find.text('2 problems · 1 photo'), findsOneWidget);

      await tester.tap(find.text('2026-09-01 – 2026-11-01'));
      await tester.pumpAndSettle();
      expect(find.text('Archived, 2026-09-01 – 2026-11-01'), findsOneWidget);
      expect(find.text('Arête'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Wall menu'), findsNothing,
          reason: 'no edit, reset or photos');

      await tester.tap(find.text('Arête'));
      await tester.pumpAndSettle();
      expect(find.text('6B'), findsOneWidget, reason: 'the problem view');
      await tester.tap(find.byTooltip('Problem menu'));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<void>), findsOneWidget,
          reason: 'view only: no edit, retire or delete');
      expect(find.text('Share'), findsOneWidget);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Archived, 2026-09-01 – 2026-11-01'), findsOneWidget,
          reason: 'Back returns to the archived layout');
    });

    testApp('delete goes, and undo brings it back', (tester) async {
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/layouts');

      await tester.tap(find.byTooltip('Layout menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No past layouts yet'), findsOneWidget);
      expect(find.text('Deleted "2026-09-01 – 2026-11-01"'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(find.text('2 problems · 1 photo'), findsOneWidget);
    });

    testApp("an archived problem's editor, and the current layout as an "
        'archived one, are not found', (tester) async {
      final arete = (await tester.runAsync(
              () => db.watchProblems(first).first))!
          .firstWhere((p) => p.name == 'Arête');
      final now = (await tester.runAsync(() => currentLayoutId(db, wall)))!;
      await pumpApp(tester, db);

      await goTo(tester, '/walls/$wall/problems/${arete.id}/edit');
      expect(find.text('Not found'), findsOneWidget);
      await goTo(tester, '/walls/$wall/layouts/$now');
      expect(find.text('Not found'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// The first run: an empty wall list offers one thing to do, and doing it
/// lands the user inside their new wall, ready to add a photo.
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  testApp('creating the first wall opens it', (tester) async {
    await pumpApp(tester, db);
    expect(find.text('Create your first wall'), findsOneWidget);

    await tester.tap(find.text('Create your first wall'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Home wall');
    await tester.tap(find.text('V'));
    await tester.pump(); // Create is enabled once the name is non-empty
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Home wall'), findsOneWidget);
    expect(find.text('No wall photos yet'), findsOneWidget);
    final walls = await tester.runAsync(() => db.watchWalls().first);
    expect(walls!.single.gradeScale, GradeScale.v);

    // Back goes to the list, which now shows the wall.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home wall'), findsOneWidget);
    expect(find.text('V grades'), findsOneWidget);
  });

  testApp('a clashing name keeps the dialog open with a reason',
      (tester) async {
    await seedWall(db, name: 'Home wall');
    await pumpApp(tester, db);

    await tester.tap(find.text('New wall'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'HOME WALL');
    await tester.pump(); // Create is enabled once the name is non-empty
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('A wall called "HOME WALL" already exists'),
        findsOneWidget);
  });

  Future<void> openEditWall(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Wall menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit wall'));
    await tester.pumpAndSettle();
  }

  testApp('deleting a wall lands on the list, and undo brings it back',
      (tester) async {
    await seedWall(db, name: 'Home wall');
    await seedWall(db, name: 'Garage');
    await pumpApp(tester, db);

    await openEditWall(tester, 'Home wall');
    await tester.tap(find.text('Delete wall'));
    await tester.pumpAndSettle();

    expect(find.text('Walls'), findsOneWidget, reason: 'back on the list');
    expect(find.text('Garage'), findsOneWidget);
    expect(find.text('Home wall'), findsNothing);
    expect(find.text('Deleted "Home wall"'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('Home wall'), findsOneWidget);
    final walls = await tester.runAsync(() => db.watchWalls().first);
    expect(walls!.map((w) => w.name), ['Home wall', 'Garage'],
        reason: 'back in its old place');
  });

  testApp('dragging a wall by its handle reorders the list',
      (tester) async {
    for (final name in ['A', 'B', 'C']) {
      await seedWall(db, name: name);
    }
    await pumpApp(tester, db);

    // Drag A's handle down past the bottom of C, in steps as a finger would.
    final start   = tester.getCenter(find.byIcon(Icons.drag_handle).first);
    final target  = tester.getBottomLeft(find.widgetWithText(ListTile, 'C')).dy + 8;
    final gesture = await tester.startGesture(start);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset(start.dx, start.dy + (target - start.dy) * i / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final walls = await tester.runAsync(() => db.watchWalls().first);
    expect(walls!.map((w) => w.name), ['B', 'C', 'A']);
  });

  testApp('a renamed wall shows its new name', (tester) async {
    await seedWall(db, name: 'Home wall');
    await pumpApp(tester, db);

    await openEditWall(tester, 'Home wall');
    await tester.enterText(find.byType(TextField), 'Cellar');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Cellar'), findsOneWidget);
  });

  testApp('the grade scale is locked once a problem has a grade',
      (tester) async {
    final id     = await seedWall(db, name: 'Home wall');
    // Seeding reads drift streams, which only complete in real async.
    await tester.runAsync(() async =>
        seedProblem(db, await currentLayoutId(db, id), grade: '6B'));
    await pumpApp(tester, db);

    await openEditWall(tester, 'Home wall');
    expect(find.textContaining('Locked'), findsOneWidget);
    await tester.tap(find.text('V'));
    await tester.pump();
    final segmented = tester.widget<SegmentedButton<GradeScale>>(
        find.byType(SegmentedButton<GradeScale>));
    expect(segmented.selected, {GradeScale.font});

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testApp('an unknown wall id shows the not-found page', (tester) async {
    await pumpApp(tester, db);
    final context = tester.element(find.byType(Scaffold).first);
    context.go('/walls/${newId()}');
    await tester.pumpAndSettle();
    expect(find.text('Not found'), findsOneWidget);
  });
}

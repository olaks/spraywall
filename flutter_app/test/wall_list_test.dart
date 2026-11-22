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

  testWidgets('creating the first wall opens it', (tester) async {
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

    await teardownTree(tester);
  });

  testWidgets('a clashing name keeps the dialog open with a reason',
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
    await teardownTree(tester);
  });

  testWidgets('an unknown wall id shows the not-found page', (tester) async {
    await pumpApp(tester, db);
    final context = tester.element(find.byType(Scaffold).first);
    context.go('/walls/${newId()}');
    await tester.pumpAndSettle();
    expect(find.text('Not found'), findsOneWidget);
    await teardownTree(tester);
  });
}

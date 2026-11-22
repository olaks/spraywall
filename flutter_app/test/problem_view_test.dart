import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_layer.dart';
import 'package:spraywall/widgets/zoomable_photo.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// The read-only problem view, and editing and deleting from its menu.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  late String      photo;
  late String      problem;
  setUp(() async {
    db      = openTestDb();
    wall    = await seedWall(db, name: 'Home wall');
    layout  = await currentLayoutId(db, wall);
    photo   = await seedPhoto(db, layout, width: 1600, height: 1200);
    problem = await db.createProblem(
      layoutId: layout, name: 'Arête', grade: '6B',
      description: 'Sit start, arête is in.', setOn: DateTime(2026, 11, 20),
      marks: [
        (id: newId(), photoId: photo, role: Role.start,  cx: 0.3, cy: 0.8, r: 0.02),
        (id: newId(), photoId: photo, role: Role.finish, cx: 0.6, cy: 0.1, r: 0.02),
      ],
    );
  });
  tearDown(() => db.close());

  Future<void> openView(WidgetTester tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/$problem');
  }

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Problem menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testApp('tapping a problem on the list opens its view', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall');
    await tester.tap(find.text('Arête'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Problem menu'), findsOneWidget);
    expect(find.text('Sit start, arête is in.'), findsOneWidget);
    expect(find.text('Set 2026-11-20'), findsOneWidget);
  });

  testApp('the view has no edit controls on the photo', (tester) async {
    await openView(tester);
    final layer = tester.widget<MarkLayer>(find.byType(MarkLayer));
    expect(layer.marks, hasLength(2));
    expect([layer.onTapEmpty, layer.onTapMark, layer.onMove, layer.onResize],
        everyElement(isNull));
    expect(find.byType(ChoiceChip), findsNothing, reason: 'no palette');
    expect(find.byTooltip('Delete mark'), findsNothing);

    // A tap on the photo and on a mark change nothing.
    await tester.tapAt(tester.getCenter(find.byType(InteractiveViewer)));
    await tester.pump();
    expect(find.byKey(const ValueKey('resize-handle')), findsNothing);
    expect(await db.marksOf(problem), hasLength(2));
  });

  testApp('the description folds away, and is absent when empty',
      (tester) async {
    await openView(tester);
    await tester.tap(find.text('Set 2026-11-20'));
    await tester.pump();
    expect(find.text('Sit start, arête is in.'), findsNothing);

    final bare = await db.createProblem(
      layoutId: layout, name: 'Crimps', setOn: DateTime(2026, 11, 21),
      marks: [(id: newId(), photoId: photo, role: Role.hand, cx: 0.5, cy: 0.5, r: 0.02)],
    );
    await goTo(tester, '/walls/$wall/problems/$bare');
    expect(find.text('Set 2026-11-21'), findsNothing);
    expect(find.text('Ungraded'), findsOneWidget);
  });

  testApp('it opens on the first photo with a start mark', (tester) async {
    final second = await tester.runAsync(() => seedPhoto(db, layout));
    final onSecond = await db.createProblem(
      layoutId: layout, name: 'Kicker start', setOn: DateTime(2026, 11, 21),
      marks: [
        (id: newId(), photoId: photo,   role: Role.hand,  cx: 0.5, cy: 0.5, r: 0.02),
        (id: newId(), photoId: second!, role: Role.start, cx: 0.5, cy: 0.5, r: 0.02),
      ],
    );
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/$onSecond');
    expect(tester.widget<ZoomablePhoto>(find.byType(ZoomablePhoto)).photo.id,
        second);
  });

  testApp('delete goes back to the list, with the undo there',
      (tester) async {
    await openView(tester);
    await menu(tester, 'Delete');

    expect(find.text('Home wall'), findsOneWidget, reason: 'on the wall list');
    expect(find.text('Arête'), findsNothing);
    expect(find.text('Deleted "Arête"'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('Arête'), findsOneWidget);
    expect(await db.marksOf(problem), hasLength(2));
  });

  testApp('edit loads the marks, and Edit details changes them on Save',
      (tester) async {
    await openView(tester);
    await menu(tester, 'Edit');
    expect(tester.widget<MarkLayer>(find.byType(MarkLayer)).marks, hasLength(2));

    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
    expect(find.text('Sit start, arête is in.'), findsOneWidget,
        reason: 'the sheet starts from the saved details');
    await tester.enterText(find.byKey(const ValueKey('problem-name')), 'Arête direct');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final before = await tester.runAsync(() => db.watchProblem(problem).first);
    expect(before!.name, 'Arête', reason: 'nothing is written before Save');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Problem menu'), findsOneWidget, reason: 'back on the view');
    expect(find.text('Arête direct'), findsOneWidget);
    final saved = await tester.runAsync(() => db.watchProblem(problem).first);
    expect((saved!.name, saved.grade), ('Arête direct', '6B'));
    expect(await db.marksOf(problem), hasLength(2));
  });

  testApp("Edit details refuses another problem's name", (tester) async {
    await db.createProblem(
      layoutId: layout, name: 'Crimps', setOn: DateTime(2026, 11, 21),
      marks: [(id: newId(), photoId: photo, role: Role.hand, cx: 0.5, cy: 0.5, r: 0.02)],
    );
    await openView(tester);
    await menu(tester, 'Edit');
    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('problem-name')), 'crimps');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('This layout already has a problem called "crimps"'),
        findsOneWidget);
  });

  testApp('leaving an edit with changes asks to discard, and keeps the '
      'problem as it was', (tester) async {
    await openView(tester);
    await menu(tester, 'Edit');
    await tester.tap(find.text('Finish')); // nothing selected: brush only
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing,
        reason: 'changing the brush changes nothing');

    await menu(tester, 'Edit');
    final viewer = find.byType(InteractiveViewer);
    // The photo's centre: on the photo, away from both marks.
    await tester.tapAt(tester.getCenter(viewer));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Problem menu'), findsOneWidget, reason: 'back on the view');
    expect(await db.marksOf(problem), hasLength(2));
  });
}

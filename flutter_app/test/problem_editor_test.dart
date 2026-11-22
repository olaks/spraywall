import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_editor.dart';
import 'package:spraywall/marks/mark_geometry.dart';
import 'package:spraywall/marks/mark_layer.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// The editor on one photo. Zoom is set on the transformation controller,
/// never by simulated pinches, and every tap and drag is aimed in photo
/// pixels through the current transform.
void main() {
  const photoSize = Size(1600, 1200);
  late AppDatabase db;
  late String      wall;
  late String      layout;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, name: 'Home wall');
    layout = await currentLayoutId(db, wall);
    await seedPhoto(db, layout, width: 1600, height: 1200);
  });
  tearDown(() => db.close());

  Future<void> openEditor(WidgetTester tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/new');
  }

  TransformationController controller(WidgetTester tester) =>
      tester.widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;

  MarkLayer layer(WidgetTester tester) =>
      tester.widget<MarkLayer>(find.byType(MarkLayer));

  List<EditMark> marks(WidgetTester tester) => layer(tester).marks;

  /// Where photo pixel [p] is on screen right now.
  Offset screen(WidgetTester tester, Offset p) =>
      tester.getTopLeft(find.byType(InteractiveViewer)) +
      MatrixUtils.transformPoint(controller(tester).value, p);

  /// Zooms to [zoom] with photo pixel [at] in the middle of the viewer.
  Future<void> zoomTo(WidgetTester tester, double zoom, Offset at) async {
    final viewport = tester.getSize(find.byType(InteractiveViewer));
    final shift    = viewport.center(Offset.zero) - at * zoom;
    controller(tester).value = Matrix4.diagonal3Values(zoom, zoom, zoom)
      ..setTranslationRaw(shift.dx, shift.dy, 0);
    await tester.pump();
  }

  Future<void> tapPhoto(WidgetTester tester, Offset p) async {
    await tester.tapAt(screen(tester, p));
    await tester.pump();
  }

  /// A finger drag from [from] by [by], both in screen pixels, in steps.
  Future<void> drag(WidgetTester tester, Offset from, Offset by) async {
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(from + by * (i / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
  }

  Offset centreOf(EditMark m) => centrePx(m.cx, m.cy, photoSize);

  testApp('a tap on empty photo always places a mark, and selects it',
      (tester) async {
    await openEditor(tester);
    await tapPhoto(tester, const Offset(400, 300));
    expect(marks(tester), hasLength(1));
    final first = marks(tester).single;
    expect(first.cx, closeTo(0.25, 0.01));
    expect(first.cy, closeTo(0.25, 0.01));
    expect(first.role, Role.hand);
    expect(layer(tester).selectedId, first.id);

    // With a mark selected, a tap elsewhere places another; it never just
    // deselects.
    await tapPhoto(tester, const Offset(1200, 900));
    expect(marks(tester), hasLength(2));
    expect(layer(tester).selectedId, isNot(first.id));
  });

  testApp('a tap on a mark selects it, and the palette shows its role',
      (tester) async {
    await openEditor(tester);
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tapPhoto(tester, const Offset(400, 300));
    // Done first: with a mark selected, a chip would recolour it.
    await tester.tap(find.byTooltip('Done'));
    await tester.pump();
    await tester.tap(find.text('Foot'));
    await tester.pump();
    await tapPhoto(tester, const Offset(1200, 900));
    final start = marks(tester).firstWhere((m) => m.role == Role.start);

    // Just inside the circle's edge still hits.
    final rPx = radiusPx(start.r, photoSize);
    await tapPhoto(tester, centreOf(start) + Offset(rPx * 0.9, 0));
    expect(layer(tester).selectedId, start.id);
    expect(marks(tester), hasLength(2), reason: 'selecting places nothing');
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Start'));
    expect(chip.selected, isTrue);

    // A chip now recolours it.
    await tester.tap(find.text('Finish'));
    await tester.pump();
    expect(marks(tester).firstWhere((m) => m.id == start.id).role, Role.finish);
  });

  testApp('dragging an unselected mark pans the photo instead',
      (tester) async {
    await openEditor(tester);
    await zoomTo(tester, 1, const Offset(800, 600));
    await tapPhoto(tester, const Offset(700, 600));
    final a = marks(tester).single;
    await tapPhoto(tester, const Offset(900, 600)); // selects the new one
    final before = controller(tester).value.getTranslation();

    await drag(tester, screen(tester, centreOf(a)), const Offset(0, 120));

    expect(marks(tester).firstWhere((m) => m.id == a.id).cy, a.cy,
        reason: 'the unselected mark stays put');
    final after = controller(tester).value.getTranslation();
    expect(after.x, closeTo(before.x, 1));
    // InteractiveViewer pans from where the gesture passed the touch slop,
    // so it trails the finger by that much.
    expect(after.y - before.y, inInclusiveRange(80, 120),
        reason: 'the photo followed the finger');
  });

  for (final zoom in [1.0, 3.0]) {
    testApp('dragging the selected mark at zoom $zoom drops it under the '
        'finger, and keeps it on the photo', (tester) async {
      await openEditor(tester);
      await tapPhoto(tester, const Offset(800, 600));
      await zoomTo(tester, zoom, const Offset(800, 600));
      final translation = controller(tester).value.getTranslation();

      await drag(tester, screen(tester, const Offset(800, 600)),
          const Offset(90, -60));
      final m = marks(tester).single;
      expect(m.cx, closeTo((800 + 90 / zoom) / 1600, 1e-3));
      expect(m.cy, closeTo((600 - 60 / zoom) / 1200, 1e-3));
      expect(controller(tester).value.getTranslation(), translation,
          reason: 'the photo did not pan');

      // Flung far past the corner, it stops on the edge.
      await drag(tester, screen(tester, centreOf(m)), const Offset(3000, 3000));
      final edge = marks(tester).single;
      expect((edge.cx, edge.cy), (1.0, 1.0));
    });
  }

  testApp('resizing stays within limits, and the size carries to the next '
      'mark on the photo', (tester) async {
    await openEditor(tester);
    await zoomTo(tester, 1, const Offset(800, 600));
    await tapPhoto(tester, const Offset(800, 600));
    expect(marks(tester).single.r, kDefaultMarkR);

    final handle = find.byKey(const ValueKey('resize-handle'));
    await drag(tester, tester.getCenter(handle), const Offset(-2000, 0));
    expect(marks(tester).single.r, kMinMarkR);
    await drag(tester, tester.getCenter(handle), const Offset(40, 0));
    final r = marks(tester).single.r;
    expect(r, closeTo(kMinMarkR + 40 / 1600, 1e-3));

    await tapPhoto(tester, const Offset(300, 300));
    expect(marks(tester).last.r, r);

    await drag(tester, tester.getCenter(handle), const Offset(4000, 0));
    expect(marks(tester).last.r, kMaxMarkR);
  });

  testApp('trash, then undo, puts the mark back', (tester) async {
    await openEditor(tester);
    await tapPhoto(tester, const Offset(400, 300));
    await tapPhoto(tester, const Offset(800, 300));
    final trashed = marks(tester).last;

    await tester.tap(find.byTooltip('Delete mark'));
    await tester.pumpAndSettle(); // let the snackbar slide in
    expect(marks(tester), hasLength(1));
    await tester.tap(find.text('UNDO'));
    await tester.pump();
    expect(marks(tester).map((m) => m.id), contains(trashed.id));
  });

  Future<void> saveAs(WidgetTester tester, String name, {String? grade}) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('problem-name')), name);
    if (grade != null) {
      await tester.tap(find.byKey(const ValueKey('problem-grade')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(grade).last);
      await tester.pumpAndSettle();
    }
    await tester.pump();
    await tester.tap(find.text('Save problem'));
    await tester.pumpAndSettle();
  }

  testApp('trash undone after saving and leaving goes into the saved problem',
      (tester) async {
    await openEditor(tester);
    await tapPhoto(tester, const Offset(400, 300));
    await tapPhoto(tester, const Offset(800, 300));
    final trashed = marks(tester).last;
    await tester.tap(find.byTooltip('Delete mark'));
    await tester.pump();

    await saveAs(tester, 'Arête');
    expect(find.byType(ChoiceChip), findsNothing,
        reason: 'the editor closed (the view draws marks, but has no palette)');
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();

    final problem = (await tester.runAsync(() => db.watchProblems(layout).first))!.single;
    final stored  = await db.marksOf(problem.id);
    expect(stored.map((m) => m.id), contains(trashed.id));
    expect(stored, hasLength(2));
  });

  testApp('save asks for details, opens the problem, and it joins the list',
      (tester) async {
    // Seeding reads drift streams, which only complete in real async.
    await tester.runAsync(() => seedProblem(db, layout, name: 'Crimps'));
    await openEditor(tester);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
        .onPressed, isNull, reason: 'no marks, no save');
    await tapPhoto(tester, const Offset(400, 300));

    // A clash keeps the sheet open with the reason.
    await saveAs(tester, 'CRIMPS');
    expect(find.text('This layout already has a problem called "CRIMPS"'),
        findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('problem-name')), 'Arête');
    await tester.tap(find.byKey(const ValueKey('problem-grade')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6B').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save problem'));
    await tester.pumpAndSettle();

    // Saving opens the new problem's view; back is the wall's list.
    expect(find.text('Arête'), findsOneWidget);
    expect(find.text('6B'), findsOneWidget);
    expect(find.byTooltip('Problem menu'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home wall'), findsOneWidget);
    expect(find.text('Arête'), findsOneWidget);
    expect(find.text('6B'), findsOneWidget);
    final saved = (await tester.runAsync(() => db.watchProblems(layout).first))!
        .firstWhere((p) => p.name == 'Arête');
    expect(saved.grade, '6B');
    expect(await db.marksOf(saved.id), hasLength(1));
  });

  testApp('a missing start or finish shows a hint, without blocking',
      (tester) async {
    await openEditor(tester);
    expect(find.textContaining('No start'), findsNothing);
    await tapPhoto(tester, const Offset(400, 300));
    expect(find.text('No start or finish mark yet'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('No finish mark yet'), findsOneWidget);
  });

  testApp('leaving with marks asks to discard', (tester) async {
    await openEditor(tester);
    await tapPhoto(tester, const Offset(400, 300));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(marks(tester), hasLength(1));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('No problems yet'), findsOneWidget);
  });

  testApp('the wall screen offers New problem once there is a photo',
      (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall');
    await tester.tap(find.text('New problem'));
    await tester.pumpAndSettle();
    expect(find.byType(MarkLayer), findsOneWidget);
  });
}

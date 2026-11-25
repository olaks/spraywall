import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_editor.dart';
import 'package:spraywall/marks/mark_layer.dart';
import 'package:spraywall/marks/outline.dart';

import 'helpers/app.dart';
import 'helpers/images.dart';
import 'helpers/test_db.dart';

/// Hold outlines in the app: a tap on a hold in the editor traces it, and
/// the outline is what's saved, edited and shown. Zoom is set on the
/// transformation controller, as in problem_editor_test.dart.
void main() {
  const photoSize = Size(1600, 1200);
  // A red hold of radius 60 px in the middle of the photo.
  const hold = Offset(800, 600);
  late AppDatabase db;
  late String      wall;
  late String      layout;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, name: 'Home wall');
    layout = await currentLayoutId(db, wall);
    await seedPhoto(db, layout,
        jpeg: jpegWithHold(centre: (800, 600), radius: 60));
  });
  tearDown(() => db.close());

  TransformationController controller(WidgetTester tester) =>
      tester.widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;

  List<EditMark> marks(WidgetTester tester) =>
      tester.widget<MarkLayer>(find.byType(MarkLayer)).marks;

  Offset screen(WidgetTester tester, Offset p) =>
      tester.getTopLeft(find.byType(InteractiveViewer)) +
      MatrixUtils.transformPoint(controller(tester).value, p);

  Future<void> tapPhoto(WidgetTester tester, Offset p) async {
    await tester.tapAt(screen(tester, p));
    await tester.pump();
  }

  Future<void> zoomTo(WidgetTester tester, double zoom, Offset at) async {
    final viewport = tester.getSize(find.byType(InteractiveViewer));
    final shift    = viewport.center(Offset.zero) - at * zoom;
    controller(tester).value = Matrix4.diagonal3Values(zoom, zoom, zoom)
      ..setTranslationRaw(shift.dx, shift.dy, 0);
    await tester.pump();
  }

  Future<void> drag(WidgetTester tester, Offset from, Offset by) async {
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(from + by * (i / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
  }

  List<Offset> px(EditMark m) => outlinePx(m.outline!, photoSize);

  testApp('a tap on a hold places its outline; drag moves it, the handle '
      'scales it, and the shape is saved and comes back', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/new');
    await tapPhoto(tester, hold + const Offset(15, -10));

    final traced = marks(tester).single;
    expect(traced.outline, isNotNull);
    expect(traced.cx * 1600, closeTo(800, 4));
    expect(traced.cy * 1200, closeTo(600, 4));
    expect(pointInPolygon(hold + const Offset(55, 0), px(traced)), isTrue);
    expect(pointInPolygon(hold + const Offset(80, 0), px(traced)), isFalse);

    // Drag it 100 photo px right, at 1:1.
    await zoomTo(tester, 1, hold);
    await drag(tester, screen(tester, hold), const Offset(100, 0));
    final moved = marks(tester).single;
    expect(moved.cx * 1600, closeTo(traced.cx * 1600 + 100, 2));
    expect(px(moved).first.dx, closeTo(px(traced).first.dx + 100, 2));

    // The handle sits on its circle's right; dragging it out grows the hold.
    await zoomTo(tester, 1, Offset(moved.cx * 1600, moved.cy * 1200));
    await drag(tester,
        tester.getCenter(find.byKey(const ValueKey('resize-handle'))),
        const Offset(60, 0));   // past the 36 px pan slop
    final grown = marks(tester).single;
    expect(grown.r, greaterThan(moved.r));
    final factor = grown.r / moved.r;
    final from   = px(moved).first, to = px(grown).first;
    final c      = Offset(moved.cx * 1600, moved.cy * 1200);
    expect((to - c).distance, closeTo((from - c).distance * factor, 1));

    // Saved, and back in the editor as it was.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('problem-name')), 'Pinch');
    await tester.pump();
    await tester.tap(find.text('Save problem'));
    await tester.pumpAndSettle();
    final saved = (await tester.runAsync(() => db.watchProblems(layout).first))!
        .single;
    final stored = (await db.marksOf(saved.id)).single;
    expect(decodeOutline(stored.outline), hasLength(grown.outline!.length));
    expect(stored.r, closeTo(grown.r, 1e-9));

    await goTo(tester, '/walls/$wall/problems/${saved.id}/edit');
    final back = marks(tester).single;
    expect(back.outline, isNotNull);
    for (final (a, b) in [for (var i = 0; i < back.outline!.length; i++)
                            (back.outline![i], grown.outline![i])]) {
      expect((a - b).distance, lessThan(1e-4), reason: 'four decimals');
    }
  });

  testApp("a traced outline's points fix it up: drag one, add one on an "
      'edge, double-tap one away', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/new');
    await tapPhoto(tester, hold);
    final traced = marks(tester).single;
    final n      = traced.outline!.length;

    // At fit zoom the points crowd, so only some have handles; zoomed in,
    // more of them do.
    int handles() => find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('point-')).evaluate().length;
    final atFit = handles();
    expect(atFit, inExclusiveRange(2, n));
    await zoomTo(tester, 1, hold);
    expect(handles(), greaterThan(atFit));

    // Drag point 0 outward, 60 px away from the hold's middle.
    final p0  = px(traced)[0];
    final out = (p0 - hold) / (p0 - hold).distance * 60;
    await drag(tester,
        tester.getCenter(find.byKey(const ValueKey('point-0'))), out);
    final pulled = marks(tester).single;
    expect((px(pulled)[0] - (p0 + out)).distance, lessThan(3));
    expect(px(pulled)[1], px(traced)[1], reason: 'the others stay');
    expect(pulled.r, greaterThan(traced.r), reason: 'the circle refits');

    // The edge from the dragged point is long now: its midpoint adds one.
    await tester.tap(find.byKey(const ValueKey('mid-0')));
    await tester.pump();
    final added = marks(tester).single;
    expect(added.outline, hasLength(n + 1));
    expect((px(added)[1] - (px(pulled)[0] + px(pulled)[1]) / 2).distance,
        lessThan(1));

    // Double-tapped, the new point goes again.
    final p1 = find.byKey(const ValueKey('point-1'));
    await tester.tap(p1);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(p1);
    await tester.pump(kDoubleTapTimeout);
    expect(marks(tester).single.outline, hasLength(n));
  });

  testApp('a tap on bare wall places a circle', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/new');
    await tapPhoto(tester, const Offset(300, 300));
    expect(marks(tester).single.outline, isNull);
  });

  testApp('the tracer looks as far as the zoom: zoomed far in on a big '
      'hold, it sees no edge and places a circle', (tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/problems/new');
    // At 8×, 200 screen px is 25 photo px: inside the 60 px hold.
    await zoomTo(tester, 8, hold);
    await tapPhoto(tester, hold);
    expect(marks(tester).single.outline, isNull);
    // Back at 1:1, the same hold traces.
    await zoomTo(tester, 1, hold);
    // Past the circle the first tap left, still on the hold.
    await tapPhoto(tester, hold + const Offset(0, 45));
    expect(marks(tester).last.outline, isNotNull);
  });
}

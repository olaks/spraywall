import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_editor.dart';
import 'package:spraywall/marks/mark_geometry.dart';

/// The pure rules under the editor: coordinates, hit-testing at a zoom,
/// radius limits, and the working copy's place/select/resize/trash.
void main() {
  const portrait = Size(1920, 2560);

  group('geometry', () {
    test('normalised ↔ photo pixels, with r relative to width', () {
      expect(centrePx(0.25, 0.5, portrait), const Offset(480, 1280));
      expect(radiusPx(0.02, portrait), closeTo(38.4, 1e-9),
          reason: 'width, not height, so the circle stays round');
      expect(normalise(const Offset(480, 1280), portrait), (0.25, 0.5));
    });

    test('normalising keeps a point on the photo', () {
      expect(normalise(const Offset(-10, 3000), portrait), (0.0, 1.0));
    });

    test('a small mark is still 20 screen px to hit when zoomed out', () {
      const centre = Offset(500, 500);
      const rPx    = 10.0;
      // At zoom 0.5, 20 screen px is 40 photo px.
      expect(hitsMark(const Offset(539, 500), centre, rPx, 0.5), isTrue);
      expect(hitsMark(const Offset(541, 500), centre, rPx, 0.5), isFalse);
      // At zoom 4, the circle itself (10 px) is bigger than 20/4 = 5.
      expect(hitsMark(const Offset(509, 500), centre, rPx, 4), isTrue);
      expect(hitsMark(const Offset(511, 500), centre, rPx, 4), isFalse);
    });

    test('radius limits', () {
      expect(clampRadius(0.0001), kMinMarkR);
      expect(clampRadius(1), kMaxMarkR);
      expect(clampRadius(0.05), 0.05);
    });
  });

  group('editor state', () {
    test('placing uses the brush, selects, and starts at the default size', () {
      final c = MarkEditorController()..chooseRole(Role.start);
      final m = c.place('p1', 0.3, 0.4);
      expect((m.role, m.cx, m.cy, m.r), (Role.start, 0.3, 0.4, kDefaultMarkR));
      expect(c.selected, m);
      expect(c.dirty, isTrue);
    });

    test('a chip recolours the selected mark and becomes the brush', () {
      final c = MarkEditorController();
      final m = c.place('p1', 0.5, 0.5);
      c.chooseRole(Role.foot);
      expect(c.selected!.role, Role.foot);
      expect(c.marks.single.id, m.id);
      c.select(null);
      expect(c.place('p1', 0.1, 0.1).role, Role.foot);
    });

    test('the last size is kept per photo', () {
      final c = MarkEditorController();
      final a = c.place('wall', 0.5, 0.5);
      c.resize(a.id, 0.01);
      expect(c.place('wall', 0.2, 0.2).r, closeTo(kDefaultMarkR + 0.01, 1e-12));
      expect(c.place('kicker', 0.2, 0.2).r, kDefaultMarkR,
          reason: 'another photo keeps its own size');
    });

    test('resizing stays within the limits', () {
      final c = MarkEditorController();
      final m = c.place('p1', 0.5, 0.5);
      c.resize(m.id, 5);
      expect(c.selected!.r, kMaxMarkR);
      c.resize(m.id, -5);
      expect(c.selected!.r, kMinMarkR);
    });

    test('moving keeps the centre on the photo', () {
      final c = MarkEditorController();
      final m = c.place('p1', 0.9, 0.1);
      c.move(m.id, 0.5, -0.5);
      expect((c.selected!.cx, c.selected!.cy), (1.0, 0.0));
    });

    test('the selected mark comes last, so it paints on top', () {
      final c = MarkEditorController();
      final a = c.place('p1', 0.1, 0.1);
      c.place('p1', 0.2, 0.2);
      c.place('p2', 0.3, 0.3);
      c.select(a.id);
      expect(c.marksOn('p1').last.id, a.id);
      expect(c.marksOn('p1'), hasLength(2));
    });

    test('trash and untrash put a mark back where it was', () {
      final c = MarkEditorController();
      final a = c.place('p1', 0.1, 0.1);
      final b = c.place('p1', 0.2, 0.2);
      c.place('p1', 0.3, 0.3);
      c.select(b.id); // the palette's trash acts on the selected mark
      final t = c.trash(b.id);
      expect(c.selected, isNull);
      expect(c.marks.map((m) => m.id), isNot(contains(b.id)));
      c.untrash(t);
      expect(c.marks.map((m) => m.id).take(2), [a.id, b.id]);
    });

    test('start and finish are tracked for the hint', () {
      final c = MarkEditorController();
      c.place('p1', 0.5, 0.5);
      expect((c.hasStart, c.hasFinish), (false, false));
      c.chooseRole(Role.start);
      expect((c.hasStart, c.hasFinish), (true, false));
    });
  });
}

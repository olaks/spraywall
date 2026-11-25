import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_editor.dart';
import 'package:spraywall/marks/outline.dart';
import 'package:spraywall/marks/overlap.dart';

/// Hold outlines: how they're stored, the circle around them, moving and
/// scaling them in the editor, and overlap with outlines.
void main() {
  // Wide, so x and y scale differently.
  const photo = Size(2000, 1000);
  // A 200 × 100 px box at (900, 450): 0.45..0.55 of width, 0.45..0.55 of height.
  const box = [Offset(0.45, 0.45), Offset(0.55, 0.45),
               Offset(0.55, 0.55), Offset(0.45, 0.55)];

  group('stored', () {
    test('round-trips at four decimals', () {
      const o = [Offset(0.12345, 0.5), Offset(1, 0), Offset(0, 0.99999)];
      final text = encodeOutline(o);
      expect(text, '0.1235 0.5000 1.0000 0.0000 0.0000 1.0000');
      expect(decodeOutline(text),
          const [Offset(0.1235, 0.5), Offset(1, 0), Offset(0, 1)]);
    });

    test('a circle, or text that is not an outline, reads as null', () {
      for (final t in [null, '', '  ', '0.1 0.2 0.3 0.4', '0.1 0.2 0.3',
                       '0.1 0.2 x 0.4 0.5 0.6']) {
        expect(decodeOutline(t), isNull, reason: '$t');
      }
    });
  });

  test('the circle around an outline, in photo pixels', () {
    final c = enclosingCircle(box, photo);
    expect(c.cx, closeTo(0.5, 1e-9));
    expect(c.cy, closeTo(0.5, 1e-9));
    // The corner is √(100² + 50²) px from the centre; r is of width.
    expect(c.r * photo.width, closeTo(111.80, 0.01));
  });

  group('editor', () {
    EditMark placed(MarkEditorController c) =>
        c.place('p', 0.5, 0.5, outline: box, photo: photo);

    test('placing an outline centres the mark on its circle and keeps the '
        'circle size for the next circle', () {
      final c = MarkEditorController();
      final m = c.place('p', 0.47, 0.46, outline: box, photo: photo);
      expect(m.cx, closeTo(0.5, 1e-9));
      expect(m.cy, closeTo(0.5, 1e-9));
      expect(m.outline, box);
      expect(m.input.outline, encodeOutline(box));
      final before = c.nextRadius('p');
      c.resize(m.id, 0.01);
      expect(c.nextRadius('p'), before, reason: "a hold's size isn't a brush");
    });

    test('moving moves the outline with its centre, kept on the photo', () {
      final c = MarkEditorController();
      final m = placed(c);
      c.move(m.id, 0.1, -0.2);
      final moved = c.marks.single;
      expect(moved.outline!.first.dx, closeTo(0.55, 1e-9));
      expect(moved.outline!.first.dy, closeTo(0.25, 1e-9));
      c.move(m.id, 1, 1);
      for (final p in c.marks.single.outline!) {
        expect(p.dx, inInclusiveRange(0, 1));
        expect(p.dy, inInclusiveRange(0, 1));
      }
    });

    test('resizing scales the outline about its centre', () {
      final c = MarkEditorController();
      final m = placed(c);
      c.resize(m.id, m.r);  // twice the size
      final o = c.marks.single.outline!;
      expect(o.first.dx, closeTo(0.40, 1e-9));
      expect(o.first.dy, closeTo(0.40, 1e-9));
      expect(c.marks.single.r, closeTo(m.r * 2, 1e-9));
    });

    test("dragging a point reshapes the outline and refits the mark's "
        'circle; it stays on the photo', () {
      final c = MarkEditorController();
      final m = placed(c);
      c.movePoint(m.id, 1, 0.05, 0.05, photo);
      final moved = c.marks.single;
      expect(moved.outline![1].dx, closeTo(0.60, 1e-9));
      expect(moved.outline![1].dy, closeTo(0.50, 1e-9));
      expect(moved.outline![0], box[0], reason: 'the others stay');
      final fit = enclosingCircle(moved.outline!, photo);
      expect((moved.cx, moved.cy, moved.r), (fit.cx, fit.cy, fit.r));
      expect(c.dirty, isTrue);

      c.movePoint(m.id, 1, 2, -2, photo);
      expect(c.marks.single.outline![1], const Offset(1, 0));
    });

    test('a point added on an edge goes between its two ends', () {
      final c = MarkEditorController();
      final m = placed(c);
      final i = c.insertPoint(m.id, 1, const Offset(0.6, 0.5), photo);
      expect(i, 2);
      expect(c.marks.single.outline, [
        box[0], box[1], const Offset(0.6, 0.5), box[2], box[3],
      ]);
      // After the last point, the edge back to the first.
      final j = c.insertPoint(m.id, 4, const Offset(0.4, 0.5), photo);
      expect(j, 5);
      expect(c.marks.single.outline!.last, const Offset(0.4, 0.5));
      final fit = enclosingCircle(c.marks.single.outline!, photo);
      expect(c.marks.single.r, fit.r);
    });

    test('a point can be removed, down to three', () {
      final c = MarkEditorController();
      final m = placed(c);
      c.removePoint(m.id, 0, photo);
      expect(c.marks.single.outline, [box[1], box[2], box[3]]);
      final fit = enclosingCircle(c.marks.single.outline!, photo);
      expect(c.marks.single.cx, fit.cx);
      c.removePoint(m.id, 0, photo);
      expect(c.marks.single.outline, hasLength(3), reason: 'a polygon');
    });

    test('a stored outline comes back into the editor', () {
      final m = EditMark.fromMark(Mark(id: 'm', problemId: 'q', photoId: 'p',
          role: Role.hand, cx: 0.5, cy: 0.5, r: 0.06,
          outline: encodeOutline(box)));
      expect(m.outline, box);
    });
  });

  group('overlap', () {
    Mark mark(String problem, double cx, double cy, {double r = 0.05,
            Outline? outline}) =>
        Mark(id: newId(), problemId: problem, photoId: 'p', role: Role.hand,
            cx: cx, cy: cy, r: r,
            outline: outline == null ? null : encodeOutline(outline));
    Mark held(String problem, Outline o) {
      final c = enclosingCircle(o, photo);
      return mark(problem, c.cx, c.cy, r: c.r, outline: o);
    }
    Outline shifted(double dx, double dy) =>
        [for (final p in box) p.translate(dx, dy)];

    test('outline and outline: crossing, touching, inside, apart', () {
      final a = held('a', box);
      expect(marksOverlap(a, held('b', shifted(0.05, 0)), photo), isTrue);
      expect(marksOverlap(a, held('b', shifted(0.1, 0)), photo), isTrue,
          reason: 'sharing an edge');
      expect(marksOverlap(a, held('b', shifted(0.1001, 0)), photo), isFalse);
      const inside = [Offset(0.49, 0.49), Offset(0.51, 0.49), Offset(0.5, 0.51)];
      expect(marksOverlap(a, held('b', inside), photo), isTrue);
      // Corner to corner, the circles cross but the boxes don't meet.
      expect(marksOverlap(a, held('b', shifted(0.11, 0.11)), photo), isFalse);
    });

    test('outline and circle, in photo pixels', () {
      final a = held('a', box);
      // The box's right edge is at 1100 px; a 100 px circle at 1200 touches.
      expect(marksOverlap(a, mark('b', 0.6, 0.5), photo), isTrue);
      expect(marksOverlap(a, mark('b', 0.6001, 0.5), photo), isFalse);
      // Its corner is 111.8 px from the centre: a circle there misses the
      // box where its circle would have crossed.
      expect(marksOverlap(a, mark('b', 0.61, 0.61, r: 0.02), photo), isFalse);
      expect(marksOverlap(mark('b', 0.5, 0.5, r: 0.001), a, photo), isTrue,
          reason: 'a circle inside the outline');
    });
  });
}

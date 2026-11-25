import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/marks/hold_trace.dart';
import 'package:spraywall/marks/outline.dart';

import 'helpers/images.dart';

/// A plywood-coloured wall with grain noise, and holds painted on it: each
/// an ellipse (centre, radii in px) of one colour. [chalk] smears go on the
/// holds, near white at their middle and fading out to their edge, as chalk
/// rubbed onto a hold does. Made in code: the real wall photo carries GPS and is
/// never committed.
PhotoPixels wall(int width, int height,
    List<({Offset c, double rx, double ry, List<int> rgb})> holds,
    {List<({Offset c, double rx, double ry})> chalk = const []}) {
  final rgba = Uint8List(width * height * 4);
  final rnd  = math.Random(7);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var rgb    = [214, 186, 140];
      var onHold = false;
      for (final h in holds) {
        final dx = (x + 0.5 - h.c.dx) / h.rx, dy = (y + 0.5 - h.c.dy) / h.ry;
        if (dx * dx + dy * dy <= 1) {
          rgb    = h.rgb;
          onHold = true;
        }
      }
      for (final s in onHold ? chalk : const <Never>[]) {
        final dx = (x + 0.5 - s.c.dx) / s.rx, dy = (y + 0.5 - s.c.dy) / s.ry;
        final a  = (1 - math.sqrt(dx * dx + dy * dy)).clamp(0.0, 1.0);
        rgb = [
          for (var k = 0; k < 3; k++)
            (rgb[k] + (const [238, 236, 230][k] - rgb[k]) * math.min(1, 2 * a))
                .round(),
        ];
      }
      final noise = rnd.nextInt(13) - 6;
      final i = (y * width + x) * 4;
      for (var k = 0; k < 3; k++) {
        rgba[i + k] = (rgb[k] + noise).clamp(0, 255);
      }
      rgba[i + 3] = 255;
    }
  }
  return PhotoPixels(width, height, rgba);
}

/// The polygon's area, in px², by the shoelace formula.
double area(List<Offset> p) {
  var s = 0.0;
  for (var i = 0; i < p.length; i++) {
    final a = p[i], b = p[(i + 1) % p.length];
    s += a.dx * b.dy - b.dx * a.dy;
  }
  return s.abs() / 2;
}

void main() {
  const red  = [200, 30, 40];
  const size = Size(800, 600);

  test('a coloured hold on plywood traces close to its shape', () {
    final px = wall(800, 600,
        [(c: const Offset(400, 300), rx: 40, ry: 25, rgb: red)]);
    final o = traceHold(px, const Offset(0.5, 0.5), 0.15)!;
    final poly = outlinePx(o, size);

    expect(o.length, inInclusiveRange(3, 64));
    // Just outside the hold: a little bigger than the ellipse, not much.
    final truth = math.pi * 40 * 25;
    expect(area(poly), inInclusiveRange(truth * 0.95, truth * 1.35));
    // The ellipse's ends are inside, and points just past them are not.
    for (final p in const [Offset(362, 300), Offset(438, 300),
                           Offset(400, 277), Offset(400, 323)]) {
      expect(pointInPolygon(p, poly), isTrue, reason: '$p');
    }
    for (final p in const [Offset(350, 300), Offset(450, 300),
                           Offset(400, 265), Offset(400, 335)]) {
      expect(pointInPolygon(p, poly), isFalse, reason: '$p');
    }
    // Its enclosing circle sits on the hold.
    final c = enclosingCircle(o, size);
    expect(c.cx * 800, closeTo(400, 3));
    expect(c.cy * 600, closeTo(300, 3));
  });

  test('a tap off-centre on the hold traces the same hold', () {
    final px = wall(800, 600,
        [(c: const Offset(400, 300), rx: 40, ry: 25, rgb: red)]);
    final o = traceHold(px, const Offset(430 / 800, 310 / 600), 0.15)!;
    expect(pointInPolygon(const Offset(370, 295), outlinePx(o, size)), isTrue);
  });

  test('a neighbouring hold of another colour is left out', () {
    final px = wall(800, 600, [
      (c: const Offset(400, 300), rx: 40, ry: 25, rgb: red),
      (c: const Offset(460, 300), rx: 25, ry: 25, rgb: [30, 60, 200]),
    ]);
    final poly = outlinePx(traceHold(px, const Offset(0.5, 0.5), 0.15)!, size);
    expect(pointInPolygon(const Offset(470, 300), poly), isFalse);
  });

  test('chalk in the middle of a hold, under the tap, is part of the hold', () {
    // Chalk is near white: closer to the wall than to the hold's colour.
    final px = wall(800, 600,
        [(c: const Offset(400, 300), rx: 40, ry: 25, rgb: red)],
        chalk: [(c: const Offset(400, 300), rx: 22, ry: 14)]);
    final poly = outlinePx(traceHold(px, const Offset(0.5, 0.5), 0.15)!, size);
    final truth = math.pi * 40 * 25;
    expect(area(poly), inInclusiveRange(truth * 0.95, truth * 1.35));
    expect(pointInPolygon(const Offset(365, 300), poly), isTrue);
    expect(pointInPolygon(const Offset(350, 300), poly), isFalse);
  });

  test('chalk running out to the rim still traces the hold, not the wall', () {
    // The chalk meets the wall at the rim with hardly an edge. It fades into
    // the hold more softly than the wall stops the flood: a smear crisper
    // than that, near white to red in a few pixels, would lead it out.
    final px = wall(800, 600,
        [(c: const Offset(400, 300), rx: 40, ry: 25, rgb: red)],
        chalk: [(c: const Offset(428, 300), rx: 30, ry: 22)]);
    final poly = outlinePx(
        traceHold(px, const Offset(425 / 800, 0.5), 0.15)!, size);
    expect(pointInPolygon(const Offset(365, 300), poly), isTrue);
    expect(pointInPolygon(const Offset(400, 280), poly), isTrue);
    // Not out into the wall past the chalk.
    expect(pointInPolygon(const Offset(460, 300), poly), isFalse);
    expect(area(poly), lessThan(math.pi * 40 * 25 * 1.35));
  });

  test('a hold among others packed close traces alone', () {
    // A dense wall: the window around the tap is mostly other holds, of
    // every colour, with narrow gaps of wall between them.
    const colours = [
      [30, 60, 200], [230, 200, 40], [40, 160, 70], [120, 60, 150],
      [240, 120, 30], [60, 60, 60], [230, 90, 160], [90, 170, 220],
    ];
    final px = wall(800, 600, [
      for (var i = 0; i < 25; i++)
        (c: Offset(400 + (i % 5 - 2) * 96.0, 300 + (i ~/ 5 - 2) * 66.0),
         rx: 44, ry: 29, rgb: i == 12 ? red : colours[i % colours.length]),
    ]);
    final poly = outlinePx(traceHold(px, const Offset(0.5, 0.5), 0.15)!, size);
    expect(pointInPolygon(const Offset(365, 300), poly), isTrue);
    expect(pointInPolygon(const Offset(435, 300), poly), isTrue);
    for (final p in const [Offset(496, 300), Offset(304, 300),
                           Offset(400, 366), Offset(400, 234)]) {
      expect(pointInPolygon(p, poly), isFalse, reason: '$p');
    }
  });

  test('a tap on a bolt in a hold traces the hold', () {
    final px = wall(800, 600, [
      (c: const Offset(400, 300), rx: 40, ry: 25, rgb: red),
      (c: const Offset(400, 300), rx: 5,  ry: 5,  rgb: [30, 30, 30]),
    ]);
    final poly = outlinePx(traceHold(px, const Offset(0.5, 0.5), 0.15)!, size);
    expect(pointInPolygon(const Offset(365, 300), poly), isTrue);
    expect(pointInPolygon(const Offset(435, 300), poly), isTrue);
  });

  test('a tap on bare wall gives no outline', () {
    final px = wall(800, 600,
        [(c: const Offset(400, 300), rx: 40, ry: 25, rgb: red)]);
    expect(traceHold(px, const Offset(0.2, 0.2), 0.15), isNull);
  });

  test('a region that runs out of the search window gives no outline', () {
    final px = wall(800, 600,
        [(c: const Offset(400, 300), rx: 300, ry: 200, rgb: red)]);
    expect(traceHold(px, const Offset(0.5, 0.5), 0.05), isNull);
  });

  test('a hold at the photo edge still traces', () {
    final px = wall(800, 600,
        [(c: const Offset(0, 300), rx: 30, ry: 30, rgb: red)]);
    final o = traceHold(px, const Offset(10 / 800, 0.5), 0.15)!;
    expect(pointInPolygon(const Offset(15, 300), outlinePx(o, size)), isTrue);
  });

  test('the search area follows the zoom: zoomed in on a foot chip, the '
      'outline follows it closely', () {
    // A whole-wall photo, shown 400 px wide: at fit zoom the window is the
    // largest mark's, five pixels a cell; at 3× it reads every pixel.
    const w    = 2560.0;
    const chip = Offset(1280, 960);
    final px   = wall(2560, 1920, [(c: chip, rx: 9, ry: 6, rgb: red)]);
    const tap  = Offset(0.5, 0.5);
    final fit  = 400 / w;
    expect(traceRadius(fit, w), closeTo(0.15, 1e-9));
    expect(traceRadius(3, w), closeTo(200 / 3 / w, 1e-9));

    final truth = math.pi * 9 * 6;
    double error(Outline? o) => o == null
        ? double.infinity
        : (area(outlinePx(o, const Size(2560, 1920))) - truth).abs() / truth;
    final close = traceHold(px, tap, traceRadius(3, w))!;
    expect(pointInPolygon(chip, outlinePx(close, const Size(2560, 1920))),
        isTrue);
    expect(error(close), lessThan(0.6));
    expect(error(close), lessThan(error(traceHold(px, tap, traceRadius(fit, w)))));
  });

  test('a speck inside a hold the colour of the wall gives no outline', () {
    // A dark bolt in a pale hold barely off the wall's colour: what's around
    // the bolt isn't wall, so it isn't traced as a hold.
    final px = wall(800, 600, [
      (c: const Offset(400, 300), rx: 40, ry: 30, rgb: [226, 204, 166]),
      (c: const Offset(400, 300), rx: 4,  ry: 4,  rgb: [40, 40, 40]),
    ]);
    expect(traceHold(px, const Offset(0.5, 0.5), 0.05), isNull);
  });

  test('decodePixels reads a JPEG as RGBA, row by row', () {
    final px = decodePixels(jpegFixture(width: 4, height: 3, r: 200, g: 30, b: 40));
    expect((px.width, px.height), (4, 3));
    expect(px.rgba.length, 4 * 3 * 4);
    expect(px.rgba[0], closeTo(200, 12));
    expect(px.rgba[1], closeTo(30, 12));
    expect(px.rgba[3], 255);
  });
}

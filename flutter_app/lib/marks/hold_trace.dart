import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:image/image.dart' as img;

import 'mark_geometry.dart';
import 'outline.dart';

// Tracing a hold from a tap, in pure Dart so it runs the same on Android,
// Linux and the web build, and unit-tests on generated images.
//
// A window around the tap is sampled onto a grid of at most [_maxGrid] cells
// a side, in CIE Lab so colour distance follows what the eye sees (with
// lightness at half weight). The wall's
// colour is the median of the window's border; the hold's is the colour
// around the tap. From the tap the region grows through cells nearer the
// hold's colour than the wall's. Its edge, smoothed and simplified, is the
// outline. No outline (a circle instead) when the tap is on bare wall, the
// region is a speck, or it runs out of the window (it leaked into the wall).
//
// The window follows the zoom ([traceRadius]): zoomed in on a small hold, the
// grid is a pixel a cell and the outline follows its real edge.

/// A photo's pixels: RGBA, row by row.
class PhotoPixels {
  final int       width;
  final int       height;
  final Uint8List rgba;
  const PhotoPixels(this.width, this.height, this.rgba);
}

/// [jpeg] decoded in pure Dart. Slower than the engine's decoder, but it
/// needs no real time, so widget tests use it.
PhotoPixels decodePixels(Uint8List jpeg) {
  final image = img.decodeJpg(jpeg)!.convert(numChannels: 4);
  return PhotoPixels(image.width, image.height,
      image.getBytes(order: img.ChannelOrder.rgba));
}

/// How far from the tap the tracer looks, in screen pixels: about a
/// thumb's reach around it.
const kTraceScreenPx = 200.0;

/// The tracer's search radius as a fraction of photo width, at [zoom]
/// (screen px per photo px) on a photo [photoWidth] px wide: [kTraceScreenPx]
/// on screen, but never wider than the largest mark.
double traceRadius(double zoom, double photoWidth) =>
    math.min(kTraceScreenPx / zoom / photoWidth, kMaxMarkR);

/// Cells along the grid's side, at most.
const _maxGrid = 160;

/// Colour distance under which hold and wall can't be told apart, at least.
const _minContrast = 6.0;

/// ...and at least this many times bare wall's own variation.
const _spreads = 3.0;

/// The disc around the tap the hold's colour is read from, as a fraction of
/// photo width: a little wider than a bolt.
const _seedR = 0.006;

/// How far a hold's edge blurs into the wall, with its shadow, in photo px.
const _edgeBlurPx = 6.0;

/// Points an outline keeps, at most.
const _maxPoints = 64;

/// The outline of the hold at [tap] (normalised), looking [radius] (a
/// fraction of the photo's width) around it; null when there's no hold to
/// trace there.
Outline? traceHold(PhotoPixels px, Offset tap, double radius) {
  final w = px.width, h = px.height;
  final tx = (tap.dx * w).clamp(0.0, w - 1.0);
  final ty = (tap.dy * h).clamp(0.0, h - 1.0);
  final rPx = math.max(radius * w, 4.0);

  final x0 = math.max(0, (tx - rPx).floor());
  final y0 = math.max(0, (ty - rPx).floor());
  final x1 = math.min(w, (tx + rPx).ceil() + 1);
  final y1 = math.min(h, (ty + rPx).ceil() + 1);
  final step = math.max(1, ((math.max(x1 - x0, y1 - y0)) / _maxGrid).ceil());
  final gw = ((x1 - x0) / step).ceil();
  final gh = ((y1 - y0) / step).ceil();
  if (gw < 3 || gh < 3) return null;

  // Each cell's mean colour, in Lab.
  final lab = Float64List(gw * gh * 3);
  for (var gy = 0; gy < gh; gy++) {
    for (var gx = 0; gx < gw; gx++) {
      var r = 0, g = 0, b = 0, n = 0;
      final sx = x0 + gx * step, sy = y0 + gy * step;
      for (var y = sy; y < math.min(sy + step, y1); y++) {
        var i = (y * w + sx) * 4;
        for (var x = sx; x < math.min(sx + step, x1); x++, i += 4) {
          r += px.rgba[i];
          g += px.rgba[i + 1];
          b += px.rgba[i + 2];
          n++;
        }
      }
      _toLab(r / n, g / n, b / n, lab, (gy * gw + gx) * 3);
    }
  }
  double dist(int c, List<double> ref) {
    final i = c * 3;
    final dl = lab[i] - ref[0], da = lab[i + 1] - ref[1], db = lab[i + 2] - ref[2];
    return math.sqrt(dl * dl + da * da + db * db);
  }
  List<double> medianOf(Iterable<int> cells) => [
        for (var k = 0; k < 3; k++)
          _median([for (final c in cells) lab[c * 3 + k]]),
      ];

  // The wall: the median of the border, which is mostly bare wall, and how
  // much bare wall varies (grain, light falling off) from that.
  final border = <int>[
    for (var x = 0; x < gw; x++) ...[x, (gh - 1) * gw + x],
    for (var y = 1; y < gh - 1; y++) ...[y * gw, y * gw + gw - 1],
  ];
  final wall   = medianOf(border);
  final spread = _median([for (final c in border) dist(c, wall)]);
  double contrastOf(List<double> hold) => math.sqrt(
      List.generate(3, (k) => hold[k] - wall[k]).fold(0.0, (s, d) => s + d * d));
  final minContrast = math.max(_minContrast, _spreads * spread);

  // The hold: the median of what isn't wall in a small disc around the tap,
  // so a tap a little off a foot chip still finds it. Nearest first.
  final sgx = ((tx - x0) / step).floor().clamp(0, gw - 1);
  final sgy = ((ty - y0) / step).floor().clamp(0, gh - 1);
  final seedR = math.max(2, (_seedR * w / step).round());
  int d2(int c) {
    final dx = c % gw - sgx, dy = c ~/ gw - sgy;
    return dx * dx + dy * dy;
  }
  final disc = [
    for (var y = math.max(0, sgy - seedR); y <= math.min(gh - 1, sgy + seedR); y++)
      for (var x = math.max(0, sgx - seedR); x <= math.min(gw - 1, sgx + seedR); x++)
        if ((x - sgx) * (x - sgx) + (y - sgy) * (y - sgy) <= seedR * seedR)
          y * gw + x,
  ]..sort((a, b) => d2(a).compareTo(d2(b)));
  final notWall = [for (final c in disc) if (dist(c, wall) >= minContrast) c];
  if (notWall.isEmpty) return null;
  final hold = medianOf(notWall);
  if (contrastOf(hold) < minContrast) return null;
  // Growth starts on the hold, not on a bolt in its middle.
  final start = disc.firstWhere((c) => dist(c, hold) < dist(c, wall),
      orElse: () => -1);
  if (start < 0) return null;

  // Grow from the tap through cells nearer the hold than the wall. Twice:
  // the second time from the first region's colour, which takes in the lit
  // and the shaded side of a hold whichever the tap landed on.
  Uint8List? grow(List<double> hold) {
    final contrast = contrastOf(hold);
    final inRegion = Uint8List(gw * gh);
    final queue    = <int>[start];
    inRegion[queue.first] = 1;
    while (queue.isNotEmpty) {
      final c = queue.removeLast();
      final x = c % gw, y = c ~/ gw;
      // Touching a side of the window that isn't the photo's edge: the
      // region ran on past where a hold could end.
      if ((x == 0 && x0 > 0) || (y == 0 && y0 > 0) ||
          (x == gw - 1 && x1 < w) || (y == gh - 1 && y1 < h)) {
        return null;
      }
      for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        if (nx < 0 || ny < 0 || nx >= gw || ny >= gh) continue;
        final nc = ny * gw + nx;
        if (inRegion[nc] == 1) continue;
        final dh = dist(nc, hold);
        if (dh < dist(nc, wall) && dh < contrast) {
          inRegion[nc] = 1;
          queue.add(nc);
        }
      }
    }
    return inRegion;
  }

  final first = grow(hold);
  if (first == null) return null;
  final cells = [for (var c = 0; c < first.length; c++) if (first[c] == 1) c];
  if (cells.length < 4) return null;
  final refined = medianOf(cells);
  // Only when the region's colour is still clearly not the wall's.
  final second = contrastOf(refined) >= minContrast ? grow(refined) : null;
  final inRegion = second ?? first;

  // Told from the wall by lightness alone, a region may be shade: a bolt, a
  // shadow, the dark side of a pale hold. It has to stand out twice as much.
  final colour = medianOf(
      [for (var c = 0; c < inRegion.length; c++) if (inRegion[c] == 1) c]);
  final hue = math.sqrt(math.pow(colour[1] - wall[1], 2) +
      math.pow(colour[2] - wall[2], 2));
  if (hue < minContrast && contrastOf(colour) < 2 * minContrast) return null;

  // A real hold is ringed by wall. A region ringed by something else is a
  // bolt or a shadow inside a hold too close to the wall's colour to trace.
  // The ring starts a few pixels out, past the blur at the hold's edge.
  var inner = inRegion;
  for (var i = 0; i < math.max(2, (_edgeBlurPx / step).ceil()); i++) {
    inner = _dilate(inner, gw, gh);
  }
  final outer = _dilate(_dilate(inner, gw, gh), gw, gh);
  final ring  = [
    for (var c = 0; c < outer.length; c++)
      if (outer[c] == 1 && inner[c] == 0) c,
  ];
  if (ring.isEmpty ||
      _median([for (final c in ring) dist(c, wall)]) >= minContrast) {
    return null;
  }

  // Close small gaps (dilate, erode), fill holes, then grow one cell so the
  // line sits just outside the hold rather than on it.
  var mask = _dilate(inRegion, gw, gh);
  mask = _erode(mask, gw, gh);
  mask = _fillHoles(mask, gw, gh);
  mask = _dilate(mask, gw, gh);

  final contour = _traceContour(mask, gw, gh);
  if (contour.length < 3) return null;
  final pts = [
    for (final (gx, gy) in contour)
      Offset(x0 + (gx + 0.5) * step, y0 + (gy + 0.5) * step),
  ];
  var eps = 0.6 * step;
  var simple = _simplifyClosed(pts, eps);
  while (simple.length > _maxPoints) {
    eps *= 1.5;
    simple = _simplifyClosed(pts, eps);
  }
  if (simple.toSet().length < 3 || _area(simple) < step * step) return null;
  return [
    for (final p in simple)
      Offset((p.dx / w).clamp(0.0, 1.0), (p.dy / h).clamp(0.0, 1.0)),
  ];
}

// ── Colour ─────────────────────────────────────────────────────────────────

void _toLab(double r, double g, double b, Float64List out, int i) {
  double lin(double c) {
    c /= 255;
    return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }
  final rl = lin(r), gl = lin(g), bl = lin(b);
  // sRGB to XYZ (D65), each over the white point.
  final x = (0.4124 * rl + 0.3576 * gl + 0.1805 * bl) / 0.95047;
  final y =  0.2126 * rl + 0.7152 * gl + 0.0722 * bl;
  final z = (0.0193 * rl + 0.1192 * gl + 0.9505 * bl) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  final fx = f(x), fy = f(y), fz = f(z);
  // Lightness at half weight: holds differ from the wall mostly in colour,
  // while light and shadow change lightness across both.
  out[i]     = (116 * fy - 16) * 0.5;
  out[i + 1] = 500 * (fx - fy);
  out[i + 2] = 200 * (fy - fz);
}

double _median(List<double> v) {
  v.sort();
  return v[v.length ~/ 2];
}

// ── Mask ───────────────────────────────────────────────────────────────────

Uint8List _dilate(Uint8List m, int w, int h) {
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (m[y * w + x] == 1 ||
          (x > 0     && m[y * w + x - 1] == 1) ||
          (x < w - 1 && m[y * w + x + 1] == 1) ||
          (y > 0     && m[(y - 1) * w + x] == 1) ||
          (y < h - 1 && m[(y + 1) * w + x] == 1)) {
        out[y * w + x] = 1;
      }
    }
  }
  return out;
}

Uint8List _erode(Uint8List m, int w, int h) {
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      // The window's edge counts as inside, so a hold at the photo's edge
      // doesn't shrink away from it.
      bool at(int x, int y) =>
          x < 0 || y < 0 || x >= w || y >= h || m[y * w + x] == 1;
      if (at(x, y) && at(x - 1, y) && at(x + 1, y) && at(x, y - 1) &&
          at(x, y + 1)) {
        out[y * w + x] = 1;
      }
    }
  }
  return out;
}

/// [m] with every empty cell that can't reach the window's edge filled.
Uint8List _fillHoles(Uint8List m, int w, int h) {
  final outside = Uint8List(w * h);
  final queue   = <int>[];
  void seed(int x, int y) {
    final c = y * w + x;
    if (m[c] == 0 && outside[c] == 0) {
      outside[c] = 1;
      queue.add(c);
    }
  }
  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }
  while (queue.isNotEmpty) {
    final c = queue.removeLast();
    final x = c % w, y = c ~/ w;
    if (x > 0)     seed(x - 1, y);
    if (x < w - 1) seed(x + 1, y);
    if (y > 0)     seed(x, y - 1);
    if (y < h - 1) seed(x, y + 1);
  }
  return Uint8List.fromList([for (final o in outside) o == 1 ? 0 : 1]);
}

/// Clockwise from north, with y down.
const _dirs = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)];

/// The outer edge of [m]'s top-left region, cell by cell, by Moore-neighbour
/// tracing.
List<(int, int)> _traceContour(Uint8List m, int w, int h) {
  bool at(int x, int y) => x >= 0 && y >= 0 && x < w && y < h && m[y * w + x] == 1;

  (int, int)? start;
  for (var y = 0; y < h && start == null; y++) {
    for (var x = 0; x < w; x++) {
      if (at(x, y)) {
        start = (x, y);
        break;
      }
    }
  }
  if (start == null) return const [];

  // From cell p, with the empty cell we came from at [back], the next edge
  // cell clockwise and the new direction back.
  ((int, int), int)? next((int, int) p, int back) {
    for (var k = 1; k <= 8; k++) {
      final d = (back + k) % 8;
      final q = (p.$1 + _dirs[d].$1, p.$2 + _dirs[d].$2);
      if (at(q.$1, q.$2)) {
        final prevDir = _dirs[(d + 7) % 8];
        final prev    = (p.$1 + prevDir.$1, p.$2 + prevDir.$2);
        final rel     = (prev.$1 - q.$1, prev.$2 - q.$2);
        return (q, _dirs.indexOf(rel));
      }
    }
    return null;
  }

  // The cell west of the start is empty: it was scanned before it.
  final first = next(start, 6);
  if (first == null) return [start];
  final contour = [start];
  var (p, back) = first;
  for (var guard = 0; guard < 4 * w * h; guard++) {
    if (p == start) {
      final n = next(p, back);
      if (n == null || n.$1 == first.$1) break;
    }
    contour.add(p);
    final n = next(p, back)!;
    (p, back) = n;
  }
  return contour;
}

// ── Simplify ───────────────────────────────────────────────────────────────

/// A closed polygon simplified by Douglas–Peucker, split at its two points
/// farthest apart so neither half is degenerate.
List<Offset> _simplifyClosed(List<Offset> pts, double eps) {
  if (pts.length < 4) return pts;
  var far = 0;
  var best = 0.0;
  for (var i = 1; i < pts.length; i++) {
    final d = (pts[i] - pts[0]).distanceSquared;
    if (d > best) {
      best = d;
      far = i;
    }
  }
  final a = _dp(pts.sublist(0, far + 1), eps);
  final b = _dp([...pts.sublist(far), pts[0]], eps);
  return [...a.sublist(0, a.length - 1), ...b.sublist(0, b.length - 1)];
}

List<Offset> _dp(List<Offset> pts, double eps) {
  if (pts.length < 3) return pts;
  final a = pts.first, b = pts.last;
  var idx = 0;
  var max = 0.0;
  for (var i = 1; i < pts.length - 1; i++) {
    final d = _lineDistance(pts[i], a, b);
    if (d > max) {
      max = d;
      idx = i;
    }
  }
  if (max <= eps) return [a, b];
  final left = _dp(pts.sublist(0, idx + 1), eps);
  return [...left.sublist(0, left.length - 1), ..._dp(pts.sublist(idx), eps)];
}

double _area(List<Offset> p) {
  var s = 0.0;
  for (var i = 0; i < p.length; i++) {
    final a = p[i], b = p[(i + 1) % p.length];
    s += a.dx * b.dy - b.dx * a.dy;
  }
  return s.abs() / 2;
}

double _lineDistance(Offset p, Offset a, Offset b) {
  final ab  = b - a;
  final len = ab.distance;
  if (len == 0) return (p - a).distance;
  return ((p.dx - a.dx) * ab.dy - (p.dy - a.dy) * ab.dx).abs() / len;
}


import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:image/image.dart' as img;

import 'mark_geometry.dart';
import 'outline.dart';

// Tracing a hold from a tap, in pure Dart so it runs the same on Android,
// Linux and the web build, and unit-tests on generated images.
//
// A hold is told from the wall by its edge, not its colour: chalk on a hold
// and a grey hold look like the wall, but every hold is ringed by an edge
// (its rim and the shadow under it). A window around the tap is sampled onto
// a grid of at most [_maxGrid] cells a side, in CIE Lab, and each cell gets
// its edge strength (the colour gradient).
//
// From the tap a flood gives each cell its level: the strongest edge on the
// easiest path to it. The cells below a level make a region around the tap,
// and raising the level grows it: through chalk and shading inside the hold,
// over the hold's rim, out into the wall. Of these regions the hold is the
// largest whose boundary runs along nearly the strongest edges on average.
// Chalk left inside it is filled. Where chalk runs out to the rim, the flood
// slips from it into the wall; so it also runs with bare wall (the photo's
// commonest colour) as a barrier, and the better of the two regions wins.
// No outline (a circle instead) when no region is ringed by a clear edge
// before it runs out of the window: a tap on bare wall, or a pale hold whose
// rim barely shows.
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
const _maxGrid = 200;

/// Steps an edge's strength is counted in, each [_levelStep] Lab units a
/// cell: up to an edge far stronger than any hold's.
const _levels    = 256;
const _levelStep = 0.25;

/// The span an edge's strength is measured across, in photo px: about how
/// far a hold's rim blurs into the wall at the stored photo size.
const _edgePx = 4;

/// The smallest hold, in photo px across: a foot chip.
const _minHoldPx = 8.0;

/// The radius of the disc around the tap the flood starts from, in photo
/// px: inside the smallest foot chip. And of the disc it starts from again
/// when the first lands in a bolt's hole: the bolt's.
const _seedPx = 3.0;
const _boltPx = 8.0;

/// The weakest edge, on average, that rings a hold: a colour gradient of
/// this many Lab units a cell.
const _minEdge = 3.0;

/// Colour distance (Lab) within which a cell is bare wall, and within which
/// a smooth cell is taken to be wall when reading the wall's colour here.
const _wallLike = 7.0;
const _wallNear = 8.0;

/// The weakest edge, on average, that rings a region grown with the wall as
/// a barrier: more than [_minEdge], as the barrier holds in a patch of wall.
const _walledEdge = 4.5;

/// What crossing bare wall costs the flood, as an edge's strength.
const _barrier = 24.0;

/// How clearly a larger region must be ringed, against the most clearly
/// ringed one, to be taken for the hold instead.
const _nearBest = 0.75;

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
  final n = gw * gh;

  // Each cell's mean colour, in Lab.
  final lab = Float64List(n * 3);
  for (var gy = 0; gy < gh; gy++) {
    for (var gx = 0; gx < gw; gx++) {
      var r = 0, g = 0, b = 0, k = 0;
      final sx = x0 + gx * step, sy = y0 + gy * step;
      for (var y = sy; y < math.min(sy + step, y1); y++) {
        var i = (y * w + sx) * 4;
        for (var x = sx; x < math.min(sx + step, x1); x++, i += 4) {
          r += px.rgba[i];
          g += px.rgba[i + 1];
          b += px.rgba[i + 2];
          k++;
        }
      }
      _toLab(r / k, g / k, b / k, lab, (gy * gw + gx) * 3);
    }
  }

  // Each cell's edge strength: the Sobel gradient's length in Lab, taken
  // across [_edgePx] photo px whatever the grid's step, so an edge reads
  // the same zoomed in or out.
  final grad = Float64List(n);
  final d = math.max(1, (_edgePx / step).round());
  double at(int x, int y, int k) =>
      lab[(y.clamp(0, gh - 1) * gw + x.clamp(0, gw - 1)) * 3 + k];
  for (var y = 0; y < gh; y++) {
    for (var x = 0; x < gw; x++) {
      var m = 0.0;
      for (var k = 0; k < 3; k++) {
        final dx = at(x + d, y - d, k) + 2 * at(x + d, y, k) + at(x + d, y + d, k)
                 - at(x - d, y - d, k) - 2 * at(x - d, y, k) - at(x - d, y + d, k);
        final dy = at(x - d, y + d, k) + 2 * at(x, y + d, k) + at(x + d, y + d, k)
                 - at(x - d, y - d, k) - 2 * at(x, y - d, k) - at(x + d, y - d, k);
        m += dx * dx + dy * dy;
      }
      grad[y * gw + x] = math.sqrt(m) / 8;
    }
  }
  int quantise(double g) => math.min(_levels - 1, (g / _levelStep).floor());

  // Bare wall: cells near the wall's colour, which the whole photo gives
  // and the window's own smooth cells near it adjust for the light here.
  final wall0  = _wallColour(px);
  final smooth = [
    for (var c = 0; c < n; c++)
      if (grad[c] < _minEdge && _dist(lab, c, wall0) < _wallNear) c,
  ];
  final wall = smooth.length < 16
      ? wall0
      : [
          for (var k = 0; k < 3; k++)
            _median([for (final c in smooth) lab[c * 3 + k]]),
        ];
  final isWall = Uint8List(n);
  for (var c = 0; c < n; c++) {
    if (_dist(lab, c, wall) < _wallLike) isWall[c] = 1;
  }

  // The cells in a disc of [r] photo px around cell (gx, gy).
  List<int> disc(int gx, int gy, double r) {
    final cr = (r / step).floor();
    return [
      for (var y = math.max(0, gy - cr); y <= math.min(gh - 1, gy + cr); y++)
        for (var x = math.max(0, gx - cr); x <= math.min(gw - 1, gx + cr); x++)
          if ((x - gx) * (x - gx) + (y - gy) * (y - gy) <= cr * cr) y * gw + x,
    ];
  }

  // The hold grown from [seeds], or null when no region around them is
  // ringed by a clear edge before it runs out of the window. With [barrier],
  // bare wall costs the flood as much as a hold's rim, so chalk running out
  // to the rim doesn't lead it out into the wall.
  ({Uint8List mask, int size, double score})? grow(List<int> seeds,
      {required bool barrier}) {
    // The flood, lowest level first: [order] lists the cells as they're
    // reached, so the region below any level is a prefix of it.
    final level   = Int32List(n)..fillRange(0, n, -1);
    final buckets = List.generate(_levels, (_) => <int>[]);
    final order   = <int>[];
    final wallLevel = barrier ? quantise(_barrier) : 0;
    buckets[0].addAll(seeds);
    for (var lv = 0; lv < _levels;) {
      if (buckets[lv].isEmpty) {
        lv++;
        continue;
      }
      final c = buckets[lv].removeLast();
      if (level[c] >= 0) continue;
      level[c] = lv;
      order.add(c);
      final x = c % gw, y = c ~/ gw;
      for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        if (nx < 0 || ny < 0 || nx >= gw || ny >= gh) continue;
        final nc = ny * gw + nx;
        if (level[nc] >= 0) continue;
        final l = math.max(quantise(grad[nc]), isWall[nc] * wallLevel);
        buckets[math.max(lv, l)].add(nc);
      }
    }

    // Grow the region cell by cell in that order, keeping the sum of the
    // edge strength just outside it. Each time the level steps up, the
    // region so far is a candidate, scored by the mean edge along its
    // boundary. Growth stops where the region reaches a side of the window
    // that isn't the photo's edge: it ran on past where a hold could end.
    final minCells = math.max(4, math.pi * math.pow(_minHoldPx / 2 / step, 2));
    final inRegion = Uint8List(n);
    var edgeSum = 0.0, edgeCount = 0, size = 0;
    final candidates = <(int, double)>[];
    for (var i = 0; i < order.length; i++) {
      final c = order[i];
      if (i > 0 && level[c] > level[order[i - 1]] && size >= minCells) {
        candidates.add((i, edgeSum / edgeCount));
      }
      final x = c % gw, y = c ~/ gw;
      if ((x == 0 && x0 > 0) || (y == 0 && y0 > 0) ||
          (x == gw - 1 && x1 < w) || (y == gh - 1 && y1 < h)) {
        break;
      }
      inRegion[c] = 1;
      size++;
      for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        if (nx < 0 || ny < 0 || nx >= gw || ny >= gh) continue;
        final nc = ny * gw + nx;
        if (inRegion[nc] == 1) {
          edgeSum -= grad[c];
          edgeCount--;
        } else {
          edgeSum += grad[nc];
          edgeCount++;
        }
      }
    }
    // The hold is the largest region ringed nearly as clearly as the best:
    // a bolt hole's washer is ringed more crisply than the hold around it.
    var bestScore = _minEdge;
    for (final (_, score) in candidates) {
      bestScore = math.max(bestScore, score);
    }
    var best = -1;
    var score = 0.0;
    for (final (i, s) in candidates) {
      if (s >= _nearBest * bestScore) (best, score) = (i, s);
    }
    if (best < 0) return null;
    final mask = Uint8List(n);
    for (var i = 0; i < best; i++) {
      mask[order[i]] = 1;
    }
    return (mask: mask, size: best, score: score);
  }

  // The flood starts from a small disc around the tap. It runs twice, with
  // the wall as a barrier and without: the barrier keeps the flood on a hold
  // whose chalk runs out to its rim, but cuts into a grey hold near the
  // wall's colour. Of the two the larger region wins, when it's ringed nearly
  // as clearly. A tap the wall's colour (bare wall, a pale hold) has only its
  // edge to go by.
  final sgx = ((tx - x0) / step).floor().clamp(0, gw - 1);
  final sgy = ((ty - y0) / step).floor().clamp(0, gh - 1);
  ({Uint8List mask, int size, double score})? from(List<int> seeds) {
    final tapColour = [
      for (var k = 0; k < 3; k++)
        _median([for (final c in seeds) lab[c * 3 + k]]),
    ];
    // A region not much bigger than the disc is a bolt's washer or a fleck;
    // one held in by the barrier alone, not an edge, is a patch of wall.
    bool fits(({Uint8List mask, int size, double score})? r, double minScore) =>
        r != null && r.size >= 2 * seeds.length && r.score >= minScore;
    var open   = grow(seeds, barrier: false);
    var walled = _distTo(tapColour, wall) >= _wallLike
        ? grow(seeds, barrier: true)
        : null;
    if (!fits(open, _minEdge)) open = null;
    if (!fits(walled, _walledEdge)) walled = null;
    final (small, large) = switch ((open, walled)) {
      (null, null)   => (null, null),
      (final a?, null) || (null, final a?) => (a, null),
      (final a?, final b?) => a.size <= b.size ? (a, b) : (b, a),
    };
    return large != null && large.score >= _nearBest * small!.score
        ? large
        : small;
  }

  // A tap on a bolt starts inside its hole, and the flood can't get past
  // the washer's ring to the hold: then again from a disc a bolt across.
  final region = from(disc(sgx, sgy, _seedPx)) ?? from(disc(sgx, sgy, _boltPx));
  if (region == null) return null;
  var mask = region.mask;

  // Fill what's left inside (chalk, a bolt), close small gaps (dilate,
  // erode), then grow it [d] cells, out past the rim: the region stops where
  // the edge starts to show, which is up to [d] cells short of it.
  mask = _fillHoles(mask, gw, gh);
  mask = _dilate(mask, gw, gh);
  mask = _erode(mask, gw, gh);
  for (var i = 0; i < d; i++) {
    mask = _dilate(mask, gw, gh);
  }

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

/// Distance in Lab between cell [c] of [lab] and [ref].
double _dist(Float64List lab, int c, List<double> ref) {
  final dl = lab[c * 3] - ref[0], da = lab[c * 3 + 1] - ref[1],
        db = lab[c * 3 + 2] - ref[2];
  return math.sqrt(dl * dl + da * da + db * db);
}

double _median(List<double> v) {
  v.sort();
  return v[v.length ~/ 2];
}

double _distTo(List<double> a, List<double> b) => math.sqrt(
    List.generate(3, (k) => a[k] - b[k]).fold(0.0, (s, d) => s + d * d));

final _wallColours = Expando<List<double>>();

/// The wall's colour in [px], in Lab: the commonest colour among patches
/// about 1/200 of the photo across. Worked out once a photo.
List<double> _wallColour(PhotoPixels px) =>
    _wallColours[px] ??= _commonestColour(px);

List<double> _commonestColour(PhotoPixels px) {
  final step   = math.max(1, math.max(px.width, px.height) ~/ 200);
  final counts = <int, int>{};
  final sums   = <int, List<double>>{};
  final lab    = Float64List(3);
  for (var y = 0; y + step <= px.height; y += step) {
    for (var x = 0; x + step <= px.width; x += step) {
      var r = 0, g = 0, b = 0;
      for (var yy = y; yy < y + step; yy++) {
        var i = (yy * px.width + x) * 4;
        for (var xx = x; xx < x + step; xx++, i += 4) {
          r += px.rgba[i];
          g += px.rgba[i + 1];
          b += px.rgba[i + 2];
        }
      }
      final k = step * step;
      _toLab(r / k, g / k, b / k, lab, 0);
      // Bins 4 Lab units a side.
      final bin = ((lab[0] ~/ 4) * 64 + (lab[1] ~/ 4 + 32)) * 64 + lab[2] ~/ 4 + 32;
      counts[bin] = (counts[bin] ?? 0) + 1;
      final sum = sums.putIfAbsent(bin, () => [0, 0, 0]);
      for (var j = 0; j < 3; j++) {
        sum[j] += lab[j];
      }
    }
  }
  final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return [for (final s in sums[top.key]!) s / top.value];
}

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
  out[i]     = 116 * fy - 16;
  out[i + 1] = 500 * (fx - fy);
  out[i + 2] = 200 * (fy - fz);
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


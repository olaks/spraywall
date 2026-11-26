import 'dart:math' as math;
import 'dart:ui';

import 'mark_geometry.dart';

// A hold's outline is a closed polygon stored normalised, like a mark's
// centre: each point's dx is 0..1 of the photo's width and dy 0..1 of its
// height. Uniform scaling in photo pixels is the same factor on both, so an
// outline scales about its centre without the photo's size; distances and
// overlap need the size, and are worked out in photo pixels.

/// A hold's outline: at least three points, normalised.
typedef Outline = List<Offset>;

/// An outline as stored in `Marks.outline`: `x y x y …`, four decimals
/// (a quarter of a pixel on a 2560 px photo).
String encodeOutline(Outline o) => [
      for (final p in o) ...[_fixed(p.dx), _fixed(p.dy)],
    ].join(' ');

String _fixed(double v) => v.toStringAsFixed(4);

/// The outline in [text], or null for a circle. Text that isn't an outline
/// also reads as a circle: the mark still shows, as its enclosing circle.
Outline? decodeOutline(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final nums = text.trim().split(RegExp(r'\s+')).map(double.tryParse).toList();
  if (nums.length.isOdd || nums.length < 6 || nums.contains(null)) return null;
  return [
    for (var i = 0; i < nums.length; i += 2) Offset(nums[i]!, nums[i + 1]!),
  ];
}

/// The outline in photo pixels.
List<Offset> outlinePx(Outline o, Size photo) => [
      for (final p in o) Offset(p.dx * photo.width, p.dy * photo.height),
    ];

/// Of the [saved] outlines, oldest first, the newest with [tap] inside it,
/// both normalised: a hold already outlined, perhaps fixed up by hand, is
/// taken as it was rather than traced again. Inside is the same in
/// normalised and pixel terms, so the photo's size isn't needed.
Outline? savedOutlineAt(Iterable<Outline> saved, Offset tap) =>
    saved.where((o) => pointInPolygon(tap, o)).lastOrNull;

/// The circle around [o], normalised like a mark: centred on the middle of
/// its bounding box, through its farthest point, r a fraction of width.
({double cx, double cy, double r}) enclosingCircle(Outline o, Size photo) {
  final b      = _bounds(o);
  final centre = b.center;
  final c      = centrePx(centre.dx, centre.dy, photo);
  final far    = outlinePx(o, photo)
      .map((p) => (p - c).distance)
      .reduce(math.max);
  return (cx: centre.dx, cy: centre.dy, r: far / photo.width);
}

Rect _bounds(Outline o) {
  var l = o.first.dx, r = l, t = o.first.dy, b = t;
  for (final p in o) {
    l = math.min(l, p.dx);
    r = math.max(r, p.dx);
    t = math.min(t, p.dy);
    b = math.max(b, p.dy);
  }
  return Rect.fromLTRB(l, t, r, b);
}

/// [o] shifted by [dx], [dy] (normalised), each point kept on the photo.
Outline moveOutline(Outline o, double dx, double dy) => [
      for (final p in o) _onPhoto(p.dx + dx, p.dy + dy),
    ];

/// [o] scaled by [factor] about [cx], [cy], each point kept on the photo.
Outline scaleOutline(Outline o, double factor, double cx, double cy) => [
      for (final p in o)
        _onPhoto(cx + (p.dx - cx) * factor, cy + (p.dy - cy) * factor),
    ];

Offset _onPhoto(double x, double y) =>
    Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

/// A mark's shape in photo pixels: its outline, or its circle.
Path markPath(double cx, double cy, double r, Outline? outline, Size photo) =>
    outline == null
        ? (Path()
          ..addOval(Rect.fromCircle(
              center: centrePx(cx, cy, photo), radius: radiusPx(r, photo))))
        : (Path()..addPolygon(outlinePx(outline, photo), true));

/// Draws a mark's shape the way every view does: a dark halo first, so the
/// colour reads on beige wood and plywood alike, then the role's colour.
void strokeMark(Canvas canvas, Path path, Color colour, double stroke) {
  canvas.drawPath(path, Paint()
    ..style       = PaintingStyle.stroke
    ..strokeWidth = stroke * 2.2
    ..strokeJoin  = StrokeJoin.round
    ..color       = const Color(0x8A000000));
  canvas.drawPath(path, Paint()
    ..style       = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeJoin  = StrokeJoin.round
    ..color       = colour);
}

// ── Overlap, in photo pixels ───────────────────────────────────────────────

/// A mark's shape in photo pixels, for overlap: a circle, or a polygon.
sealed class Shape {}

class CircleShape extends Shape {
  final Offset centre;
  final double radius;
  CircleShape(this.centre, this.radius);
}

class PolygonShape extends Shape {
  final List<Offset> points;
  PolygonShape(this.points);
}

/// A hair of slack, so shapes that touch exactly aren't lost to rounding.
const _slack = 1e-6;

/// Whether [a] and [b] cross or touch, one inside the other included.
bool shapesOverlap(Shape a, Shape b) => switch ((a, b)) {
      (CircleShape a, CircleShape b) =>
        (a.centre - b.centre).distance <= a.radius + b.radius + _slack,
      (CircleShape c, PolygonShape p) || (PolygonShape p, CircleShape c) =>
        _circleMeetsPolygon(c, p.points),
      (PolygonShape a, PolygonShape b) => _polygonsMeet(a.points, b.points),
    };

bool _circleMeetsPolygon(CircleShape c, List<Offset> poly) {
  if (pointInPolygon(c.centre, poly)) return true;
  for (var i = 0; i < poly.length; i++) {
    final d = _segmentDistance(c.centre, poly[i], poly[(i + 1) % poly.length]);
    if (d <= c.radius + _slack) return true;
  }
  return false;
}

bool _polygonsMeet(List<Offset> a, List<Offset> b) {
  for (var i = 0; i < a.length; i++) {
    final a1 = a[i], a2 = a[(i + 1) % a.length];
    for (var j = 0; j < b.length; j++) {
      if (_segmentsMeet(a1, a2, b[j], b[(j + 1) % b.length])) return true;
    }
  }
  // No edges cross: they meet only if one lies inside the other.
  return pointInPolygon(a.first, b) || pointInPolygon(b.first, a);
}

/// Even-odd point-in-polygon.
bool pointInPolygon(Offset p, List<Offset> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

double _segmentDistance(Offset p, Offset a, Offset b) {
  final ab  = b - a;
  final len = ab.distanceSquared;
  if (len == 0) return (p - a).distance;
  final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len)
      .clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

double _cross(Offset o, Offset a, Offset b) =>
    (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

bool _segmentsMeet(Offset p1, Offset p2, Offset q1, Offset q2) {
  final d1 = _cross(q1, q2, p1), d2 = _cross(q1, q2, p2);
  final d3 = _cross(p1, p2, q1), d4 = _cross(p1, p2, q2);
  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }
  // Collinear or touching: an endpoint lies on the other segment.
  return _segmentDistance(p1, q1, q2) <= _slack ||
      _segmentDistance(p2, q1, q2) <= _slack ||
      _segmentDistance(q1, p1, p2) <= _slack ||
      _segmentDistance(q2, p1, p2) <= _slack;
}

/// Points an outline keeps, at most: few enough that each has a handle a
/// thumb can grab. And how far, as a share of the hold's size across, an
/// outline may cut a corner to keep fewer.
const _maxPoints = 16;
const _cornerCut = 0.04;

/// A hold's outline from a closed path of [px] (photo pixels, on a photo of
/// [photo] pixels): a traced edge or a finger's stroke, simplified to a
/// handful of points that keep its shape. Corners are cut by at least
/// [minCut] px. Null when it isn't a shape: fewer than three points, or
/// less than [minArea] px² inside.
Outline? simplifyOutline(List<Offset> px, Size photo,
    {double minCut = 0, double minArea = 1}) {
  if (px.length < 3) return null;
  var eps    = math.max(minCut, _cornerCut * math.sqrt(_area(px)));
  var simple = _simplifyClosed(px, eps);
  while (simple.length > _maxPoints) {
    eps   *= 1.5;
    simple = _simplifyClosed(px, eps);
  }
  if (simple.toSet().length < 3 || _area(simple) < minArea) return null;
  return [
    for (final p in simple)
      Offset((p.dx / photo.width).clamp(0.0, 1.0),
             (p.dy / photo.height).clamp(0.0, 1.0)),
  ];
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


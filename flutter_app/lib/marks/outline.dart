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

import 'dart:ui' show Size;

import '../database/database.dart';
import 'mark_geometry.dart';
import 'outline.dart';

/// Whether [a] and [b] mark the same hold, as near as marks can say: on the
/// same photo, with shapes (circles or hold outlines) that cross or touch,
/// one inside the other included. Compared in photo pixels, where circles
/// are round: in the 0..1 coordinates a mark is stored in, x and y are
/// scaled differently.
bool marksOverlap(Mark a, Mark b, Size photo) {
  if (a.photoId != b.photoId) return false;
  // Every mark's circle holds its shape: circles apart, shapes apart.
  final apart = (centrePx(a.cx, a.cy, photo) - centrePx(b.cx, b.cy, photo))
      .distance;
  if (apart > radiusPx(a.r, photo) + radiusPx(b.r, photo) + 1e-6) return false;
  return shapesOverlap(_shape(a, photo), _shape(b, photo));
}

Shape _shape(Mark m, Size photo) => switch (decodeOutline(m.outline)) {
      final o? => PolygonShape(outlinePx(o, photo)),
      null     => CircleShape(centrePx(m.cx, m.cy, photo), radiusPx(m.r, photo)),
    };

/// The other problems with a mark overlapping [tapped], each once, in the
/// order of [marks]. The tapped mark's own problem is left out: the sheet
/// shows it on its own.
List<String> overlappingProblems(Mark tapped, Iterable<Mark> marks, Size photo) {
  final out = <String>{};
  for (final m in marks) {
    if (m.problemId != tapped.problemId && marksOverlap(tapped, m, photo)) {
      out.add(m.problemId);
    }
  }
  return out.toList();
}

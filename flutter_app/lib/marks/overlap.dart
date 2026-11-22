import 'dart:ui' show Size;

import '../database/database.dart';
import 'mark_geometry.dart';

/// Whether [a] and [b] mark the same hold, as near as marks can say: on the
/// same photo, with circles that cross or touch (one inside the other
/// included). Compared in photo pixels, where circles are round: in the 0..1
/// coordinates a mark is stored in, x and y are scaled differently.
bool marksOverlap(Mark a, Mark b, Size photo) {
  if (a.photoId != b.photoId) return false;
  final apart = (centrePx(a.cx, a.cy, photo) - centrePx(b.cx, b.cy, photo))
      .distance;
  // A hair of slack, so circles that touch exactly aren't lost to rounding.
  return apart <= radiusPx(a.r, photo) + radiusPx(b.r, photo) + 1e-6;
}

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

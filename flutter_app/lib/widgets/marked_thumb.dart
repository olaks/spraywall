import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../marks/mark_editor.dart';
import '../marks/mark_geometry.dart';
import '../marks/outline.dart';
import '../providers/app_providers.dart';

/// A photo's thumbnail with [marks] drawn on it, as large as fits its box
/// at the photo's own shape, so the marks land where they do on the photo.
/// Loads only the thumbnail bytes.
class MarkedThumb extends ConsumerWidget {
  final WallPhoto      photo;
  final List<EditMark> marks;
  const MarkedThumb({super.key, required this.photo, required this.marks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumb = ref.watch(photoThumbProvider(photo.id)).value;
    return Center(
      child: AspectRatio(
        aspectRatio: photo.width / photo.height,
        child: Stack(fit: StackFit.expand, children: [
          thumb == null
              ? ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest)
              : Image.memory(thumb, fit: BoxFit.fill, gaplessPlayback: true),
          CustomPaint(painter: _ThumbMarks(marks)),
        ]),
      ),
    );
  }
}

/// The same marks as on the photo, scaled to the thumbnail, with a floor
/// so a foot chip still shows.
class _ThumbMarks extends CustomPainter {
  final List<EditMark> marks;
  _ThumbMarks(this.marks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in marks) {
      paint.color = roleColors[m.role]!;
      // A hold too small to show its shape here shows as the floor's circle.
      if (m.outline == null || radiusPx(m.r, size) < 3) {
        canvas.drawCircle(
          centrePx(m.cx, m.cy, size),
          radiusPx(m.r, size).clamp(1.5, double.infinity),
          paint,
        );
      } else {
        canvas.drawPath(markPath(m.cx, m.cy, m.r, m.outline, size), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ThumbMarks old) => old.marks != marks;
}

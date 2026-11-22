import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../marks/mark_editor.dart';
import '../marks/mark_geometry.dart';
import '../providers/app_providers.dart';
import '../screens/photos/photos_screen.dart' show photoTitle;

/// The layout's photos as thumbnails, to switch the one a problem screen
/// shows. Each carries its label, this problem's marks and a count per role;
/// the current one is outlined. Taps only: there is no swiping between
/// photos. Takes no room for a layout with a single photo.
class PhotoStrip extends StatelessWidget {
  /// Under the photo on a phone.
  static const height = 96.0;

  final List<WallPhoto>      photos;
  final String               currentId;
  final List<EditMark>       marks;
  final ValueChanged<String> onSelect;

  /// The view's strip: photos without this problem's marks are dimmed, but
  /// still selectable.
  final bool dimUnmarked;

  const PhotoStrip({
    super.key,
    required this.photos,
    required this.currentId,
    required this.marks,
    required this.onSelect,
    this.dimUnmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.length < 2) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        height: height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            for (final (i, p) in photos.indexed)
              _Thumb(
                key:     ValueKey('strip-${p.id}'),
                photo:   p,
                title:   photoTitle(p, i),
                marks:   [for (final m in marks) if (m.photoId == p.id) m],
                current: p.id == currentId,
                dimUnmarked: dimUnmarked,
                onTap:   () => onSelect(p.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends ConsumerWidget {
  final WallPhoto      photo;
  final String         title;
  final List<EditMark> marks;
  final bool           current;
  final bool           dimUnmarked;
  final VoidCallback   onTap;

  const _Thumb({
    super.key,
    required this.photo,
    required this.title,
    required this.marks,
    required this.current,
    required this.dimUnmarked,
    required this.onTap,
  });

  // Every row has a fixed height, so the thumb fits the strip whatever the
  // font's line height: 4 + 4 + 48 + 2 + 16 + 12 + 4 + 4 = 94 of 96.
  static const _imageBox = Size(96, 48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final thumb = ref.watch(photoImageProvider(photo.id)).value?.thumb;
    final counts = {
      for (final r in Role.values)
        if (marks.where((m) => m.role == r).length case final n when n > 0)
          r: n,
    };

    return Semantics(
      button:   true,
      selected: current,
      label:    title,
      excludeSemantics: true,
      child: Opacity(
        opacity: dimUnmarked && marks.isEmpty ? 0.4 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width:   _imageBox.width + 8,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  width: 2,
                  color: current ? theme.colorScheme.primary : Colors.transparent,
                ),
              ),
              child: Column(children: [
                SizedBox.fromSize(
                  size: _imageBox,
                  child: Center(
                    // Exactly the photo's shape, so the marks land on it.
                    child: AspectRatio(
                      aspectRatio: photo.width / photo.height,
                      child: Stack(fit: StackFit.expand, children: [
                        thumb == null
                            ? ColoredBox(color: theme.colorScheme.surfaceContainerHighest)
                            : Image.memory(thumb, fit: BoxFit.fill, gaplessPlayback: true),
                        CustomPaint(painter: _ThumbMarks(marks)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 16,
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall),
                ),
                SizedBox(
                  height: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final MapEntry(key: role, value: n) in counts.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Row(children: [
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: roleColors[role],
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text('$n',
                                key:   ValueKey('count-${photo.id}-${role.name}'),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontSize: 10, height: 1)),
                          ]),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A thumbnail's marks: the same circles as on the photo, scaled to the
/// thumbnail, with a floor so a foot chip still shows.
class _ThumbMarks extends CustomPainter {
  final List<EditMark> marks;
  _ThumbMarks(this.marks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in marks) {
      canvas.drawCircle(
        centrePx(m.cx, m.cy, size),
        radiusPx(m.r, size).clamp(1.5, double.infinity),
        Paint()
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color       = roleColors[m.role]!,
      );
    }
  }

  @override
  bool shouldRepaint(_ThumbMarks old) => old.marks != marks;
}

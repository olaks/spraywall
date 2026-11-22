import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/app_providers.dart';

/// The transform that shows [content] whole and centred in [viewport].
///
/// All three axes scale: `getMaxScaleOnAxis()` reads z too, so a fit that
/// leaves z at 1 reports a zoom of 1 and every zoom-scaled size is wrong.
Matrix4 fitTransform(Size viewport, Size content) {
  final f = math.min(viewport.width / content.width,
                     viewport.height / content.height);
  return Matrix4.diagonal3Values(f, f, f)
    ..setTranslationRaw((viewport.width  - content.width  * f) / 2,
                        (viewport.height - content.height * f) / 2, 0);
}

/// One photo's pan and zoom, plus what [ZoomablePhoto] needs to decide
/// whether to fit: kept apart from the widget, so a photo shown again (after
/// switching to another) comes back where it was left instead of refitting.
class PhotoViewController extends TransformationController {
  /// The viewport and fit factor of the last fit; null until the first.
  Size?   _viewport;
  double? _fit;
}

/// A wall photo in an `InteractiveViewer`, fitted to the screen and free to
/// pan and zoom. Its child is a box the size of the photo, so anything
/// [overlay] draws or hit-tests is in photo pixels.
class ZoomablePhoto extends StatefulWidget {
  final WallPhoto                 photo;
  final PhotoViewController?      controller;
  final Widget?                   overlay;

  /// Off while a mark or its handle is held, so the drag moves the mark
  /// instead of the photo. Zooming stays on.
  final bool panEnabled;

  const ZoomablePhoto({
    super.key,
    required this.photo,
    this.controller,
    this.overlay,
    this.panEnabled = true,
  });

  @override
  State<ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<ZoomablePhoto> {
  late final PhotoViewController _tc =
      widget.controller ?? PhotoViewController();

  @override
  void dispose() {
    if (widget.controller == null) _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo   = Size(widget.photo.width.toDouble(),
                         widget.photo.height.toDouble());
    return LayoutBuilder(builder: (context, box) {
      final viewport = box.biggest;
      final fit = math.min(viewport.width / photo.width,
                           viewport.height / photo.height);
      // Fit on first show, and again on a resize unless the user has zoomed
      // in, so rotating a phone doesn't throw away a close-up.
      final last     = _tc._fit;
      final zoomedIn = last != null && _tc.value.getMaxScaleOnAxis() > last * 1.05;
      if (last == null || (viewport != _tc._viewport && !zoomedIn)) {
        _tc.value = fitTransform(viewport, photo);
        _tc._fit  = fit;
      }
      _tc._viewport = viewport;

      return ColoredBox(
        color: Colors.black,
        child: InteractiveViewer(
          transformationController: _tc,
          constrained:    false,
          panEnabled:     widget.panEnabled,
          minScale:       fit * 0.8,
          // Up to 4 screen px per photo px; a small photo fits above that.
          maxScale:       math.max(4, fit * 2),
          // Room to centre a portrait photo on a landscape screen and back.
          boundaryMargin: const EdgeInsets.all(1500),
          child: SizedBox.fromSize(
            size:  photo,
            child: Stack(children: [
              Positioned.fill(child: _PhotoImage(widget.photo)),
              if (widget.overlay case final overlay?)
                Positioned.fill(child: overlay),
            ]),
          ),
        ),
      );
    });
  }
}

class _PhotoImage extends ConsumerWidget {
  final WallPhoto photo;
  const _PhotoImage(this.photo);

  /// Safety net for photos that came in some other way than the import
  /// (a hand-edited backup, say): never decode more than this per edge.
  static const _maxDecode = 4096;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(photoImageProvider(photo.id)).value;
    if (image == null) return const SizedBox.expand();
    final tooWide = photo.width >= photo.height && photo.width > _maxDecode;
    final tooTall = photo.height > photo.width && photo.height > _maxDecode;
    return Image.memory(
      image.data,
      fit:           BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      cacheWidth:    tooWide ? _maxDecode : null,
      cacheHeight:   tooTall ? _maxDecode : null,
    );
  }
}

# Zoomable wall photo with a mark overlay (Flutter)

Research for [issue 02](../issues/02-zoomable-photo-with-mark-overlay.md). Checked against the Flutter SDK source in `~/sdk/flutter` (Flutter 3.41.7 stable, Dart 3.11.5, engine source in the monorepo under `engine/src/flutter`) and pub.dev on 2026-11-21. training_logger's `flutter_app/pubspec.yaml` uses `sdk: '>=3.3.0 <4.0.0'`.

## Recommendation

Use the framework's **`InteractiveViewer`** (with `constrained: false` and an external `TransformationController`). Its child is a `SizedBox` the size of the decoded **wall photo**: a `Stack` holding the `Image` and the **marks**. Each mark is a small widget with its own `GestureDetector`, and a `GestureDetector` over the photo handles taps on empty space.

Because the hit test passes through the `Transform`, `localPosition` and `delta` in gesture callbacks inside the child are **already in photo (scene) coordinates**. You don't need to do any coordinate maths yourself. When you do need it (for example, a detector outside the viewer), use `TransformationController.toScene(viewportPoint)`.

Store mark geometry normalised to the photo: centre `(cx, cy)` in 0..1 of photo width and height, and radius `r` as a fraction of photo **width**. Decode the photo with `ResizeImage` (`policy: ResizeImagePolicy.fit`) so the long edge is at most 4096 px. Don't use packages and don't tile.

## Findings

### 1. InteractiveViewer vs. packages

**InteractiveViewer (built in).**
- **Gestures it handles.** Its `build` wraps the child in a `Listener(onPointerSignal: …)` and a `GestureDetector(onScaleStart/Update/End, trackpadScrollCausesScale: …)`. The child is drawn through a `Transform(transform: matrix)` ([source: `packages/flutter/lib/src/widgets/interactive_viewer.dart`, `build`][iv-src]; [API][iv-api]). That one scale recognizer covers one-finger pan, two-finger pinch, left-mouse drag and trackpad pan/zoom. The pointer-signal listener handles the mouse wheel.
- **Mouse wheel.** It zooms by `exp(-scrollDelta.dy / scaleFactor)` around the cursor. The default `scaleFactor` is `kDefaultMouseScrollToScaleFactor = 200` ([`gestures/scale.dart`][scale-src]). The docs say the engine hard-codes a wheel `scrollDelta` of 20 per notch ([`scaleFactor` docs][iv-api]).
- **Trackpad two-finger scroll.** It **pans** unless `trackpadScrollCausesScale: true` (source of `_receivedPointerSignal`).
- **Mapping a screen tap to photo coordinates.** `TransformationController.toScene(Offset)` inverts the matrix: `Matrix4.inverted(value).transform3(...)`, per the source and [toScene API][toscene]. The class docs show exactly this pattern: `GestureDetector(onTapUp: (d) => controller.toScene(d.localPosition), child: InteractiveViewer(...))`.
- **Content larger than the viewport.** It needs `constrained: false` so the child can lay out at its own size ([`constrained` docs][iv-api]). `minScale` defaults to 0.8 and `maxScale` to 2.5, so set both explicitly.
- **Rebuilding on zoom.** `TransformationController` is a `ValueNotifier<Matrix4>`. Listen to it with `ListenableBuilder` to keep stroke widths and handle sizes constant on screen; `getMaxScaleOnAxis()` returns the current zoom.

**photo_view (0.15.0, last published about 2 years ago)** ([pub.dev][photoview]). It works on all six platforms and can wrap any child, and it has `PhotoViewController` streams for position and scale. However:
- Its README doesn't mention mouse-wheel zoom or overlays.
- There is no `toScene`-style API, so you would rebuild the matrix from scale and position yourself.
- It is unmaintained relative to the SDK.

**extended_image (10.1.0, published about 4 months ago)** ([pub.dev][extimg]). Gesture mode has min/max scale and inertia, and `afterPaintImage` lets you paint on the canvas. However:
- The README documents no screen-to-image mapping and no mouse-wheel support.
- Painting in `afterPaintImage` gives you no per-mark hit testing or gestures, so dragging and resizing marks would all be hand-written.

**Verdict.** Both packages solve "view a photo", not "edit things on a photo". InteractiveViewer gives us the matrix, `toScene`, wheel and trackpad support, and real child widgets with their own gestures, at no dependency cost.

### 2. Gesture conflicts

- **Mapping is free inside the child.** The child sits under a `Transform`, so `DragUpdateDetails.delta` is "in the coordinate space of the event receiver" ([`gestures/drag_details.dart`][drag-details]). The same holds for `localPosition` on tap, drag and long-press details. A `GestureDetector` on a mark or on the photo therefore reports **photo-space** values directly, at any zoom.
- **Pan vs. dragging a mark.** The viewer's `ScaleGestureRecognizer` accepts once the focal point moves more than `computePanSlop` (`kPanSlop` = 2 × `kTouchSlop` = 36 px for touch), once the span changes by more than `kScaleSlop` (18), or once the scale ratio exceeds 1.05 ([`gestures/scale.dart` around line 745][scale-src]; [`gestures/constants.dart`][constants]).
  - A child `onPan*` recognizer uses the same `computePanSlop`, and the child comes earlier on the hit-test path, so it sees the crossing move first and wins the arena.
  - Result: a one-finger drag that **starts on a mark that has a pan handler** moves the mark. A drag that starts anywhere else pans the photo.
- **Only the selected mark should be draggable.** Holds are dense (about 200, some tiny), so if every mark took drags, starting a pan on a mark would be nearly impossible. Give `onPan*` only to the **selected** mark and its resize handle. Unselected marks get `onTap` only, and a tap recognizer loses to the viewer once the finger moves beyond slop.
  - For extra safety, set `panEnabled: false` on the viewer from a `Listener.onPointerDown` on the selected mark, and clear it on pointer up. That way a mark drag can never leak into a pan.
- **Avoid `onDoubleTap` on the photo.** It makes every single tap wait for the double-tap timeout (`kDoubleTapTimeout`, 300 ms), which makes placing marks feel slow. Use explicit zoom buttons instead, or wheel/pinch.
- **Long press** (`kLongPressTimeout` 500 ms) works on touch. It is awkward with a mouse and has no meaning on a trackpad, so don't make it the only way to do anything. Map the same action to secondary click (`onSecondaryTapUp`) for desktop and Web.
- **Mouse.** Left drag on empty photo pans, the wheel zooms around the cursor, and left drag on the selected mark moves it. Precise devices use smaller slops (`kPrecisePointerPanSlop` and related constants in `constants.dart`), so mouse drags start promptly.
- **Trackpad on Linux and Web.** Two-finger scroll pans by default and pinch arrives as pan/zoom events to the scale recognizer. I haven't tested the GTK embedder's trackpad pinch support on real hardware.

### 3. Rendering a 3120×4160 photo

- **Decoded size.** The photo decodes to 3120 × 4160 × 4 B ≈ **49.5 MiB** RGBA. The default `ImageCache.maximumSizeBytes` is 100 MiB (`_kDefaultSizeBytes = 100 << 20`, [`painting/image_cache.dart`][imgcache]), so one full-size photo fits but two nearly fill it.
- **Max texture size on Android (Impeller).** `ImageDecoderImpeller::DecompressTexture` clamps the target size to the GPU max texture size, and if the source is larger it falls back to a "slow CPU resize" (`engine/src/flutter/lib/ui/painting/image_decoder_impeller.cc`, lines ~346–351 and ~419–423; [mirror][impeller-dec]).
  - **The clamp is per axis.** The code does `min(max_w, target_w)` and `min(max_h, target_h)` separately. On a GPU with a 4096 limit, the 4160 px height would be clamped to 4096 and the 3120 width left unchanged. That looks like a slight squash unless we cap the size ourselves.
  - Many mid-range GPUs report a max texture size of 4096, and the OpenGL ES 3.0 / WebGL 2 minimum is lower still.
- **Web (CanvasKit/skwasm).** skwasm decodes with the browser `ImageDecoder` and then wraps it in a `ResizingCodec`, which scales each **full-size** decoded frame down to `targetWidth`/`targetHeight` (`engine/src/flutter/lib/web_ui/lib/src/engine/image_decoder.dart`, `ResizingCodec`; `skwasm/skwasm_impl/renderer.dart` `instantiateImageCodec`). `cacheWidth` therefore lowers steady-state GPU memory on the web but **not** peak decode memory.
- **No tiling needed.** One texture of at most 4096 px on its long edge is a single `drawImage`. Panning and zooming change only the layer transform, so the image isn't re-decoded or re-rasterised.
- **What to do.**
  - Wrap the provider in `ResizeImage(provider, width: 4096, height: 4096, policy: ResizeImagePolicy.fit)`. This preserves aspect ratio and doesn't upscale by default ([`ResizeImagePolicy`][resizepolicy]).
  - **Better still:** when a photo is imported, write a downscaled display copy (long edge about 3000–4096) next to the original. This keeps memory low on the web too, and the original stays available if we need it later.
  - Set `filterQuality: FilterQuality.medium` so tiny holds stay legible when zoomed out.
  - Allow a `maxScale` that reaches roughly 2–3 screen px per photo px, enough to place marks on the tiniest holds.

### 4. Storing mark geometry

Store marks in a resolution-independent form, keyed to their wall photo:

| column | meaning |
| --- | --- |
| `photoId` | the one wall photo the mark sits on |
| `problemId`, `role` | owner and role: start / hand / foot / finish |
| `cx`, `cy` | centre as a fraction of photo width and height (0..1) |
| `r` | radius as a fraction of photo **width** |
| ellipse (stretch goal) | `rx`, `ry` (both fractions of width) and `rotation` in radians. A circle is `rx == ry`, so this can replace `r` later without migrating data. |

- **Why this survives screen and resolution changes.** Pixels are square, so a radius relative to width stays a circle at any decode size. The same mark lines up on a downscaled display copy, on the full-resolution original, and on every screen size, because widget positions are `cx * sceneW` and so on.
- **Fix orientation at import.** The sample JPEG has no EXIF orientation tag, but phone photos often do. Rotate the pixels upright when importing, so the stored fractions always refer to an upright pixel grid regardless of decoder or platform.
- **Draw strokes and handles at a constant screen size.** Divide stroke widths and handle sizes by `controller.value.getMaxScaleOnAxis()`. The radius itself stays in photo space.

## Minimal sketch

```dart
// WallPhotoView: wall photo + marks, pinch/wheel zoom, tap to place, drag/resize selected mark.
class Mark { // normalised geometry; see table above
  final String id; final Role role; final double cx, cy, r;
  const Mark(this.id, this.role, this.cx, this.cy, this.r);
}

class WallPhotoView extends StatefulWidget {
  const WallPhotoView({super.key, required this.photo, required this.photoSize,
      required this.marks, this.selectedId, required this.onTapEmpty,
      required this.onTapMark, required this.onMoveMark, required this.onResizeMark});
  final ImageProvider photo;
  final Size photoSize;              // decoded size of the display copy
  final List<Mark> marks;
  final String? selectedId;
  final void Function(double cx, double cy) onTapEmpty;
  final void Function(String id) onTapMark;
  final void Function(String id, double dcx, double dcy) onMoveMark;
  final void Function(String id, double dr) onResizeMark;
  @override State<WallPhotoView> createState() => _WallPhotoViewState();
}

class _WallPhotoViewState extends State<WallPhotoView> {
  final _tc = TransformationController();
  bool _panEnabled = true;

  @override
  Widget build(BuildContext context) {
    final w = widget.photoSize.width, h = widget.photoSize.height;
    return LayoutBuilder(builder: (context, box) {
      final fit = math.min(box.maxWidth / w, box.maxHeight / h);
      if (_tc.value.isIdentity()) _tc.value = Matrix4.diagonal3Values(fit, fit, 1);
      return InteractiveViewer(
        transformationController: _tc,
        constrained: false,
        panEnabled: _panEnabled,
        minScale: fit * 0.9,
        maxScale: 3,                       // ~3 screen px per photo px
        boundaryMargin: const EdgeInsets.all(200),
        child: SizedBox(
          width: w, height: h,
          child: ListenableBuilder(
            listenable: _tc,
            builder: (context, _) {
              final zoom = _tc.value.getMaxScaleOnAxis();
              return Stack(children: [
                // Tap on empty photo: localPosition is already in photo space.
                Positioned.fill(child: GestureDetector(
                  onTapUp: (d) => widget.onTapEmpty(d.localPosition.dx / w, d.localPosition.dy / h),
                  child: Image(
                    image: ResizeImage(widget.photo, width: 4096, height: 4096,
                        policy: ResizeImagePolicy.fit),
                    filterQuality: FilterQuality.medium, fit: BoxFit.fill),
                )),
                for (final m in widget.marks) _markWidget(m, w, h, zoom),
              ]);
            },
          ),
        ),
      );
    });
  }

  Widget _markWidget(Mark m, double w, double h, double zoom) {
    final rPx = m.r * w;
    final selected = m.id == widget.selectedId;
    final stroke = 3 / zoom;               // constant on-screen width
    final circle = CustomPaint(
      size: Size.square(rPx * 2),
      painter: _CirclePainter(colorFor(m.role), stroke, selected),
    );
    return Positioned(
      left: m.cx * w - rPx, top: m.cy * h - rPx,
      width: rPx * 2, height: rPx * 2,
      child: Listener(
        // Stop the viewer stealing a drag that starts on the selected mark.
        onPointerDown: selected ? (_) => setState(() => _panEnabled = false) : null,
        onPointerUp: (_) => setState(() => _panEnabled = true),
        onPointerCancel: (_) => setState(() => _panEnabled = true),
        child: GestureDetector(
          onTap: () => widget.onTapMark(m.id),
          // delta is in the receiver's (photo) coordinate space.
          onPanUpdate: selected
              ? (d) => widget.onMoveMark(m.id, d.delta.dx / w, d.delta.dy / h)
              : null,
          child: selected
              ? Stack(clipBehavior: Clip.none, children: [
                  circle,
                  Positioned( // resize handle on the right edge, constant screen size
                    right: -12 / zoom, top: rPx - 12 / zoom,
                    width: 24 / zoom, height: 24 / zoom,
                    child: GestureDetector(
                      onPanUpdate: (d) => widget.onResizeMark(m.id, d.delta.dx / w),
                      child: const DecoratedBox(decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white)),
                    ),
                  ),
                ])
              : circle,
        ),
      ),
    );
  }
}

// If a detector ever sits OUTSIDE the viewer:
//   final scene = _tc.toScene(details.localPosition); // photo-space px
```

Notes on the sketch:
- `Positioned` children of a `Stack` are hit-tested in reverse paint order, so later marks win when circles overlap. Paint the selected mark last.
- A mark that is visually tiny at low zoom is hard to tap. Give unselected marks a minimum hit area of about `24 / zoom` photo px, while keeping the drawn radius true.

## Sources

- InteractiveViewer API and source: [api.flutter.dev/flutter/widgets/InteractiveViewer-class.html][iv-api]; `packages/flutter/lib/src/widgets/interactive_viewer.dart` in Flutter 3.41.7 ([GitHub][iv-src])
- `TransformationController.toScene`: [api.flutter.dev][toscene]
- Scale recognizer acceptance and wheel/trackpad factors: `packages/flutter/lib/src/gestures/scale.dart` ([GitHub][scale-src])
- Slop constants: `packages/flutter/lib/src/gestures/constants.dart` ([GitHub][constants])
- Drag delta coordinate space: `packages/flutter/lib/src/gestures/drag_details.dart` ([GitHub][drag-details])
- Image cache default size: `packages/flutter/lib/src/painting/image_cache.dart` ([GitHub][imgcache])
- `ResizeImagePolicy.fit`: [api.flutter.dev][resizepolicy]
- Impeller decode clamp and CPU resize: `engine/src/flutter/lib/ui/painting/image_decoder_impeller.cc` ([googlesource mirror][impeller-dec])
- Web resizing codec: `engine/src/flutter/lib/web_ui/lib/src/engine/image_decoder.dart` and `skwasm/skwasm_impl/renderer.dart` in Flutter 3.41.7
- photo_view: [pub.dev/packages/photo_view][photoview]; extended_image: [pub.dev/packages/extended_image][extimg]

[iv-api]: https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html
[iv-src]: https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/widgets/interactive_viewer.dart
[toscene]: https://api.flutter.dev/flutter/widgets/TransformationController/toScene.html
[scale-src]: https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/gestures/scale.dart
[constants]: https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/gestures/constants.dart
[drag-details]: https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/gestures/drag_details.dart
[imgcache]: https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/painting/image_cache.dart
[resizepolicy]: https://api.flutter.dev/flutter/painting/ResizeImagePolicy.html
[impeller-dec]: https://flutter.googlesource.com/mirrors/engine/+/HEAD/lib/ui/painting/image_decoder_impeller.cc
[photoview]: https://pub.dev/packages/photo_view
[extimg]: https://pub.dev/packages/extended_image

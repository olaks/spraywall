# Zoomable photo with tappable circle overlay in Flutter

Type: research
Status: resolved
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

What's the best Flutter approach to show a large **wall photo** with pinch-zoom/pan (touch) and wheel-zoom/drag (mouse), with circle **marks** drawn on top that can be tapped, placed, dragged and resized, on Android, Linux and Web?

Find out:
- `InteractiveViewer` + `CustomPainter`/`Stack` versus packages (`photo_view`, `extended_image`, others); how each maps a tap in screen space back to photo coordinates under the current transform.
- Gesture conflicts: one-finger pan vs. dragging a mark; long-press; desktop mouse and trackpad.
- Rendering performance of a ~3000×4000 image on mid-range Android and on Web (CanvasKit/skwasm); whether a decoded-size cap or tiling is needed.
- How to store mark geometry so it survives screen sizes and photo downscaling (e.g. normalised 0..1 centre plus radius relative to photo width).

Recommend one approach, with sources and a minimal code sketch.

## Answer

Use the built-in **`InteractiveViewer`** (`constrained: false`, external `TransformationController`); don't use `photo_view` or `extended_image`. Its child is a `SizedBox` the size of the decoded **wall photo**, holding a `Stack` of the `Image` and one widget per **mark**, each with its own `GestureDetector`.

- **Coordinates.** Gesture `localPosition` and `delta` inside the transformed child are already in photo coordinates. `controller.toScene()` covers detectors outside the viewer.
- **Gestures.**
  - Tap on empty photo places a mark; tap on a mark selects it.
  - Only the **selected** mark (and its resize handle) takes pan gestures. It wins the gesture arena over the viewer's pan, and a `Listener` sets `panEnabled: false` while it is pressed.
  - Wheel zoom and trackpad pan/pinch work out of the box.
  - Avoid `onDoubleTap`, because it delays every tap. Mirror long press with secondary click for mouse users.
- **Rendering.** Cap the decode with `ResizeImage(..., width: 4096, height: 4096, policy: ResizeImagePolicy.fit)`, or better, write a downscaled display copy at import. No tiling is needed.
  - A full 3120×4160 decode is about 50 MiB.
  - Impeller clamps decodes to the GPU max texture size **per axis**, which risks a squash on GPUs limited to 4096.
  - On the web, the full image is decoded before it is resized.
- **Storage.** Store `cx`, `cy` as 0..1 of photo width and height, and `r` as a fraction of photo width, with `photoId` on each mark. A later ellipse adds `rx`, `ry` and `rotation`. Fix EXIF orientation at import, and draw strokes and handles divided by the current zoom.

Details, sources and a code sketch: [../research/zoomable-photo-with-mark-overlay.md](../research/zoomable-photo-with-mark-overlay.md)

## Comments

- 2026-11-21 (spraywall-09, from [How does a problem span several wall photos?](09-multi-photo-viewer.md)): when fitting the photo, set the scale on all three axes (`Matrix4.diagonal3Values(f, f, f)`). With z left at 1, `getMaxScaleOnAxis()` reports zoom 1 until the first pinch, so hit radii come out wrong.

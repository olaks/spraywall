# 03: Wall photos

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The user adds wall photos to the current layout from the camera (where supported) or a file, labels and reorders them, opens one full-screen with pan and zoom, and deletes an unused one with undo. Photos come out upright, at most 2560 px, without EXIF/GPS.

**Blocked by:** 01

**Status:** done (2026-11-22)

- [x] Photo import is a pure function: decode (applies orientation), downscale to 2560 px long edge without upscaling, clear all EXIF, JPEG q85, 384 px thumbnail; run in an isolate on Android/Linux
- [x] Unit tests: 4000×3000 → 2560 long edge; small image not upscaled; orientation 6 swaps width/height and leaves no tag; output has no EXIF; thumb is 384 px
- [x] `image_picker` only; camera button shown only when `supportsImageSource(camera)`; Android `retrieveLostData()` handled
- [x] Photos screen: thumbnail grid, add, edit label, drag to reorder, "N problems use this photo"
- [x] Delete photo only when no mark uses it (snapshot + undo, round-trip test); otherwise refused naming the problems
- [x] Full-screen `InteractiveViewer` view; fit-to-screen scales all three axes; regression test that `getMaxScaleOnAxis()` equals the fit factor without pinching
- [x] Web: OPFS via `coi-serviceworker`, `navigator.storage.persist()` called (manual checklist item)

## Comments

- **The decoder already applies orientation.** In `image` 4.13 the JPEG decoder rotates the pixels by the EXIF orientation and clears the tag, so `importPhoto` doesn't call `bakeOrientation`, which would only copy the image. The orientation test pins this down.
- **EXIF clearing is load-bearing.** With the `exif = ExifData()` lines removed, the GPS test fails: resizing carries the EXIF along and encoding writes it back.
- **Photos screen is a list, not a grid.** Flutter has no reorderable grid. A list of large thumbnails reuses the wall list's drag code, and a layout holds only a handful of photos. Revisit with ticket 10 (wide windows) if it looks sparse.
- **Full-screen view has its own route**, `/walls/:wallId/photos/:photoId`. The spec's route table didn't list one; a route keeps back and web reload consistent.
- **`ZoomablePhoto`** (`lib/widgets/`) is ready for the editor and problem view. It ports the prototype's rules: fit on first show; refit on resize unless zoomed in past 1.05× the fit; `minScale` 0.8× the fit; `maxScale` the larger of 4 and 2× the fit (so a small photo can't make minScale exceed maxScale); boundary margin 1500. Its `overlay` is laid out in photo pixels.
- **Android lost data.** The layout id is kept in prefs while the picker is open. On the next start the app adds the recovered photo to that layout, if it still exists, and says so in a snackbar. Added to the manual checklist ("Don't keep activities").
- **Test seams.** `photoSourceProvider` (`FakePhotoSource` in tests) and `photoImporterProvider` (inline in tests, `compute` in the app).
- **`testApp`.** Widget tests now use this wrapper, which runs `teardownTree` pass or fail. Before, a failing test hung the runner for about 2.5 minutes.
- **Checks.** `check.sh` passes (51 tests). The web (WASM) and Linux builds succeed, and the Linux app starts cleanly. The APK build and the camera were not run; they are on the manual checklist.

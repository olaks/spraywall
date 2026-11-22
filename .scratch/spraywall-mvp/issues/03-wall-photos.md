# 03: Wall photos

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The user adds wall photos to the current layout from the camera (where supported) or a file, labels and reorders them, opens one full-screen with pan and zoom, and deletes an unused one with undo. Photos come out upright, at most 2560 px, without EXIF/GPS.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Photo import is a pure function: decode (applies orientation), downscale to 2560 px long edge without upscaling, clear all EXIF, JPEG q85, 384 px thumbnail; run in an isolate on Android/Linux
- [ ] Unit tests: 4000×3000 → 2560 long edge; small image not upscaled; orientation 6 swaps width/height and leaves no tag; output has no EXIF; thumb is 384 px
- [ ] `image_picker` only; camera button shown only when `supportsImageSource(camera)`; Android `retrieveLostData()` handled
- [ ] Photos screen: thumbnail grid, add, edit label, drag to reorder, "N problems use this photo"
- [ ] Delete photo only when no mark uses it (snapshot + undo, round-trip test); otherwise refused naming the problems
- [ ] Full-screen `InteractiveViewer` view; fit-to-screen scales all three axes; regression test that `getMaxScaleOnAxis()` equals the fit factor without pinching
- [ ] Web: OPFS via `coi-serviceworker`, `navigator.storage.persist()` called (manual checklist item)

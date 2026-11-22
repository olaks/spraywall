# What is the test strategy?

Type: grilling
Status: resolved
Claimed by: spraywall-11 2026-11-22T10:22:32+01:00 (taken over from session 46b2507b)
Blocked by: 09, 10
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

What gets **unit tests** and what gets **widget tests** in the MVP, following `training_logger`'s conventions (`CODING_STANDARDS.md`, `backup_test.dart` statement counting, schema tests)?

Cover at least: mark geometry (normalised `cx`/`cy`/`r`, hit-testing under zoom), the marks-first editor (role palette, select/drag/resize, undo), the reset and retire flows, snapshot deletes with undo, and backup import (validation, merge by id, name-clash renaming, layout archiving, off-scale grades). Also: which fixtures (e.g. crops of `sample/`) and which platforms run the tests in `scripts/check.sh`.

## Comments

- 2026-11-21 (spraywall-10, from [Which extras are in the MVP?](10-which-extras-are-in-the-mvp.md)): the stretch goals need a test plan too, but must not block the core one: circle-intersection lookup for the overlap view, and the shared-image render (caption, legend, one image per marked photo).
- 2026-11-21 (spraywall-09, from [How does a problem span several wall photos?](09-multi-photo-viewer.md)): also cover switching photos with the thumbnail strip (the selection clears and each photo keeps its own zoom), the last mark size kept per photo, and the opening-photo rules (the view opens on the first photo with start marks; the editor keeps the viewed photo). Add a regression test that the fit transform scales all three axes (see the comment on [Zoomable photo with tappable circle overlay in Flutter](02-zoomable-photo-with-mark-overlay.md)). Photo import (downscale, orientation, EXIF/GPS cleared) needs tests too, and so does what runs only on web (OPFS, the web SQLite assets) versus on the VM.

## Answer

Resolved by grilling, 2026-11-22 (taken over from session 46b2507b). Glossary: added **Overlapping marks** (crossing or touching circles on the same wall photo). No ADR, because every choice here is cheap to revisit.

1. **Layers.** Unit tests, database tests on `NativeDatabase.memory()`, and widget tests, all run on the VM by `flutter test`. No `integration_test/`. Widget tests follow `training_logger`'s fake-time rules: read drift streams in `tester.runAsync`, and advance 1 ms before teardown.
2. **Where tests run.** `scripts/check.sh` is copied from `training_logger`: `flutter analyze`, then `flutter test` under a timeout. `release.sh` also runs `flutter build web --wasm`. The spec carries a short **manual checklist**:
   - On web, a photo survives a reload, and storage is OPFS, not memory.
   - On Android, taking a photo with the camera works.
   - On Linux, picking a photo from a file works.
   - Mark appearance looks right on the sample photo.
3. **Pure-Dart seams with unit tests** (no Flutter imports, like `training_load.dart`):
   - Mark geometry: normalised `cx`/`cy`/`r` to photo pixels and back, hit-testing at a zoom scale, and resize limits.
   - The opening-photo rule.
   - The last mark size kept per photo.
   - Grade-range and name filters.
   - Name-clash renaming (`(2)`, `(3)`).
   - Picking which current layout to archive on import.
   - Photo import:
     - A 4000×3000 image comes out at 2560 px on the long edge.
     - No upscaling.
     - EXIF orientation 6 swaps width and height and leaves no tag.
     - The output has no EXIF, so no GPS.
     - The thumbnail is 384 px on its long edge.
     - Byte size is not asserted.
4. **Database tests.**
   - Each snapshot delete (problem, archived layout, wall, unused photo) round-trips to identical rows.
   - Foreign keys are enforced.
   - `schema_test.dart` plus a `drift_schemas/` dump from v1.
   - Reset and retire:
     - Retire hides the problem, "Show retired" shows it, and unretire restores it.
     - Reset creates an empty current layout and archives the old one, and its undo restores it.
     - Deleting an archived layout can be undone, and the current layout can't be deleted.
   - Backup:
     1. An export then import round trip gives identical rows and byte-identical photos.
     2. Re-importing the same backup changes nothing.
     3. A missing photo, a dangling id, an unknown version or bad JSON writes nothing and gives a readable error.
     4. On an id clash the device wins.
     5. Name clashes become `(2)`, `(3)`.
     6. With two current layouts, the earlier start date is archived.
     7. Off-scale grades become ungraded and are counted.
     8. Thumbnails are regenerated, not read from the zip.
     9. A statement-count test via a counting `QueryInterceptor` (200 marks cost no more statements than 5).
5. **Zoom in widget tests.**
   - Set the `TransformationController` directly; no simulated pinches.
   - Regression test from ticket 02: after the fit, with no pinch, a tap just inside a mark's edge hits, and `getMaxScaleOnAxis()` equals the fit factor.
6. **Editor widget tests.**
   1. With a role chosen, a tap on empty photo always places a mark, at the last size used on this photo.
   2. A tap selects a mark. Dragging an unselected mark pans the photo.
   3. Dragging the selected mark at zoom 1 and zoom 3 stores `cx`/`cy` that match the drop point, within 0–1.
   4. The resize handle stays within its limits, and the new size carries to the next mark.
   5. Trash, then undo, restores the mark even after leaving the editor, since the undo goes through the captured database.
   6. Switching photos on the thumbnail strip clears the selection and keeps each photo's zoom.
7. **Other widget tests.**
   - The archived wall screen is read-only.
   - The reset snackbar's undo.
   - The import summary dialog's counts.
   - The problem view: opening photo, dimmed photos without marks, no edit controls.
   - The wall list: create, open, delete with undo.
   - The backup reminder, copied from `backup_status_test` with an injected clock.
   - The editor and the problem view at 400 and 800 dp wide: palette, thumbnails and panel in place, and placing a mark still works.
8. **No golden tests**, matching `training_logger`.
9. **Fixtures.** Built in code with `package:image`: small JPEGs, some with EXIF orientation and fake GPS. `sample/` is **never committed** (it carries GPS) and stays a manual reference. A shared `test/helpers/` holds:
   - An in-memory database factory with foreign keys on.
   - Builders such as `seedWall(...)` that write through the app's own database API.
   - The image fixtures.
   - The statement counter.
10. **Stretch goals** are tested only in their own last slices:
    - **Overlap**: a pure function. Same photo, circles intersect or touch, compared in photo pixels, excluding the tapped mark's own problem.
    - **Sharing**: a pure caption function, and a render test. The render test checks one image per photo with marks, at the photo's pixel size, and samples each mark's ring for its role colour.
11. **Slices.** Each slice in `spec.md` lists the tests that close it, as acceptance criteria. A slice is done when they pass under `check.sh`.

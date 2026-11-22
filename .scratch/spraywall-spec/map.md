# Spraywall: problem-setting app spec

Label: wayfinder:map

## Destination

A build-ready MVP **spec** (plus `GLOSSARY.md` and ADRs) for a Flutter app on Android, Linux desktop and Web. With it, one user sets **problems** on a **wall**: each problem is a named set of **marks** with roles, drawn on one or more **wall photos** of the current **layout**. Clear enough to hand off and build in slices.

## Notes

- **Domain**: climbing spray wall. Canonical vocabulary is in `GLOSSARY.md` (Wall, Layout, Wall photo, Problem, Mark, Role, Grade, Reset); use it and keep it current.
- **Skills**: every grilling session calls `grilling` + `domain-modeling`; prototypes call `prototype`; research calls `research`. The final spec is written with `to-spec`.
- **Stack**: same as `../training_logger` (Flutter, Riverpod 3, Drift/SQLite, go_router, Material 3; Android + Linux + Web/WASM on GitHub Pages). Read its `CLAUDE.md` and `CODING_STANDARDS.md` before deciding anything technical; its pinned-dependency notes apply here too.
- **Sample data**: `sample/IMG_20210522_093949634.jpg` is the real wall: 3120×4160 portrait, about 200 holds, many beige wooden holds on beige plywood, tiny footholds on the kicker, GPS in EXIF. Test every interaction idea against it.
- **Standing decisions from charting (2026-11-21)**:
  - Marks are **per problem**: no shared hold catalogue.
  - A layout's several photos are **separate views**; each mark sits on exactly one photo.
  - A mark is a **circle** (an ellipse is a stretch goal) with one of four **roles**: start, hand, foot, finish.
  - A problem has a name, a grade (Font/V), an optional description and the date it was set.
  - A **reset** starts a new layout and archives the old one.
  - Browsing is a list for the current layout with grade-range and name filters.
  - This is a **separate app** that copies code from `training_logger`.
  - Single user, all data on the device. Use nothing that rules out later sync or community features (e.g. prefer stable ids).
- **Plan, don't do**: tickets produce decisions, not app code. Prototypes are throwaway.

## Decisions so far

<!-- one line per closed ticket: [title](issues/NN-slug.md): gist -->

- [What to copy from training_logger](issues/03-what-to-copy-from-training-logger.md): copy the plumbing nearly as-is (grades, theme, undo snackbar, file helpers, web SQLite assets, check/build/release/deploy scripts, pubspec pins); rebuild the domain (Drift DB from schema v1, backup, delete snapshots) following the same patterns; all CODING_STANDARDS rules carry over.

- [Zoomable photo with tappable circle overlay in Flutter](issues/02-zoomable-photo-with-mark-overlay.md): built-in `InteractiveViewer` with a photo-sized `Stack` of per-mark gesture widgets (taps arrive in photo coordinates); only the selected mark is draggable; cap decode at 4096 px long edge (downscaled copy on import for web); marks stored as normalised `cx`/`cy` + `r` relative to photo width.

- [Storing and picking wall photos on Android, Linux and Web](issues/01-photo-storage-across-platforms.md): `image_picker` only (camera where supported, so not Linux); on import, downscale in Dart with `package:image` to 2560 px long edge, JPEG q85 (~0.5 MB), apply orientation and clear EXIF (GPS); store as Drift BLOBs in their own table; web needs OPFS via `coi-serviceworker` or every photo sits in memory.

- [What does a reset do?](issues/04-what-a-reset-does.md): a few moved holds means **retiring** problems one at a time, not a reset; a reset starts a new empty layout (start date + optional name); photos are never replaced or copied over; archived layouts are read-only and deletable with undo; a reset can only be undone straight away; several walls, starting from a wall list.

- [What is the data model?](issues/06-data-model.md): six Drift tables (Walls, Layouts, WallPhotos, WallPhotoBytes with a 384 px thumb, Problems, Marks) with UUIDv7 text ids (ADR 0001); grade as nullable text on a per-wall grade scale, filtered in Dart; problem names unique per layout; dates as `yyyy-MM-dd`; snapshot deletes for problem, archived layout, wall and unused photo; no drafts.

- [How should marking holds feel on a dense wall?](issues/05-mark-editing-interaction.md): variant A, the role palette: pick a role chip, tap empty photo to place (always places), tap a mark to select it; only the selected mark drags; handle to resize; new marks reuse the last size; trash with undo snackbar. [Prototype](prototypes/mark_editing/README.md).

- [What are the MVP screens and navigation?](issues/07-screens-and-navigation.md): no tab bar; wall list as the root; nested routes under `/walls/:wallId`; the wall screen is the problem list (filters, "Show retired", sort toggle) with a menu for Photos/Reset/Past layouts/Edit wall; a read-only problem view separate from a marks-first editor; archived layouts reuse the wall screen read-only; same screens on wide windows, with a side palette and side panel at ≥ 600 dp.
- [How are backups exported and imported?](issues/08-backup-format.md): a `.zip` of `backup.json` + `photos/<id>.jpg` (thumbs regenerated); export everything or one wall; import validates then merges by id in one transaction, device wins, name clashes renamed `(2)`, a second current layout archived by later start date, off-scale grades made ungraded; summary dialog, no undo; backup reminder kept.
- [How does a problem span several wall photos?](issues/09-multi-photo-viewer.md): variant B, a thumbnail strip (under the photo on phones, a left column at ≥ 600 dp), no swipe; the view opens on the first photo with start marks and dims photos without marks; the editor keeps the photo being viewed (a new problem opens on the first photo); a hold on two photos is marked once; the last mark size is kept per photo. [Prototype](prototypes/multi_photo/README.md).
- [Which extras are in the MVP?](issues/10-which-extras-are-in-the-mvp.md): "stretch goal" = last slices, core never depends on them; overlap view ("Show problems" on a full-screen photo, tap a mark to list problems with overlapping marks) and sharing (one captioned JPEG per marked photo via share sheet/save/download) are stretch goals, sharing first; carry-forward is out of scope.
- [What is the test strategy?](issues/11-test-strategy.md): VM-only `flutter test` (pure-Dart unit tests for geometry/filters/renaming/photo import, in-memory DB tests for snapshots, schema v1, reset/retire and backup incl. statement count, widget tests for editor, read-only archive, both widths); zoom set via `TransformationController` + fit regression; fixtures generated with `package:image`, sample never committed (GPS); no goldens; `release.sh` adds a web WASM build, plus a manual checklist; each slice lists its closing tests.

## Not yet specified

Nothing: the destination is reached. The spec is [Spraywall MVP](spec.md) (2026-11-22), sliced into 14 build tickets in [`../spraywall-mvp/issues/`](../spraywall-mvp/issues/) (12 core, 2 stretch), all `ready-for-agent`.

## Out of scope

- **Community features** (accounts, ratings, public problems): possibly a later effort; the data model only avoids ruling it out.
- **Multi-user sync** of a shared home wall: not for this map; the same "don't rule it out" applies.
- **Logging ascents and attempts**: `training_logger` already covers climbing logs.
- **A shared hold catalogue / automatic hold detection**: ruled out by choosing per-problem marks.
- **Stitching photos into a panorama**: photos are separate views.
- **Building this inside `training_logger`**: it's a separate app.
- **A list-detail split on wide windows** (problem list beside the problem view): MVP uses the phone screens on every width; see [What are the MVP screens and navigation?](issues/07-screens-and-navigation.md).
- **Carrying a problem forward after a reset**: re-marking is the real work and archived layouts stay viewable; see [Which extras are in the MVP?](issues/10-which-extras-are-in-the-mvp.md).

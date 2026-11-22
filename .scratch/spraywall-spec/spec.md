# Spraywall MVP

Status: ready-for-agent
Map: [Spraywall: problem-setting app spec](map.md)

Vocabulary follows `GLOSSARY.md` (Wall, Layout, Wall photo, Problem, Mark, Role, Grade, Grade scale, Retired problem, Overlapping marks, Backup, Reset). Ids follow ADR 0001 (UUIDv7 text ids). Each decision below gists a resolved ticket; the ticket holds the detail and the reasoning.

## Problem Statement

I set boulder problems on my home spray wall. The wall has about 200 holds, many of them beige wood on beige plywood, with tiny footholds on the kicker. There is no good way to record which holds make up a problem: describing them in words fails on a wall this dense, generic photo markup apps don't know about start, hand, foot and finish holds, and existing board apps (Kilter, MoonBoard and the like) only work with their own fixed hold sets. When I change the holds, every problem I wrote down goes stale, and I lose track of which problems belong to which arrangement of the wall.

## Solution

A Flutter app for Android, Linux desktop and the web where one user keeps their walls on the device. For each wall the user takes photos of its current layout and sets problems by tapping holds on those photos: each tap draws a circle (a mark) in the colour of its role. A problem has a name, a grade on the wall's grade scale, an optional description and the date it was set. The wall screen lists the current layout's problems with grade and name filters. When a few holds move, the user retires the problems that broke; when the wall is rebuilt, a reset archives the whole layout, with its photos and problems still viewable, and starts a new empty one. Everything can be exported to a backup file and imported back, merging with what is already on the device.

## User Stories

### Walls

1. As a climber, I want a list of my walls as the first screen, so that I can keep my home wall and my gym's spray wall apart.
2. As a first-time user, I want an empty state that says "Create your first wall" and takes me straight into the new wall, so that I'm setting problems within a minute.
3. As a climber, I want to give a wall a name and a grade scale (Font or V), so that its problems are graded the way I think about them.
4. As a climber, I want wall names to be unique ignoring case, so that I never confuse two walls.
5. As a climber, I want to drag walls into my own order, so that the one I use most sits at the top.
6. As a climber, I want to rename a wall, so that I can fix a typo or follow a move.
7. As a climber, I want to change a wall's grade scale only while none of its problems has a grade, and to see why it is locked otherwise, so that grades are never silently reinterpreted.
8. As a climber, I want to delete a wall with an undo, so that a mis-tap doesn't cost me years of problems.

### Wall photos

9. As a climber, I want to take a wall photo with the camera on my phone, so that I can photograph the wall right where I stand.
10. As a Linux or web user, I want to pick a photo from a file, so that I can use photos taken on another device.
11. As a climber, I want photos to come out the right way up, whatever orientation the camera stored, so that marks land where I tap.
12. As a climber, I want my photos stripped of their location data when imported, so that my home's GPS position never ends up in a backup or a shared image.
13. As a climber, I want photos downscaled on import to a size that still shows 2–3 cm footholds, so that the app stays fast and small.
14. As a climber, I want several photos per layout (whole wall, left half, kicker close-up), so that small holds are big enough to tap.
15. As a climber, I want to label and reorder a layout's photos, so that the photo I use most comes first.
16. As a climber, I want to see how many problems use each photo, so that I know what deleting it would affect.
17. As a climber, I want deleting a photo refused while any mark sits on it, naming the problems that use it, so that I can't break problems by accident.
18. As a climber, I want to open a photo full-screen with pan and zoom, so that I can study the wall.
19. As a climber, I want the app to prompt me to add a wall photo while the layout has none, so that I know what to do first.

### Setting problems (the editor)

20. As a setter, I want the editor to open on the photo, marks first, so that I spend my time on holds, not forms.
21. As a setter, I want a role palette (start, hand, foot, finish) where the chosen chip is my brush, so that marking a run of hand holds is one tap each.
22. As a setter, I want a tap on empty photo to always place a mark with the brush role and select it, so that marking never stalls on a deselect tap.
23. As a setter, I want a tap on an existing mark to select it, so that I can fix it.
24. As a setter, I want the palette to show the selected mark's role, and a chip tap to change it, so that I can recolour a mark in one tap.
25. As a setter, I want only the selected mark to be draggable, and a drag anywhere else to pan the photo, so that I don't knock marks around while moving the view.
26. As a setter, I want to pinch, wheel or trackpad zoom into the photo, so that I can place marks on tiny footholds precisely.
27. As a setter, I want a resize handle on the selected mark, so that the circle fits the hold.
28. As a setter, I want new marks to reuse the last size I used on that photo, so that a close-up and a whole-wall photo each get sensible circles.
29. As a setter, I want unselected marks to stay easy to tap (at least 20 screen px), and the selected mark drawn on top, so that dense clusters stay workable.
30. As a setter, I want a trash button for the selected mark with an undo snackbar, so that deleting a mark is quick and safe.
31. As a setter, I want a done button that deselects, so that I can look at the whole problem.
32. As a setter, I want mouse input to work like touch (click to place or select, drag the selected mark, wheel to zoom), so that setting on Linux or the web is just as quick.
33. As a setter, I want to switch between the layout's photos with a thumbnail strip that shows this problem's marks and a count per role, so that I can find and mark holds on any photo.
34. As a setter, I want each photo to keep its own zoom and position while I switch, so that I get back to the spot I was working on.
35. As a setter, I want switching photos to clear the selection, so that I never edit a mark I can't see.
36. As a setter, I want to mark a hold that shows on two photos only once, on the photo that shows it best, so that I don't do the work twice.
37. As a setter, I want a non-blocking hint when the problem has no start or no finish marks, so that I notice the omission without being forced to fix it.
38. As a setter, I want Save to ask for a name (required), grade, description and set date (defaulting to today), so that the details come after the holds.
39. As a setter, I want saving refused until the problem has a name and at least one mark, so that empty problems don't clutter the list.
40. As a setter, I want problem names unique within a layout, ignoring case, so that every problem in the list is unambiguous.
41. As a setter, I want to edit an existing problem's marks and, through "Edit details", its name, grade, description and set date.
42. As a setter, I want leaving the editor with unsaved changes to ask "Discard changes?", so that I don't lose work by pressing back.
43. As a setter, I want a new problem to open on the layout's first photo, and an existing problem to open on the photo I was viewing, so that I don't have to hunt for my place.

### Browsing and viewing problems

44. As a climber, I want the wall screen to list the current layout's problems with name, grade, set date and a thumbnail of the first marked photo, so that I can pick something to climb.
45. As a climber, I want to filter by a grade range and by name, so that I can find problems for today's session.
46. As a climber, I want to sort by grade (easiest first, ungraded last, ties by name) or by newest set date, so that I can see the new problems or work up the grades.
47. As a climber, I want ungraded problems allowed, so that a project can live in the list before I know its grade.
48. As a climber, I want the app bar to show the wall's name and the layout's name or start date, so that I know which layout I'm looking at.
49. As a climber, I want a read-only problem view with pan and zoom, showing the name and grade in the app bar and the description in a collapsible sheet, so that I can read a problem without risking an edit.
50. As a climber, I want the problem view to open on the first photo with a start mark, so that I see where the problem begins.
51. As a climber, I want photos that carry none of this problem's marks dimmed in the strip but still selectable, so that I can see where the problem is and still look at the rest of the wall.
52. As a climber, I want to delete a problem from its view, with an undo snackbar on the list it returns to.

### Retiring and resetting

53. As a setter, I want to retire a problem whose hold I moved, keeping it in the app, so that a small change to the wall doesn't cost me the record.
54. As a climber, I want retired problems hidden from the list unless I turn on "Show retired", and shown greyed with a badge when I do, so that the list shows what's climbable.
55. As a setter, I want to un-retire a problem, so that I can bring it back when I put a hold back.
56. As a setter, I want a retired problem to be read-only apart from Un-retire and Delete, so that its record stays as it was.
57. As a setter, I want a Reset that archives the current layout with its problems and starts an empty new layout, with an optional name and a start date defaulting to today, so that a rebuilt wall starts clean.
58. As a setter, I want an undo snackbar straight after a reset, so that a mistaken reset is recoverable; after that, it's permanent.
59. As a climber, I want a Past layouts list showing each archived layout's dates, name, problem count and photo count, so that I can browse the wall's history.
60. As a climber, I want to open an archived layout read-only, with its photos, problems and marks, so that I can remember old problems.
61. As a climber, I want to delete an archived layout with an undo, so that I can free the space its photos take.
62. As a climber, I want the current layout to have no delete, only Reset or deleting the wall, so that a wall always has a current layout.

### Wide windows

63. As a desktop or tablet user, I want the same screens on a wide window (≥ 600 dp, landscape phones included), with lists capped at a readable width, the photo strip as a left column, the role palette as a right side bar and problem details in a side panel, so that the space is used well.

### Backups

64. As a climber, I want to export everything, or one wall, to a single `.zip` backup, so that a lost phone doesn't lose my problems.
65. As a climber, I want the export handed to the share sheet on Android, a save dialog on Linux and a download on the web.
66. As a climber, I want to import a backup that merges with what is on the device, never removing anything, so that I can move between devices or restore safely.
67. As a climber, I want a broken or too-new backup refused before anything is written, with a clear reason, so that an import never leaves half its data behind.
68. As a climber, I want importing the same backup twice to change nothing the second time.
69. As a climber, I want clashing wall or problem names renamed `Name (2)`, `(3)`, so that nothing is lost and nothing is ambiguous.
70. As a climber, I want an import that brings a second current layout to archive the older one, so that each wall still has one current layout.
71. As a climber, I want grades that aren't on the wall's grade scale imported as ungraded, so that a mismatch doesn't block the import.
72. As a climber, I want progress while importing and a summary afterwards (added, already here, renamed, made ungraded, archived), so that I know what happened.
73. As a climber, I want a backup reminder that nudges me monthly until I do a full export, and stays quiet for a week when dismissed, so that I don't forget.
74. As a web user, I want my photos to survive a reload and the browser asked to keep storage persistent, so that the web version is usable day to day.

### Settings

75. As a climber, I want Settings to hold the theme choice, the backup status, export and import, so that the rarely-used things are in one place.

## Implementation Decisions

### Stack and what is copied

- Same stack as `training_logger`: Flutter, Riverpod 3, Drift/SQLite, go_router, Material 3; targets Android, Linux desktop and web (WASM, GitHub Pages).
- **Copied nearly verbatim**, with a rename pass: the grades utility, the dark Material 3 theme with four accents and its provider, the undo snackbar (its `persist: false` is load-bearing), the share-file helpers (port the web half from `dart:html` to `package:web`), the text-file picker (plus a new binary-file picker beside it), the backup reminder provider and its date helpers, the web SQLite files (drift worker, `sqlite3.wasm`, `coi-serviceworker`), the check/build/release/deploy scripts, the pre-commit hook, the analysis options, and the pubspec pins with their comments (drift below 2.34.1, the `jni` 1.0.0 override, the win32-5 trio).
- **Rebuilt following the same patterns**: the Drift database class (schema v1, foreign keys on in `beforeOpen`), the schema dump and schema test from the first commit, backup, and delete-returns-snapshot undo. All four `CODING_STANDARDS.md` rules carry over; the name-matching rule is adapted to per-layout problem names.

### Data model (schema v1)

Six tables; every id is UUIDv7 text (ADR 0001); dates are `yyyy-MM-dd` text with no time of day; enums are stored as int enums and written by **name** in backups.

| Table | Columns | Notes |
|---|---|---|
| Walls | id, name, gradeScale, createdOn, sortOrder | name unique ignoring case; gradeScale ∈ {font, v}; manual order |
| Layouts | id, wallId, name?, startedOn, endedOn? | endedOn null = current; partial unique index on wallId where endedOn is null, also enforced by the reset transaction |
| WallPhotos | id, layoutId, sortOrder, width, height, addedOn, label? | metadata only, read by every list |
| WallPhotoBytes | photoId, data, thumb | data = 2560 px JPEG q85; thumb = 384 px JPEG; read only by widgets that draw them |
| Problems | id, layoutId, name, grade?, description, setOn, retiredOn? | name unique ignoring case within the layout (retired included); grade is text from the wall's scale, null = ungraded; description non-null, default empty |
| Marks | id, problemId, photoId, role, cx, cy, r | role ∈ {start, hand, foot, finish}, append-only; cx/cy are 0..1 of photo width/height, r a fraction of photo **width**; drawn in insertion order |

- Indexes: the foreign-key columns, plus the current-layout partial unique index. Grade-range and name filters run in Dart, ordering grades by their position in the wall's scale.
- No speculative columns (no setter, updatedOn, problem sort order). A later ellipse adds nullable rx, ry, rotation to Marks.
- A mark's photo must belong to its problem's layout (enforced in code).
- No drafts: the editor keeps its working copy in memory and writes the problem and its marks in one transaction.

### Domain operations (the database module's interface)

- **Create and edit** walls, photos (import pipeline below), problems with their marks (one transaction), and photo labels and order.
- **Retire / un-retire**: set or clear retiredOn.
- **Reset**: in one transaction, set endedOn on the current layout and insert a new current layout (optional name, start date). Undone only from the snackbar straight after.
- **Deletes**, each in one transaction returning a snapshot (ids included) that a matching restore reinserts parents first:
  - problem → its marks;
  - archived layout → its photos, photo bytes, problems and marks;
  - wall → all its layouts and everything under them;
  - photo → only when no mark (any problem, retired included) sits on it; otherwise refused with the names of the problems using it.
- The current layout can't be deleted.
- Undo goes through the database the snapshot was captured from, so it works after the widget that offered it is gone.

### Photo import pipeline

- Pick with `image_picker` only: gallery everywhere; the camera button appears only where `supportsImageSource(camera)` is true (so not on Linux); on Android handle `retrieveLostData()`. Don't use the picker's own resize or quality options.
- In Dart with `package:image` (in an isolate on Android and Linux): decode (which applies the EXIF orientation), downscale to **2560 px on the long edge, never upscaling**, clear all EXIF (`exif = ExifData()`, otherwise GPS is written back), encode JPEG quality 85 (about 0.5 MB), and make a 384 px thumbnail. Store width and height with the photo.
- On the web, keep `coi-serviceworker` so Drift uses OPFS (otherwise the whole database, photos included, lives in memory), and call `navigator.storage.persist()`.

### The zoomable photo with marks

- Built-in `InteractiveViewer` (`constrained: false`, an external `TransformationController`); its child is a box the size of the photo holding the image and one gesture widget per mark, so gesture positions arrive in photo coordinates.
- **Fit-to-screen scales all three axes evenly** (`Matrix4.diagonal3Values(f, f, f)`); with z left at 1, `getMaxScaleOnAxis()` reports zoom 1 and every hit radius is wrong.
- Strokes and handles are drawn divided by the current zoom; unselected marks keep a hit radius of at least 20 screen px; the selected mark paints last.
- Only the selected mark and its handle take pan gestures; while one is pressed, the viewer's panning is turned off. No double-tap handler (it delays every tap); long press is mirrored by secondary click.
- Decode capped at 4096 px per edge as a safety net.
- Role colours, from the prototype: start `#00E676`, hand `#00B0FF`, foot `#D500F9`, finish `#FF1744`.

### The editor (variant A, the role palette)

- A palette of four role chips; the chosen chip is the brush. A tap on empty photo always places a mark with the brush role and selects it. A tap on a mark selects it and shows its role on the palette; a chip tap then changes the mark's role.
- Size: a new mark reuses the last radius used **on that photo** in this editor session; a photo with none starts at about 1.8 % of photo width. The resize handle sits on the selected mark's right edge.
- Trash (with undo snackbar) and Done (deselect) live in the palette bar.
- Save opens a details sheet (name required, grade, description, set date); saving needs a name and at least one mark. A missing start or finish role shows a non-blocking hint. Leaving with unsaved changes asks to discard. The editor never adds photos.

### Several photos (variant B, the thumbnail strip)

- One photo at a time plus a strip of the layout's photos in sortOrder: each thumbnail shows the label, this problem's marks and a count per role, and the current one is highlighted. No swiping. A single-photo layout hides the strip.
- Phones: the strip sits under the photo (about 92 dp), with the palette (editor) or the description sheet (view) below it. ≥ 600 dp: the strip is a left column, the palette or details panel on the right.
- Each photo keeps its own pan and zoom while the screen is open; switching photos deselects.
- Opening photo: the problem view opens on the first photo with a start mark, else the first with any mark. The editor opens on the photo the view was showing, or the layout's first photo for a new problem.
- In the view, photos without this problem's marks are dimmed in the strip but selectable.
- A hold on two photos is marked once; marks are never linked or copied between photos.

### Screens and routes

No tab bar; the wall list is always the root. Nested routes so that the back stack and a web reload follow the hierarchy:

```
/                                         wall list
/settings                                 theme, backup status, export, import
/walls/:wallId                            wall screen (current layout's problem list)
/walls/:wallId/photos                     photos of the current layout
/walls/:wallId/layouts                    past layouts
/walls/:wallId/layouts/:layoutId          archived layout, read-only
/walls/:wallId/problems/new               editor (new problem)
/walls/:wallId/problems/:problemId        problem view
/walls/:wallId/problems/:problemId/edit   editor (existing problem)
```

- An unknown id shows a "not found" page linking home. Filters and sort live in memory, not in the URL.
- **Wall list**: manual order by drag, FAB for a new wall (name + grade scale), Settings in the app bar, first-run empty state.
- **Edit wall**: rename, grade scale (locked while any problem has a grade, with a short explanation), export this wall, delete with undo.
- **Wall screen**: app bar with wall name and layout name or start date; grade-range and name filters, a "Show retired" chip, the sort toggle; rows with name, grade, set date and the first marked photo's thumbnail; FAB "New problem", or "Add a wall photo" while the layout has none; menu with Photos, Reset, Past layouts, Edit wall. With `readOnly` it shows an archived layout: no FAB, edit, retire or reset.
- **Photos**: thumbnail grid, add from camera or gallery, edit label, drag to reorder, "N problems use this photo", refused delete naming the problems, full-screen pan and zoom on tap.
- **Past layouts**: start–end dates, name, problem and photo counts; delete with undo; tap opens the read-only wall screen.
- **Reset**: a dialog ("Start a new layout? The current one will be archived with its N problems") with optional name and start date; then the empty layout with the undo snackbar and the add-photo prompt.
- **Problem view**: menu with Edit, Retire/Un-retire, Delete. Delete pops to the list and shows the undo there. Retired problems offer only Un-retire and Delete; archived-layout problems offer nothing but viewing.
- **Settings**: theme, the backup status card (as in `training_logger`), export everything, import.
- **Wide windows** switch at ≥ 600 dp window width via `LayoutBuilder` on each screen, not per platform. Lists are capped at about 720 px wide; photo screens fill the window. No list-detail split.

### Backup format and import

- A `.zip` (`package:archive`) holding `backup.json` and `photos/<photoId>.jpg` (the 2560 px bytes, stored uncompressed). Thumbnails are not exported; import regenerates them, with progress.
- `backup.json`: top-level `version: 1` and `exportedAt`; null fields omitted; children nested under parents (wall → layouts → photos, problems → marks); enums by name; every row carries its id.
- Export everything (Settings) or one wall (Edit wall), same format. Only a full export resets the backup reminder (monthly nudge, one-week snooze when dismissed).
- Import picks the file as bytes on every platform.
- **Validate first**: valid JSON, a known version (newer is refused with a clear message), every mark's photo present in the zip and in its problem's layout. Then **one transaction**, with all "already here" lookups built before the loop and children inserted in batches. All or nothing.
- **Merge by id, the device wins**: an existing id is left alone, and the problem is the unit (an existing problem's incoming marks are skipped too).
- **Clashes**: a new wall or a new problem whose name clashes (ignoring case; problems within their layout) is renamed `Name (2)`, `(3)`…; new walls append to the list order. Two current layouts on one wall: the later startedOn stays current and the other is ended on that date (a tie keeps the device's current). Grades off the wall's scale import as ungraded.
- A summary dialog afterwards (added walls/layouts/photos/problems, already here, renamed, made ungraded, archived). No undo.

### Stretch goals

Built as the last slices; the MVP ships without them and no core slice depends on them.

- **Sharing a problem** (first in line): Share in the problem view's menu, wherever the view appears. It renders one JPEG per photo that carries the problem's marks, at stored resolution, with the marks drawn on and a caption bar (name · grade · wall name) with a role legend. Output goes to the share sheet, a save dialog, or a download. Images only; nothing to import on the other side.
- **Overlap view**: a "Show problems" toggle on the full-screen photo (from Photos) draws every current, non-retired problem's marks faintly in role colours. Tapping a mark opens a sheet of the problems with **overlapping marks** (same photo, circles crossing or touching), with name and grade; tapping one opens its view. No filters.

## Testing Decisions

- **What a good test is**: it checks behaviour a user or a caller can see (rows written, what is on screen, what a function returns), not how it is done. Logic with many edge cases sits in plain Dart functions with no Flutter, so it is unit-tested in milliseconds, and widget tests only check the wiring. Prior art: the training-load utility and its tests in `training_logger`.
- **Where tests run**: unit, in-memory database and widget tests, all on the VM via `flutter test`; no device or integration tests. The check script runs `flutter analyze` and then the tests under a timeout; the release script also builds the web (WASM) version. Widget tests follow `training_logger`'s fake-time rules: read drift streams inside `runAsync`, and advance the clock 1 ms before teardown.
- **Manual checklist** (in the release notes or script): on the web, a photo survives a reload and storage is OPFS, not memory; on Android, the camera works; on Linux, picking a photo from a file works; marks look right on the sample photo.
- **No golden tests.**
- **Fixtures**: generated in code with `package:image` (small JPEGs, some with an EXIF orientation tag and fake GPS). The sample wall photo is never committed, because it carries GPS. Shared test helpers hold an in-memory database factory with foreign keys on, builders (such as seeding a wall with photos and problems) that write through the app's own database API, the image fixtures, and a statement-counting query interceptor.
- **Unit tests (pure functions)**:
  - mark geometry: normalised ↔ photo pixels (with r relative to width), hit-testing at a zoom scale, resize limits;
  - the opening-photo rule; the last size kept per photo;
  - grade-range and name filters, and the grade sort (ungraded last, ties by name);
  - name-clash renaming; which current layout an import archives;
  - photo import: a 4000×3000 image comes out at 2560 px on the long edge; nothing is upscaled; orientation 6 swaps width and height and leaves no tag; the output has no EXIF; the thumbnail is 384 px. Byte size is not asserted.
- **Database tests** (prior art: `training_logger`'s undo, foreign-key, schema and backup tests):
  - each snapshot delete round-trips to identical rows; foreign keys are enforced; the schema test and a v1 schema dump exist from the first slice;
  - retire hides, "Show retired" shows, un-retire restores; reset archives and creates an empty current layout, and its undo restores; an archived layout deletes and restores; the current layout can't be deleted;
  - backup: export then import into an empty database gives identical rows and byte-identical photos; re-import changes nothing; a missing photo, a dangling id, an unknown version or bad JSON writes nothing and gives a readable error; device wins on id clashes; renames go `(2)`, `(3)`; the earlier current layout is archived; off-scale grades become ungraded and are counted; thumbnails are regenerated; importing 200 marks runs no more statements than importing 5.
- **Widget tests**:
  - zoom is set directly on the transformation controller, never by simulated pinches. Regression: after the fit, without pinching, a tap just inside a mark's edge hits, and the reported zoom equals the fit factor;
  - editor: a tap on empty photo always places a mark at the last size used on that photo; a tap selects; dragging an unselected mark pans; dragging the selected mark at zoom 1 and zoom 3 stores the drop point within 0..1; resizing stays within limits and the size carries to the next mark; trash then undo restores the mark even after leaving the editor; switching photos clears the selection and keeps each photo's zoom;
  - the read-only archived wall screen; the reset undo snackbar; the import summary counts;
  - the problem view (opening photo, dimmed photos, no edit controls); the wall list (create, open, delete with undo); the backup reminder with an injected clock;
  - the editor and the problem view at 400 dp and 800 dp wide: palette, strip and panel are in place, and placing a mark still works.
- **Stretch-goal tests**, in their own slices: overlap is a pure function (same photo, circles crossing or touching, compared in photo pixels, excluding the tapped mark's own problem); sharing has a pure caption function and a render test (one image per marked photo, at the photo's size, each mark's ring sampled for its role colour).
- **Each slice lists the tests that close it**; a slice is done when they pass under the check script.

## Out of Scope

- Community features (accounts, ratings, public problems) and multi-user sync; the model only avoids ruling them out (UUIDv7 ids).
- Logging ascents and attempts (`training_logger` covers it).
- A shared hold catalogue or automatic hold detection; marks are per problem.
- Stitching photos into a panorama; linking or copying marks between photos.
- Carrying a problem forward after a reset.
- A list-detail split on wide windows.
- Ellipse marks (the schema leaves room for them).
- Drafts of unsaved problems; replacing a photo in place.

## Further Notes

- **Slices**: 14 build tickets in `../spraywall-mvp/issues/` (01–12 core, 13–14 stretch), each with its blocking edges and acceptance criteria. The frontier starts at 01.
- Decisions and their reasoning live in the map's tickets (`issues/01`–`11`); research notes in `research/`; the two throwaway prototypes in `prototypes/mark_editing` (variant A) and `prototypes/multi_photo` (variant B) show the editor and the strip working on the sample wall.
- The real wall photo in `sample/` is the reference for every manual check: 3120×4160 portrait, about 200 holds, beige on beige, tiny kicker footholds.
- The app is a separate repository from `training_logger`; this folder is not under git yet, so the first slice also starts the repository.

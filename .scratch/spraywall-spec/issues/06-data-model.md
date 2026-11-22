# What is the data model?

Type: grilling
Status: resolved
Claimed by: spraywall-5f 2026-11-21T13:29:32+01:00
Blocked by: 01, 04
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

What Drift tables, columns and relationships hold **Wall**, **Layout**, **Wall photo**, **Problem** and **Mark**, given the photo-storage and reset decisions?

Settle: how mark geometry is stored (normalised to its photo); how a mark points at its photo and problem; how roles and grades are encoded; ids (auto-increment vs. UUID, so later sync stays possible); what's archived vs. deleted, and the delete/undo snapshots (`training_logger`'s `CODING_STANDARDS.md`); and which indexes are needed for the list filters (grade range, name). Record an ADR where the three ADR conditions hold.

## Answer

Resolved by grilling, 2026-11-21. ADR: [docs/adr/0001-uuid-v7-ids.md](../../../docs/adr/0001-uuid-v7-ids.md). Glossary: added **Grade scale**; **Grade** may be ungraded; **Problem** names are unique per layout.

### Tables

| Table | Columns | Notes |
|---|---|---|
| `Walls` | `id`, `name`, `gradeScale`, `createdOn`, `sortOrder` | name required, unique ignoring case; `gradeScale` intEnum {font, v}; manual list order |
| `Layouts` | `id`, `wallId`→Walls, `name?`, `startedOn`, `endedOn?` | `endedOn` null = current; partial unique index `(wallId) WHERE endedOn IS NULL`, and the reset transaction enforces it too |
| `WallPhotos` | `id`, `layoutId`→Layouts, `sortOrder`, `width`, `height`, `addedOn`, `label?` | metadata only, read by every list |
| `WallPhotoBytes` | `photoId`→WallPhotos, `data`, `thumb` | `data` 2560 px JPEG q85, `thumb` 384 px JPEG; read only by widgets that draw them |
| `Problems` | `id`, `layoutId`→Layouts, `name`, `grade?`, `description`, `setOn`, `retiredOn?` | name required, unique ignoring case within the layout (retired included), may repeat across layouts; `grade` text from the wall's scale, null = ungraded; `description` non-null default `''`; `setOn` defaults to today, editable |
| `Marks` | `id`, `problemId`→Problems, `photoId`→WallPhotos, `role`, `cx`, `cy`, `r` | `role` intEnum {start, hand, foot, finish}, append-only; `cx`/`cy` 0..1 of photo width/height, `r` fraction of photo width; a later ellipse adds nullable `rx`, `ry`, `rotation`; marks draw in insertion order |

- **Ids:** UUIDv7 text on every table (ADR 0001).
- **Dates:** `"yyyy-MM-dd"` text; no times of day.
- **Indexes:** foreign-key columns only (`layouts.wallId`, `wallPhotos.layoutId`, `problems.layoutId`, `marks.problemId`, `marks.photoId`) plus the current-layout partial unique index. Grade-range and name filters run in Dart, ordering grades by position in the wall's scale.
- **Enums in backups:** written by name, not index.
- **No speculative columns:** no `setter`, `updatedOn` or problem `sortOrder`; UUIDs keep sync possible, and migrations can add columns later.

### Rules

- **Saving a problem** needs a name and at least one mark. Missing start or finish marks show a non-blocking hint in the editor; the model doesn't enforce roles.
- **The photo of a mark belongs to the problem's layout**, enforced in code.
- **No drafts:** the editor keeps its working copy in memory and writes the problem plus its marks in one transaction. A later `shared_preferences` draft could be added without touching the schema. Adding a photo from inside the editor must save first or not be offered (the screens ticket decides).
- **Retire / un-retire:** set or clear `retiredOn`.
- **Deletes**, each in one transaction returning a snapshot (ids included) for snackbar undo, per `CODING_STANDARDS.md`:
  - delete **problem** (current, retired or archived-layout problem) → its marks
  - delete **archived layout** → its photos, photo bytes, problems, marks
  - delete **wall** → all its layouts and everything under them
  - delete **photo** → only when no mark (any problem, retired included) sits on it; otherwise refused, naming the problems that use it
- **The current layout can't be deleted**, only reset (issue 04) or removed with its wall.

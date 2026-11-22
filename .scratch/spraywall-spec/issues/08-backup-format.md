# How are backups exported and imported?

Type: grilling
Status: resolved
Claimed by: spraywall-08 2026-11-21T13:35:28+01:00
Blocked by: 01, 03, 06
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

What does a full backup look like, given that it must carry large wall photos as well as rows, and how is it imported?

Options to weigh: JSON with base64 photos, a zip of JSON plus image files, or a separate photo export. Also settle: how import handles duplicates (`training_logger` matches names case-insensitively), whether a single wall or layout can be exported on its own, and how all this works on the web (download/upload, no file system).

## Answer

Resolved by grilling, 2026-11-21 (spraywall-08). Glossary: added **Backup**.

### Format

- A **`.zip`** holding `backup.json` (all rows) and `photos/<photoId>.jpg` (the 2560 px JPEG bytes, stored uncompressed). Uses `package:archive`, already pulled in by `package:image`.
- `backup.json` follows `training_logger`'s shape: top-level `version: 1` + `exportedAt`, optional fields omitted when null, children nested under parents (wall → layouts → photos, problems → marks), enums by name, every row carrying its UUIDv7 id.
- **Thumbnails are not exported**; import regenerates the 384 px thumb from each photo (show progress; slowest on web).

### Scope

- Export **everything** or **one wall** (all its layouts). Same format; import doesn't care which.
- Only a full export resets the **backup reminder** (`backup_provider.dart`, carried over). Where the reminder shows is for [What are the MVP screens and navigation?](07-screens-and-navigation.md).

### Platforms

- Export: `share_file*` (share sheet on Android, save on Linux, download on web); port `share_file_web.dart` from `dart:html` to `package:web` while copying.
- Import: `file_picker` with `withData: true` → bytes on every platform; add `pickBinaryFile` beside `pick_text_file`. The zip lives in memory on web.

### Import

- **Validate first, then one transaction.** Unzip and check everything before writing: valid JSON, known `version` (newer → refused with a clear message), every mark's photo present in the zip and in its problem's layout. Then insert in one transaction with lookups built before the loop and `batch` inserts (`CODING_STANDARDS.md`). All or nothing.
- **Merge by id; the device wins.** A row whose id already exists is left alone. The problem is the unit: an existing problem's incoming marks are skipped too.
- **Clashes:**
  - new wall whose name matches one on the device (ignoring case) → renamed `Name (2)`, `(3)`…; new walls append to the list order
  - new problem whose name clashes in its layout → renamed the same way
  - two current layouts on one wall → the later `startedOn` stays current, the other gets `endedOn` = that date (tie: the device's stays current). The only change import makes to an existing row; same effect as a reset
  - grade not on the wall's grade scale → imported ungraded
- **Afterwards:** a summary dialog (added walls/layouts/photos/problems, already here, renamed, made ungraded, archived). **No undo.**

## Comments

- 2026-11-21 (spraywall-5f, from [What is the data model?](06-data-model.md)): rows now have UUIDv7 ids ([ADR 0001](../../../docs/adr/0001-uuid-v7-ids.md)), so import can match by id instead of `training_logger`'s case-insensitive names. What's still open is what to do when an id already exists (skip, overwrite, newer wins) and when a *different* id clashes with a per-layout problem name or a wall name. Photo bytes live in `WallPhotoBytes` (`data` + `thumb`); the thumb could be regenerated on import instead of exported. Enums are written by name.
- 2026-11-21 (spraywall-07, from [What are the MVP screens and navigation?](07-screens-and-navigation.md)): backup export/import lives on the `/settings` screen (no other entry point is planned). If a per-wall export is chosen, the obvious place for it is the Edit wall screen.

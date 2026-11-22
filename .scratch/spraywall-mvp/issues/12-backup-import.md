# 12: Backup import

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The user imports a backup from Settings. It is validated in full first, then merged in one transaction, and a summary says what happened.

**Blocked by:** 11

**Status:** done (2026-11-22)

- [x] Bytes picked on every platform (`pickBinaryFile`)
- [x] Validation before any write: valid JSON, known version (newer refused clearly), every mark's photo in the zip and in its problem's layout; failures write nothing and give a readable error (tests for missing photo, dangling id, unknown version, bad JSON)
- [x] Merge by id, device wins, problem is the unit; renames `(2)`, `(3)` for walls and problems (pure renaming function with unit tests); second current layout: later startedOn stays current (tie: device's); off-scale grades → ungraded
- [x] Thumbnails regenerated with progress
- [x] Tests: export → import into empty DB gives identical rows and byte-identical photos; re-import changes nothing; 200 marks cost no more statements than 5
- [x] Summary dialog (added, already here, renamed, made ungraded, archived) with a widget test; no undo

## Comments

- Three steps, so a refused backup writes nothing: `parseBackup(bytes)` (pure, in an isolate via `backupParserProvider`) unzips and checks everything and returns the same `BackupRows` the export reads; thumbnails are made for the photos not yet here (`newPhotoIds`, then `makeThumb` per photo via `thumbMakerProvider`, with "Making thumbnails (3 of 12)" and a determinate bar); then `db.importBackup(rows, thumbs)` merges in one transaction.
- Checks (`BackupError`, one readable sentence): not a zip / no backup.json; bad JSON; a newer version ("made by a newer version of Spraywall (format 2). Update the app…"), a missing or non-positive one; any field missing or of the wrong kind (named, e.g. "problems[0] has a name of the wrong kind"); unknown enum names; an id twice; two current layouts on one wall; a photo's JPEG missing from the zip; a mark on a photo not in its problem's layout (covers dangling ids). A photo that can't be decoded fails at the thumbnail step, still before any write.
- `importBackup`: eight lookups up front, one batch of writes (tested: 200 marks cost the same statements as 5). Device wins by id; an existing problem's marks are skipped. Renames reuse `freeName` (already unit-tested in `edit_wall_test.dart`) for walls and for problems within their layout, counting names added earlier in the same import. New walls keep their relative order after the device's; photos added to a layout that's here go after its own; into an empty app, sort orders stay as exported, so the round trip is identical. A second current layout: the later `startedOn` stays current, the other is ended on that date (a tie keeps the device's), the device's update going first in the batch so the one-current index holds at every statement. Grades are checked against the device's scale for a wall that's here.
- An id that's here under a different parent (a layout on another wall, a photo or problem in another layout, a mark on another problem) is not the same row: `BackupClash`, and the transaction rolls back.
- Settings: Import backup (always enabled) → picker (`pickBinaryFile`, bytes everywhere, behind `pickBinaryFileProvider`) → an undismissable progress dialog → "Backup imported" with the summary lines (`importSummaryLines`, pure), or "Import failed" with the reason and "Nothing was changed." No undo.
- Tests: `test/backup_import_test.dart` (17: round trip identical incl. drawing order and regenerated 384 px thumbnails; re-import changes nothing; statement count; every check; clash rollback; device wins; wall renames and order; a new problem renamed and its photo appended in a layout that's here; both current-layout outcomes and the tie; off-scale grade; summary wording) and `test/import_test.dart` (4 widget tests: summary, progress while thumbnails are made, a readable error with nothing changed, backing out).
- Planted bugs, all caught (18): a newer version accepted; a missing photo, a mark's layout, duplicate ids, two current layouts each unchecked; an existing problem replaced or its marks merged; walls or problems not renamed; walls or photos not appended; the earlier layout winning; a tie going to the backup; an off-scale grade kept; marks inserted one by one; the photo stored as its own thumbnail (first missed: the 40×30 fixture is already thumbnail-sized, so the round trip now seeds a 1000×750 photo and checks the thumb is 384×288); a failure titled "Backup imported"; a clash skipped instead of rolled back.
- Not tried by hand yet: picking a real file on Linux, Android and the web (on `release.sh`'s list now).

# 11: Backup export and reminder

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The user exports everything from Settings, or one wall from Edit wall, as a `.zip`, handed to the share sheet, a save dialog or a download. A backup status card nudges monthly until a full export.

**Blocked by:** 04

**Status:** done (2026-11-22)

- [x] Zip with `backup.json` (version 1, exportedAt, nested wall → layouts → photos, problems → marks, enums by name, ids on every row, null fields omitted) and `photos/<photoId>.jpg` stored uncompressed; no thumbnails
- [x] Export everything (Settings) and one wall (Edit wall), same format
- [x] Share helpers ported to `package:web` on web
- [x] Backup reminder card on Settings (monthly nudge, one-week snooze); only a full export resets it; widget test with an injected clock

## Comments

- `lib/backup/backup_export.dart`: `exportBackup(db, {wallId, now})` zips `backup.json` and `photos/<photoId>.jpg` (`ArchiveFile.noCompress`); `backupJson(rows, exportedAt)` is the pure part; `backupFileName` gives `spraywall-2026-11-22.zip` or `spraywall-Home_wall-2026-11-22.zip` (Unicode letters kept, anything else becomes `_`). `archive` is now a direct dependency (it was already in the lock via `image`).
- `backup.json`: `version: 1`, `exportedAt` (UTC ISO 8601), `walls` in list order → `layouts` by start date → `photos` (sortOrder) and `problems` → `marks` in drawing order. Every column is written, ids included, so ticket 12 can round-trip to identical rows; null fields are left out (an empty description is kept: it isn't null). Retired problems and archived layouts are included.
- `AppDatabase.backupRows({wallId})` reads it all in one transaction, six statements however much there is (tested against 5 vs 200 marks), and reads only the full-size photo bytes, never the thumbnails.
- `shareFile` (behind `shareFileProvider`, faked in widget tests): Android/iOS share sheet via `share_plus`; desktop `FilePicker.saveFile(bytes:)`, which writes the file; web a `package:web` Blob download (no more `dart:html`). It returns false when the user backs out, and then the reminder is not reset.
- Reminder: `clockProvider` is the injectable clock. The nudge sits on the wall list (the screen opened every time; Settings alone would be seen too rarely to nudge), with Back up (→ Settings) and Remind me later (a week's snooze). Settings leads with the BACKUP section: the status card and Export everything (disabled with no walls). Only that full export resets the reminder; Export this wall (in the Edit wall dialog) doesn't.
- The nudge reads the clock when the wall list builds, so a wall list left open for days only shows it after a rebuild (any navigation back to it, or reopening the app). Tests model days passing as reopening the app (`pumpApp(keepPrefs: true)`): `/settings` is nested under `/`, so the wall list stays mounted beneath it.
- Tests: `test/backup_export_test.dart` (9: json shape, nesting, nulls, enums, drawing order, photos byte-identical and uncompressed with no thumbnails, one wall, statement count, file names, reminder rules and wording), `test/backup_test.dart` (5 widget tests with the injected clock: the nudge and its week's snooze, Export everything resetting it for 30 days, backing out, Export this wall not resetting it, no walls).
- Planted bugs, all caught: photos compressed; nulls written; roles and grade scale by index; marks out of drawing order; the one-wall filter ignored; thumbnails exported for photos; marks read one problem at a time; a one-wall export resetting the reminder; backing out counted as a backup; the snooze ignored; a 31-day month; Export everything enabled with no walls; the nudge reading the real clock.
- Not checked by hand yet: the Linux save dialog, the Android share sheet and the web download (on `release.sh`'s manual list territory).

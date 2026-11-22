# 11: Backup export and reminder

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The user exports everything from Settings, or one wall from Edit wall, as a `.zip`, handed to the share sheet, a save dialog or a download. A backup status card nudges monthly until a full export.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] Zip with `backup.json` (version 1, exportedAt, nested wall → layouts → photos, problems → marks, enums by name, ids on every row, null fields omitted) and `photos/<photoId>.jpg` stored uncompressed; no thumbnails
- [ ] Export everything (Settings) and one wall (Edit wall), same format
- [ ] Share helpers ported to `package:web` on web
- [ ] Backup reminder card on Settings (monthly nudge, one-week snooze); only a full export resets it; widget test with an injected clock

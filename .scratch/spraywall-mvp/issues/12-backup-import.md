# 12: Backup import

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The user imports a backup from Settings. It is validated in full first, then merged in one transaction, and a summary says what happened.

**Blocked by:** 11

**Status:** ready-for-agent

- [ ] Bytes picked on every platform (`pickBinaryFile`)
- [ ] Validation before any write: valid JSON, known version (newer refused clearly), every mark's photo in the zip and in its problem's layout; failures write nothing and give a readable error (tests for missing photo, dangling id, unknown version, bad JSON)
- [ ] Merge by id, device wins, problem is the unit; renames `(2)`, `(3)` for walls and problems (pure renaming function with unit tests); second current layout: later startedOn stays current (tie: device's); off-scale grades → ungraded
- [ ] Thumbnails regenerated with progress
- [ ] Tests: export → import into empty DB gives identical rows and byte-identical photos; re-import changes nothing; 200 marks cost no more statements than 5
- [ ] Summary dialog (added, already here, renamed, made ungraded, archived) with a widget test; no undo

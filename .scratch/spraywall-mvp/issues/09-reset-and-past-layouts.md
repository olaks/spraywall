# 09: Reset and past layouts

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** When the wall is rebuilt, Reset archives the current layout and starts an empty one, undoable from the snackbar. Past layouts can be browsed read-only and deleted with undo.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] Reset dialog ("Start a new layout? The current one will be archived with its N problems", optional name, start date default today); one transaction ends the current layout and inserts the new one
- [ ] Undo snackbar straight after restores the old layout as current; afterwards it is permanent
- [ ] Past layouts list: start–end dates, name, problem and photo counts
- [ ] Archived layout opens in the wall screen with `readOnly` (no FAB, edit, retire, reset); its problems open view-only
- [ ] Delete archived layout returns a snapshot (photos, bytes, problems, marks); round-trip test; the current layout can't be deleted
- [ ] Widget tests: the read-only archived wall screen; the reset undo snackbar

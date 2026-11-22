# 02: Edit wall

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** From the wall screen's menu the user can rename a wall, change its grade scale while no problem has a grade, and delete it with undo. Walls can be dragged into order on the wall list.

**Blocked by:** 01

**Status:** done (2026-11-22), commit d2174a7

- [x] Rename keeps names unique ignoring case
- [x] Grade scale editable only while none of the wall's problems (any layout) has a grade; otherwise locked with a short explanation
- [x] Drag to reorder walls; order persists
- [x] Delete wall returns a snapshot of the wall and everything under it; undo restores identical rows (round-trip DB test)
- [x] Widget test: wall list delete with undo

## Comments

- Edit wall is a dialog from the wall screen's menu (the only menu item so far; Photos, Reset and Past layouts join it in later tickets). "Export this wall" belongs in it with ticket 11.
- Delete has no confirm, only the undo. The wall screen navigates to `/` before deleting, so it never flashes "Not found"; the undo snackbar lands on the list.
- `restoreWall` renames to `Name (2)` if a wall took the name during the undo window. The helper `freeName` is ready for ticket 12's import clashes.
- `test/edit_wall_test.dart` inserts layouts, photos, problems and marks directly, since their APIs arrive in tickets 03/04; swap in the real calls then.
- Reorder writes after the drop; the list follows the stream. If a one-frame snap-back is visible on a device, hold the dropped order locally until the stream catches up.

# 02: Edit wall

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** From the wall screen's menu the user can rename a wall, change its grade scale while no problem has a grade, and delete it with undo. Walls can be dragged into order on the wall list.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Rename keeps names unique ignoring case
- [ ] Grade scale editable only while none of the wall's problems (any layout) has a grade; otherwise locked with a short explanation
- [ ] Drag to reorder walls; order persists
- [ ] Delete wall returns a snapshot of the wall and everything under it; undo restores identical rows (round-trip DB test)
- [ ] Widget test: wall list delete with undo


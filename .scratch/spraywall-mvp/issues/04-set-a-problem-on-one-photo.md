# 04: Set a problem on one photo

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** From the wall screen the user opens the editor for a new problem, marks holds on the layout's first photo with the role palette, then saves it with a name, grade, description and set date. The problem appears in a plain list on the wall screen.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Editor per variant A: role chips as brush; tap on empty photo always places a mark (brush role, last size on this photo, default ~1.8 % of width) and selects it; tap a mark selects it and shows its role; chip tap changes the selected mark's role
- [ ] Only the selected mark and its resize handle take pan gestures; drags elsewhere pan; strokes/handles scaled by 1/zoom; hit radius ≥ 20 screen px; selected mark paints last; mouse works like touch
- [ ] Trash with undo snackbar; Done deselects; non-blocking hint when start or finish is missing
- [ ] Pure-function unit tests: normalised ↔ photo pixels (r relative to width), hit-testing at a zoom scale, resize limits
- [ ] Save opens the details sheet (name required and unique in the layout ignoring case, grade from the wall's scale or ungraded, description, set date defaulting to today); needs ≥ 1 mark; problem + marks written in one transaction
- [ ] Wall screen lists the layout's problems (name, grade); FAB is New problem, or Add a wall photo while the layout has none
- [ ] Widget tests (zoom set via the controller): always places; tap selects; unselected drag pans; selected drag at zoom 1 and 3 stores the drop point within 0..1; resize within limits and size carries to the next mark; trash + undo restores even after leaving the editor

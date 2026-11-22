# 04: Set a problem on one photo

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** From the wall screen the user opens the editor for a new problem, marks holds on the layout's first photo with the role palette, then saves it with a name, grade, description and set date. The problem appears in a plain list on the wall screen.

**Blocked by:** 03

**Status:** done (2026-11-22)

- [x] Editor per variant A: role chips as brush; tap on empty photo always places a mark (brush role, last size on this photo, default ~1.8 % of width) and selects it; tap a mark selects it and shows its role; chip tap changes the selected mark's role
- [x] Only the selected mark and its resize handle take pan gestures; drags elsewhere pan; strokes/handles scaled by 1/zoom; hit radius ≥ 20 screen px; selected mark paints last; mouse works like touch
- [x] Trash with undo snackbar; Done deselects; non-blocking hint when start or finish is missing
- [x] Pure-function unit tests: normalised ↔ photo pixels (r relative to width), hit-testing at a zoom scale, resize limits
- [x] Save opens the details sheet (name required and unique in the layout ignoring case, grade from the wall's scale or ungraded, description, set date defaulting to today); needs ≥ 1 mark; problem + marks written in one transaction
- [x] Wall screen lists the layout's problems (name, grade); FAB is New problem, or Add a wall photo while the layout has none
- [x] Widget tests (zoom set via the controller): always places; tap selects; unselected drag pans; selected drag at zoom 1 and 3 stores the drop point within 0..1; resize within limits and size carries to the next mark; trash + undo restores even after leaving the editor

## Comments

- **Trash undo after leaving.** The spec's "trash then undo restores the mark even after leaving the editor, through the captured database" conflicts with "no drafts". Resolved as follows:
  - editor open: undo puts the mark back in the working copy;
  - closed by Save: `db.addMark` appends it to the saved problem, if the problem and photo are still there and in one layout;
  - closed by Discard: there's nothing to restore, so undo does nothing.
  Tested both in the editor and after save.
- **Pan-off while held** (`onHold` → `panEnabled: false`) is kept as the spec asks, but no test can tell it's there. With it removed, every test still passes, because the mark's drag recogniser wins the gesture arena on its own. It's a backstop for real-device cases (a second finger mid-drag); check it on Android.
- **`DragStartBehavior.down`** on the mark and handle makes a mark land exactly under the finger. With `.start`, the zoom 1/3 drop tests and the resize test fail by the slop.
- **Pan trails the finger.** `InteractiveViewer` pans from where the gesture passed the touch slop, so a drag across an unselected mark trails the finger by about 24 px. That's built-in, and the test allows for it.
- **Mark order.** Marks have no order column, so `marksOf` orders by `rowid` (insertion order), as the spec's "drawn in insertion order" needs; UUIDv7 ids aren't strictly monotonic within a millisecond.
- **Reusable pieces.**
  - `MarkLayer` (`lib/marks/`) draws read-only without callbacks, ready for ticket 05's problem view.
  - `MarkEditorController` already keys the last size per photo, ready for ticket 06's photo strip.
- **Tests now use the real APIs.** `seedProblem` goes through `createProblem`, and the earlier tests use it in place of direct inserts. `schema_test` and `foreign_keys_test` still insert directly, on purpose.
- **What happens after Save.** The editor returns to the wall screen. Ticket 05 will open the new problem's view instead.
- **Checks.** `check.sh` passes (83 tests). The web (WASM) and Linux builds succeed, and the Linux app starts cleanly. Marking on a device and on the real sample photo is still on the manual checklist.

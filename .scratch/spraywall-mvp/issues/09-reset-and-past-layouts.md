# 09: Reset and past layouts

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** When the wall is rebuilt, Reset archives the current layout and starts an empty one, undoable from the snackbar. Past layouts can be browsed read-only and deleted with undo.

**Blocked by:** 05

**Status:** done (2026-11-22)

- [x] Reset dialog ("Start a new layout? The current one will be archived with its N problems", optional name, start date default today); one transaction ends the current layout and inserts the new one
- [x] Undo snackbar straight after restores the old layout as current; afterwards it is permanent
- [x] Past layouts list: start–end dates, name, problem and photo counts
- [x] Archived layout opens in the wall screen with `readOnly` (no FAB, edit, retire, reset); its problems open view-only
- [x] Delete archived layout returns a snapshot (photos, bytes, problems, marks); round-trip test; the current layout can't be deleted
- [x] Widget tests: the read-only archived wall screen; the reset undo snackbar

## Comments

- **Reset** (`resetLayout`): ends the current layout on the new one's start date and inserts the new one, in one transaction, old one first so the one-current-layout index never sees two. The start date can't be before the current layout started (the date picker's first date; the database refuses too). A blank name is no name.
- **Undo** (`undoReset`) only works while the new layout has no photos: undo never deletes work. In the 6 s the snackbar shows that only happens if the user adds a photo straight away; then the undo says "Can't undo: the new layout has photos". With no photos there can be no problems either.
- **Read-only wall screen:** `WallScreen(layoutId:)`, at `/walls/:wallId/layouts/:layoutId`. No FAB and no wall menu (Photos, Reset, Past layouts and Edit wall are all about the current layout). The subtitle says "Archived, start – end" or "Name, start – end". A URL naming the current layout, or another wall's, is Not found.
- **Archived problems** open at `/walls/:wallId/layouts/:layoutId/problems/:problemId`, under their layout so Back returns there (the spec's route table doesn't list this one; it follows "the back stack follows the hierarchy"). The view hides its whole menu for any problem on an archived layout, whatever the route, and the editor shows Not found for one. Ticket 08 should keep Retire out of that menu too.
- **Filters** are now kept per layout, not per wall, so an archived layout's list has its own.
- **Delete** shares `_takeLayouts` with `deleteWall`. Both snapshots now read marks in drawing order (rowid), so a restore keeps overlapping marks drawn as before; `deleteWall`'s used to be unordered.
- **Past layouts** delete straight away with an undo, like every other delete; no confirmation dialog.
- **Tests:** `test/layouts_test.dart` (8 database tests) and `test/reset_test.dart` (5 widget tests). Tests that reset through the UI use the new `settleDb` helper (see CLAUDE.md). Planted-bug checks: undo deleting a layout with photos, reset before the current start, the current layout deletable, a FAB or a problem menu on archived screens, the editor opening an archived problem, archived problems routed under the wall, and undo leaving the old layout archived each fail their tests.


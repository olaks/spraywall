# 05: Problem view, edit and delete

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** Tapping a problem in the list opens a read-only view with pan and zoom, name and grade in the app bar and the description in a collapsible sheet. From its menu the user edits the problem (marks and details) or deletes it with undo shown on the list.

**Blocked by:** 04

**Status:** done (2026-11-22)

- [x] Problem view route; read-only photo with marks; description sheet hidden when empty
- [x] Edit opens the editor on the problem; "Edit details" in the app bar; leaving with unsaved changes asks "Discard changes?"
- [x] Delete problem returns a snapshot (problem + marks); round-trip DB test; delete pops to the list and shows the undo there
- [x] Widget test: the view has no edit controls on the photo

## Comments

- **Routes.**
  - `/walls/:wallId/problems/:problemId` is the view, and `…/edit` the editor on an existing problem.
  - A problem whose layout belongs to another wall shows Not found.
- **Saving.** New and edited problems both land on the problem's view, and back from there goes to the wall's list. Discarding an edit returns to the view.
- **Edit details.** For an existing problem, the sheet only collects the details and checks the name (`problemNameTaken`, ignoring the problem's own id). Save then writes details and marks together with `updateProblem`, one transaction. A new problem keeps ticket 04's flow, where Save opens the sheet and it creates the problem. The sheet now takes `initial`, `actionLabel` and a `submit` callback.
- **`updateProblem`** replaces the marks wholesale but keeps their ids, so a mark that survives an edit keeps its identity, which matters for backups.
- **`restoreProblem`** puts the marks back in drawing order, and renames to `Name (2)` if the name was taken during the undo window.
- **Opening photo.** `openingPhoto` (`lib/marks/`) is unit-tested and used by both the view and the editor. Ticket 06 replaces the editor's choice with "the photo the view was showing".
- **Description sheet.** It shows the set date in its header and starts open; tapping the header folds it. A long description scrolls within 30% of the screen height. With no description there's no sheet, so the set date doesn't show either; ticket 07's list rows carry the date.
- **Checks.** `check.sh` passes (98 tests), and the web (WASM) and Linux builds succeed.

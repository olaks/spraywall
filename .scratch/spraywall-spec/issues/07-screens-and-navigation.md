# What are the MVP screens and navigation?

Type: grilling
Status: resolved
Claimed by: spraywall-07 2026-11-21T13:36:18+01:00
Blocked by: 04, 05
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

Which screens and go_router routes does the MVP have, and how does a user move between them?

Expected candidates: the wall list (the start screen; several walls), the current layout (its photos and problem list with grade-range and name filters), problem view, the problem editor (marks + name/grade/description), adding wall photos (photos are never replaced), the reset flow (with its snackbar undo), retiring a problem, and browsing and deleting archived layouts and retired problems (read-only). Settle what's on each screen, the routes (URL-based, which matters on the web), and how it all works on a phone vs. a wide desktop window.

## Answer

Resolved by grilling, 2026-11-21. No glossary changes: "Past layouts" is only the menu label; the domain term is still **archived layout**. No ADR, because screens and routes are cheap to change.

### Shell and routes

No tab bar: plain stack navigation with the **wall list** as the root, always shown, even when there's only one wall. Nested `GoRoute`s, so the back stack (and a web reload) follows the hierarchy. Ids are UUIDv7 strings.

```
/                                         wall list
/settings                                 theme, backup (format: issue 08)
/walls/:wallId                            current layout (problem list)
/walls/:wallId/photos                     photos of the current layout
/walls/:wallId/layouts                    past (archived) layouts
/walls/:wallId/layouts/:layoutId          archived layout, read-only
/walls/:wallId/problems/new               editor (new problem)
/walls/:wallId/problems/:problemId        problem view
/walls/:wallId/problems/:problemId/edit   editor (existing problem)
```

- A problem in an archived layout uses the same problem route; the view looks up its layout and goes read-only.
- Filters and sort live in memory, not in the URL.
- An unknown id shows a "not found" page linking to `/`.

### Screens

- **Wall list** (`/`): walls in manual order (drag to reorder), a FAB for a new wall (name + grade scale), and Settings in the app bar. **First run**: the empty state says "Create your first wall"; after creating one the app goes straight into it.
- **Edit wall**: rename, change the grade scale, delete (snapshot + undo). The **grade scale** can be changed only while none of the wall's problems, in any layout, have a grade; otherwise it's locked with a short explanation.
- **Wall screen** (`/walls/:wallId`): the app bar shows the wall name, with the layout's name or start date below it. The body is the current layout's **problem list**:
  - Grade-range and name filters, a "Show retired" chip (retired problems are greyed with a badge), and a sort toggle: grade with the easiest first (the default; ungraded last; ties by name) or newest set date.
  - Each row shows name, grade, set date and a thumbnail of the first marked photo.
  - The FAB is "New problem", or "Add a wall photo" while the layout has no photos.
  - Menu: Photos, Reset, Past layouts, Edit wall.
  - The same widget with `readOnly: true` shows an archived layout: no FAB, no edit, no retire, no reset.
- **Photos** (`/walls/:wallId/photos`): a thumbnail grid. Add from camera or gallery, edit the label, drag to reorder, and see "N problems use this photo". Deleting a photo is refused while any mark uses it, naming the problems. Tapping a photo opens it full-screen with pan and zoom.
- **Past layouts**: a list showing the start–end dates, name, problem count and photo count. Delete with undo. Tapping a layout opens the read-only wall screen.
- **Reset**: Menu → Reset opens a dialog ("Start a new layout? The current one will be archived with its N problems") with an optional name and a start date defaulting to today. Then the empty new layout appears with an undo snackbar and the "Add a wall photo" prompt.
- **Problem view**: read-only photo with its marks, pan and zoom. The app bar shows name and grade. The description sits in a collapsible bottom sheet (hidden when empty) on phones, and in a side panel on wide windows.
  - Menu: Edit, Retire/Un-retire, Delete.
  - Delete is only available here (no swipe in the list). It pops back to the list and shows the undo snackbar there.
  - Read-only for retired problems apart from Un-retire and Delete. Archived-layout problems offer nothing but view.
- **Editor**: marks come first, using the role palette from issue 05.
  - Save opens a details sheet: name (required), grade, description, set date. On an existing problem the details are also under "Edit details" in the app bar.
  - Leaving with unsaved changes asks "Discard changes?".
  - The editor never adds photos; it only uses the layout's existing ones.
  - The non-blocking start/finish hint from issue 06 lives here.

### Wide windows

The same screens as on a phone; there is no list-detail split in the MVP (see the map's Out of scope). The switch happens at **≥ 600 dp** window width, checked with `LayoutBuilder` on each screen, not per platform, so a phone in landscape counts as wide:

- Lists are capped at about 720 px wide.
- The editor's role palette becomes a vertical side bar.
- The problem view's details move to a side panel.
- Photo screens fill the window.

### Left to the next ticket

How a problem shows (and the editor switches between) several photos is [How does a problem span several wall photos?](09-multi-photo-viewer.md).

## Comments

- 2026-11-21 (spraywall-08, from [How are backups exported and imported?](08-backup-format.md)): place the export (everything / one wall) and import actions, the import progress + summary dialog, and the backup reminder nudge.

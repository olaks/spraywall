# 05: Problem view, edit and delete

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** Tapping a problem in the list opens a read-only view with pan and zoom, name and grade in the app bar and the description in a collapsible sheet. From its menu the user edits the problem (marks and details) or deletes it with undo shown on the list.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] Problem view route; read-only photo with marks; description sheet hidden when empty
- [ ] Edit opens the editor on the problem; "Edit details" in the app bar; leaving with unsaved changes asks "Discard changes?"
- [ ] Delete problem returns a snapshot (problem + marks); round-trip DB test; delete pops to the list and shows the undo there
- [ ] Widget test: the view has no edit controls on the photo

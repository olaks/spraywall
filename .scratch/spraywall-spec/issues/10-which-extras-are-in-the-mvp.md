# Which extras are in the MVP?

Type: grilling
Status: resolved
Claimed by: spraywall-10 2026-11-21T13:40:00+01:00
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

Three features are wanted but not yet placed: for each, is it **in the MVP**, a **stretch goal** (specced lightly, built after the core slices), or **out of scope** for this map?

- **Overlap views**: showing several problems' marks at once (e.g. "which problems use this area").
- **Sharing a single problem**: e.g. exporting an image of a wall photo with the problem's marks drawn on it, as a lightweight step towards multi-user use without sync.
- **Carrying a problem forward** after a reset: copy name, grade and description into the new layout, then re-mark the holds on a new photo (marks are never copied; see [What does a reset do?](04-what-a-reset-does.md)).

For each one kept in the MVP or as a stretch goal, settle enough of its shape (entry point, what it produces) that a later ticket or the spec can pin it down.

## Answer

Resolved by grilling, 2026-11-21. No glossary changes: "overlap view" is a screen name, not a domain term (**Mark** already says holds aren't recorded on their own). No ADR, because each choice is cheap to revisit.

1. **"Stretch goal" means** a short section at the end of the spec, built as the last slices. The MVP ships without it, and no core slice may depend on one. Each stretch goal gets enough shape (entry point, output) to be sliced later.
2. **Overlap views: stretch goal.**
   - Entry: the full-screen photo opened from the Photos screen gets a "Show problems" toggle.
   - It draws the marks of every current, non-retired problem on that photo, faintly, in role colours.
   - Tapping a mark opens a bottom sheet listing the problems with a mark that **overlaps** it (the circles intersect, any role), with name and grade. Tapping one opens its problem view.
   - No filters in this version. Overlap is approximate by design, because marks are per problem.
3. **Sharing a single problem: stretch goal, first in line.**
   - **Share** goes in the problem view menu, everywhere that view appears, including retired and archived problems.
   - It renders **one JPEG per wall photo carrying the problem's marks**, at stored resolution (2560 px long edge), with the marks drawn on.
   - A caption bar shows problem name · grade · wall name, with a small role legend (start/hand/foot/finish colours).
   - Output goes to the system share sheet on Android, a save dialog on Linux, or a download on the web. Only images go out; nothing can be imported on the other side.
4. **Carrying a problem forward after a reset: out of scope.** It would only copy name, grade and description, and re-marking is the real work. The archived layout stays viewable for reference, and no link between problems across layouts is needed in the data model.

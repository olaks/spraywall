# 06: Several photos

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** A problem can have marks on any of the layout's photos. The editor and the view show one photo at a time with a thumbnail strip to switch; each photo keeps its own zoom.

**Blocked by:** 05

**Status:** done (2026-11-22)

- [x] Strip of the layout's photos in sortOrder, under the photo on phones; each thumb shows label, this problem's marks and a count per role; current one highlighted; hidden for a single-photo layout; no swipe
- [x] Each photo keeps its own pan/zoom while the screen is open; switching deselects
- [x] Last mark size kept per photo for the editor session
- [x] Opening photo is a pure function with unit tests: view → first photo with a start mark, else first with any mark; editor → the photo the view showed, or the first photo for a new problem
- [x] In the view, photos without this problem's marks are dimmed but selectable
- [x] A mark's photo must belong to the problem's layout (enforced in code)
- [x] Widget tests: switching clears the selection and keeps each photo's zoom; the view opens on the right photo and dims unmarked photos

## Comments

- **Per-photo zoom** lives in `PhotoViewController` (a `TransformationController` that also remembers its last fit), one per photo in a map on the screen's state. `ZoomablePhoto` is keyed by photo id, so switching gives a fresh viewer on that photo's own controller, and it only fits a controller that has never been fitted (or on a resize, as before).
- **Editor opening photo:** the view's Edit goes to `…/edit?photo=<id>`. `openingPhoto(photos, marks, shown:)` takes that photo while it is still in the layout, else the view's rule, so a reloaded edit URL without the parameter still opens somewhere sensible. A new problem has no marks, so it opens on the first photo.
- **Last mark size per photo** and **a mark's photo in the problem's layout** were already in place from tickets 04 and 05 (`MarkEditorController._lastR`, `_checkProblem`, `addMark`), with tests; nothing new here.
- Both screens use one `PhotoStrip` widget; the view passes `dimUnmarked: true`. It hides itself for a single-photo layout. Each thumb has fixed row heights (96 dp strip) so it can't overflow whatever the font.
- After Save, or Discard of an edit, the view opens on its opening photo again rather than the photo last edited, per the spec's view rule.
- Tests: `test/several_photos_test.dart` (5 widget tests) and 3 more in `opening_photo_test.dart`. Planted-bug checks: keeping the selection on switch, refitting on every show, ignoring `?photo=`, no dimming, and a strip on a single photo each fail their test.


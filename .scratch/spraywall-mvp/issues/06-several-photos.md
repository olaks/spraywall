# 06: Several photos

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** A problem can have marks on any of the layout's photos. The editor and the view show one photo at a time with a thumbnail strip to switch; each photo keeps its own zoom.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] Strip of the layout's photos in sortOrder, under the photo on phones; each thumb shows label, this problem's marks and a count per role; current one highlighted; hidden for a single-photo layout; no swipe
- [ ] Each photo keeps its own pan/zoom while the screen is open; switching deselects
- [ ] Last mark size kept per photo for the editor session
- [ ] Opening photo is a pure function with unit tests: view → first photo with a start mark, else first with any mark; editor → the photo the view showed, or the first photo for a new problem
- [ ] In the view, photos without this problem's marks are dimmed but selectable
- [ ] A mark's photo must belong to the problem's layout (enforced in code)
- [ ] Widget tests: switching clears the selection and keeps each photo's zoom; the view opens on the right photo and dims unmarked photos

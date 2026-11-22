# 14: ⭐ Overlap view (stretch)

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** Stretch goal. A "Show problems" toggle on the full-screen photo draws every current, non-retired problem's marks faintly; tapping a mark lists the problems with overlapping marks, and tapping one opens it.

**Blocked by:** 13

**Status:** done (2026-11-22)

- [x] Overlap is a pure function with unit tests: same photo, circles crossing or touching, compared in photo pixels, excluding the tapped mark's own problem
- [x] Sheet lists name and grade; tap opens the problem view; no filters

## Comments

- `lib/marks/overlap.dart`: `marksOverlap(a, b, photo)` (same photo, centre distance ≤ r₁ + r₂ in photo pixels, so touching and one-inside-the-other count; a 1e-6 slack for exact touches) and `overlappingProblems(tapped, marks, photo)` (the other problems, each once, in mark order; the tapped mark's own problem left out). Unit-tested on a 2000×1000 photo, where comparing in 0..1 coordinates would get vertical neighbours wrong.
- The full-screen photo (Photos → a photo) has a layers toggle in its app bar, "Show problems" / "Hide problems", off on opening. On: the marks of the layout's non-retired problems on this photo, through the existing `MarkLayer` at 60 % opacity (taps only, no editing).
- Tapping a mark opens a bottom sheet: "This mark" with its own problem, then "Overlapping marks" (sorted by name), or "No other problem has a mark here". Each row shows the name and the grade ("–" for ungraded); tapping one goes to its problem view. `context.go`, like the rest of the app, so Back from there follows the hierarchy to the wall screen, not back to the photo.
- I listed the tapped mark's own problem at the top of the sheet: the overlap function leaves it out as the ticket says, but without it there'd be no way to see or open the problem whose mark was tapped.
- Tests: `test/overlap_test.dart` (3 unit, 3 widget: only in-use problems on this photo drawn, faint; the sheet's rows and grades, retired and other-photo problems absent, opening one; a lone mark). The widget test zooms to 1:1 before tapping, because at the fit zoom the 20 px minimum touch targets of neighbouring marks overlap.
- Planted bugs, all caught (12): comparing in 0..1 coordinates; touching excluded; any photo; the own problem listed; a problem listed twice; retired problems drawn; other photos' marks drawn; not faint; the own row missing; a row tap not opening; no grades; on by default.

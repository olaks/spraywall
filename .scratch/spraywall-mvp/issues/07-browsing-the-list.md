# 07: Browsing the list

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The wall screen becomes a usable problem list: grade-range and name filters, a sort toggle, rich rows, and the layout shown in the app bar.

**Blocked by:** 04

**Status:** done (2026-11-22)

- [x] Grade-range and name filters and the sort (grade easiest first, ungraded last, ties by name; or newest set date) are pure functions with unit tests, ordering grades by position in the wall's scale
- [x] Rows show name, grade, set date and the first marked photo's thumbnail
- [x] App bar subtitle: layout name or start date
- [x] Filters and sort live in memory, not the URL

## Comments

- **Rules** are in `lib/problems/browse.dart`: `browse(problems, scale, query)` and `firstMarkedPhoto`, unit-tested in `test/browse_test.dart`. Grades rank by their index in the wall's scale; a grade off the scale counts as ungraded. Names compare in Dart with `toLowerCase`, so "Ê" matches "ê" (SQLite's NOCASE wouldn't).
- **Decided here:** while a grade range is set, ungraded problems are hidden (they have no place in a range; the dialog says so). Choosing the whole scale, or "Any grade", clears the range and brings them back. An open end ("6B and up") runs to the end of the scale.
- **Row photo:** the first photo in the layout's order with any of the problem's marks, as the spec says, which can differ from the photo the view opens on (the start photo). It shows that photo's marks.
- **Where the query lives:** `problemQueryProvider`, a Riverpod family keyed by wall id and not auto-disposed: filters survive opening a problem and coming back, and leaving the wall, for the app run; never in the URL.
- **New reads:** `watchLayoutMarks` (one query for every row's marks) and `photoThumb` (the thumbnail without the 2560 px JPEG). The photo strip now uses the thumbnail-only read too, through the shared `MarkedThumb` widget.
- Tests: `browse_test.dart` (10), `wall_screen_test.dart` (7), plus one each in `photos_test.dart` and `problems_test.dart`. Planted-bug checks: ungraded sorted first, grades compared as text, a range that keeps ungraded, the last marked photo instead of the first, and Clear filters leaving the search text each fail their tests.


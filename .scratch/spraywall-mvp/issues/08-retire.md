# 08: Retire

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** When a few holds move, the user retires the problems that broke. Retired problems disappear from the list unless "Show retired" is on, and can be un-retired.

**Blocked by:** 05

**Status:** done (2026-11-22)

- [x] Retire / Un-retire in the problem view menu set / clear retiredOn
- [x] "Show retired" chip shows retired problems greyed with a badge
- [x] A retired problem's view offers only Un-retire and Delete
- [x] Tests: retire hides, Show retired shows, un-retire restores

## Comments

- `retireProblem(id, {today})` / `unretireProblem(id)` set and clear `retiredOn` in a transaction that refuses (`StateError`) a problem on an archived layout, so the database keeps archived layouts read-only, not just the UI.
- "Show retired" lives in `ProblemQuery` (per layout, in memory, like the other filters). It widens the list rather than narrowing it, so it is not one of `filters` and "Clear filters" keeps it. Retired problems sort among the others.
- With no filters on and every problem retired, the list says "Every problem here is retired" with a Show retired button, rather than "No problems match" with a Clear filters that would do nothing.
- Retired rows: opacity 0.5 and an outlined "Retired" badge after the name. The problem view's subtitle reads "6B · Retired yyyy-MM-dd".
- Retire stays on the view and shows an undo snackbar (undo = un-retire). Un-retire has no snackbar: it is its own undo's inverse and visible in the menu.
- The editor shows Not found for a retired problem, as for an archived one.
- The filter bar's chips and sort toggle now share one `Wrap`: with the new chip, a narrow phone squeezed the chip label instead of wrapping it.
- Tests: `test/retire_test.dart` (3 database, 4 widget), `test/browse_test.dart` (retired hidden by default, shown with filters still applying, clearing keeps "Show retired"). The `rows` helper in `wall_screen_test.dart` now reads a title's first text, so the badge doesn't break it.
- Planted bugs, all caught: retired shown by default; clearing drops "Show retired"; Edit offered on a retired problem; the editor opening a retired problem; an archived layout's problem retirable; a retired row not greyed; no badge; the all-retired list saying "No problems match"; the snackbar undo doing nothing; the retire date not today.

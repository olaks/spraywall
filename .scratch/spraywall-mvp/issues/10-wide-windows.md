# 10: Wide windows

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** On windows ≥ 600 dp wide (landscape phones included) every screen uses the space: the photo strip becomes a left column, the role palette a right side bar, problem details a side panel, and lists are capped at about 720 px.

**Blocked by:** 06, 07, 09

**Status:** done (2026-11-22)

- [x] Switch via `LayoutBuilder` per screen at 600 dp, not per platform
- [x] Editor: left strip column, right palette side bar; view: left strip, right details panel; photo screens fill the window; lists capped ~720 px
- [x] Widget tests at 400 and 800 dp wide for the editor and the problem view: palette, strip and panel in place, and placing a mark still works

## Comments

- `lib/widgets/wide.dart`: `wideWidth` (600), `readableWidth` (720), `isWide(constraints)`, and `ReadableWidth`, which hands a list its side insets. Each screen measures its own body with a `LayoutBuilder`.
- Lists are capped by padding, not by a centred box: the scroll view stays window-wide, so on a desktop the wheel and the scrollbar work beside the column too. Capped: the wall list, the wall screen (filter bar and rows line up), Photos, Past layouts, Settings. The full-screen photo viewer fills the window.
- `PhotoStrip` takes an `axis`: a 96 dp row under the photo, or a 112 dp column on the left.
- Editor, wide: strip | photo | palette side bar (160 dp, the chips in a column with trash and done under them, scrolling if a landscape phone is too short).
- View, wide: strip | photo | details panel (300 dp): set date, retired date, the description (or "No description"), always open. Name and grade stay in the app bar, as on a phone. The phone's folding description sheet is unchanged.
- Resizing across 600 dp keeps the editor's working marks (they live in the screen's state, above the `LayoutBuilder`) and each photo's zoom (its `PhotoViewController`).
- `pumpApp` now opens a 400×800 phone window by default: the test default, 800×600, is wide, and silently flipped every existing widget test into the wide layout (one strip-order test kept passing only because a column's thumbnails all share one x).
- Tests: `test/wide_windows_test.dart` (10): the editor at 400, 800, the 599/600 boundary, a landscape phone 800×360 and a resize mid-edit, placing a mark each time; the view at 400 and 800 (panel, dimmed photos in the column); lists capped and centred at 1200 and full width at 400, with the scroll view window-wide.
- Planted bugs, all caught: never wide; the switch at 700, at 801, and at > 600; the palette on the left; no panel; the view's strip on the right; lists uncapped; the filter bar uncapped; capping with a centred box; the strip ignoring its axis; the column not dimming.

# PROTOTYPE: a problem across several wall photos (throwaway)

For [How does a problem span several wall photos?](../../issues/09-multi-photo-viewer.md).

The layout has three photos, cropped from `sample/` to stand in for separate shots:

| Photo | What it shows | Problem "Red crimps" (seeded) |
| --- | --- | --- |
| Top | upper wall, about 60 % | 2 hands + finish |
| Bottom | lower wall incl. kicker; overlaps Top by a band of holds | 2 starts, 2 hands, 2 feet |
| Kicker | close-up of the kicker (also on Bottom) | none |

The two low hands on Bottom also show on Top, and the feet also show on Kicker. That's the "same hold on two photos" case.

Run (from this folder):

- Linux: `flutter run -d linux` (add `--dart-define=VARIANT=B` to start on a variant)
- Android: `flutter run --profile` (debug builds make gestures feel janky)
- Web: `flutter run -d chrome`, then `?variant=A..C`

App bar: 👁 problem view · ✎ editor for the existing problem (keeps the photo the view showed) · ＋ editor for a new problem (empty). The ⋮ menu toggles "view opens on the start marks" (vs the first marked photo) and "view hides photos without marks". The top-left panel shows the full state (which photo, why it opened there, marks per photo, zoom lock); tap it to collapse it. Resize the Linux window past 600 px wide to get the side-bar layouts.

| Key | Name | Switching photos | View: photos without marks | Editor |
| --- | --- | --- | --- | --- |
| A | Swipe pages | `PageView` swipe plus ‹ › arrows and dots; swipe is locked while zoomed in, while a mark is selected or held, and with a mouse | hidden | palette below (side bar when wide) |
| B | Thumbnail strip | tap a thumbnail (with its marks drawn and per-role counts); no swipe | dimmed, still reachable | strip above the palette; wide: strip left, palette right |
| C | Overview first | view: marked photos stacked in one scrolling column, tap one to zoom; editor: grid of all photos, tap one to edit it full screen, back to return | listed as "Not on: …" | one photo per screen, chosen from the grid |

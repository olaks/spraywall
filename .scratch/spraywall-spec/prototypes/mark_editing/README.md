# PROTOTYPE: mark-editing interaction (throwaway)

For [How should marking holds feel on a dense wall?](../../issues/05-mark-editing-interaction.md).
Four interaction variants on the real wall photo (downscaled to 1920×2560). Marks are in memory only and are shared across variants.

Run (from this folder):

- Linux: `flutter run -d linux` (add `--dart-define=VARIANT=C` to start on a variant)
- Android: `flutter run --profile` (use profile mode, because debug builds make gestures feel janky)
- Web: `flutter run -d chrome`, then `?variant=A..D` in the URL

Switch variants with the bottom pill or ←/→. The top-left panel shows the full mark state; tap it to collapse it.

| Key | Name | Where | Role | Size | Move / delete |
| --- | --- | --- | --- | --- | --- |
| A | Role palette | tap empty photo places a mark (always) | pick from the palette first; the palette also changes the selected mark's role | resize handle; new marks reuse the last size | drag the selected mark; trash button |
| B | Tap to cycle, zoom sets size | tap places a hand mark | tap a mark: hand → foot → start → finish → removed | 18 screen px at the current zoom | long-press / right-click selects, then drag or use the handle |
| C | Crosshair | pan the hold under a fixed reticle, then press a role button | role buttons | slider; the reticle shows the size | tap a mark to pick it up (it sticks to the reticle while you pan); trash button |
| D | Long-press radial menu | long-press / right-click, then flick or tap a role; plain taps never add marks | radial menu (finish ↑, foot ↓, start ←, hand →) | handle; last size | drag the selected mark; floating toolbar next to the mark |

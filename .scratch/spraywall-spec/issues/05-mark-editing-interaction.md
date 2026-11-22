# How should marking holds feel on a dense wall?

Type: prototype
Status: resolved
Claimed by: spraywall-f4 2026-11-21T13:28:40+01:00
Blocked by: 02
Map: [Spraywall: problem-setting app spec](../map.md)
Prototype: [mark-editing variants A–D](../prototypes/mark_editing/README.md)

## Question

How should a user place, resize, move, change the **role** of and delete circle **marks** while setting a **problem** on a phone, on a wall as dense as `sample/`?

Build a throwaway Flutter prototype on the sample photo (using the approach from the zoomable-photo research) and try out the options: tap to place vs. long-press; choosing the role first (a role palette) vs. tapping a mark to cycle its role; resize handles vs. pinch on a mark; how to tell a tap that adds a mark from one that selects a mark. Check it on Android and with a mouse on desktop. The outcome is the chosen interaction, linked to the prototype.

## Answer

**Variant A: the role palette.** The user chose it over B (tap to cycle, zoom sets size), C (crosshair) and D (long-press radial menu) after trying all four on the sample wall.

The editor behaves like this:

- **Role palette.** A bar shows the four **roles** (start, hand, foot, finish) as chips. The chosen role is the brush. When a **mark** is selected, the palette shows that mark's role, and tapping a chip changes it (and the brush).
- **Placing.** A tap on empty photo always places a mark with the brush role and selects it. It never just deselects, so marking a run of holds is one tap each.
- **Size.** A new mark reuses the last radius (it starts at about 1.8 % of photo width). Resize with the handle on the right edge of the selected mark.
- **Selecting and moving.** A tap on a mark selects it. Only the selected mark is draggable, and the viewer stops panning while a finger or button is down on it. A drag that starts anywhere else pans the photo.
- **Removing.** A trash button in the palette bar deletes the selected mark, with an undo snackbar. A done button deselects.
- **Hit area and stacking.** Unselected marks have a hit radius of at least 20 screen px. The selected mark paints last, so it wins overlaps.
- **Mouse.** The same as touch: left click to place or select, drag the selected mark, wheel to zoom.

Not adopted: tying size to zoom (B), cycling roles by tapping (B), the crosshair (C), and long-press menus (D).

Prototype (throwaway, kept as the primary source because there's no git branch to hold it): [prototypes/mark_editing/](../prototypes/mark_editing/README.md). Variant A is `VariantA` in `lib/variants.dart`; the shared viewer and mark widget are in `lib/viewer.dart`.

## Comments

- 2026-11-21 (spraywall-09, from [How does a problem span several wall photos?](09-multi-photo-viewer.md)): "new marks reuse the last size" is kept **per photo**, because a close-up shows the same hold larger.

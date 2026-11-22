# How does a problem span several wall photos?

Type: prototype
Status: resolved
Claimed by: spraywall-09 2026-11-21T13:38:52+01:00
Blocked by: 07
Map: [Spraywall: problem-setting app spec](../map.md)
Prototype: [multi-photo variants A–C](../prototypes/multi_photo/README.md)

## Question

When a layout has several **wall photos**, how do the problem view and the editor (screens from [What are the MVP screens and navigation?](07-screens-and-navigation.md)) move between them, and how does a **problem** handle a hold that shows on more than one photo?

Try on a phone, with two or three photos of the sample wall (crops of `sample/` will do):
- Switching photos: swipe (`PageView`), tabs, or a thumbnail strip. Check how each gets along with pan and zoom inside `InteractiveViewer` and with the editor's role palette (bottom bar on phones, side bar at ≥ 600 dp).
- Which photo opens first in the view (the first photo with marks? the one with the start marks?) and in the editor for a new problem.
- Showing which photos carry this problem's marks, and hiding or skipping photos with none in the view.
- The same hold on photos A and B: mark it on both, or only on one photo, with the view leading the user to the photos that carry marks? Marks stay one-per-photo (data model, issue 06).

The outcome is the chosen behaviour, linked to the prototype.

## Answer

**Variant B: the thumbnail strip.** The user chose it on 2026-11-21, over A (swipe pages) and C (overview first). No glossary changes and no ADR.

### Switching photos

- The problem view and the editor show **one photo at a time**, with a **strip of thumbnails** of the layout's photos in their `sortOrder`. Tapping a thumbnail switches photos. There is **no swipe**: the swipe gesture fights with dragging the selected mark and with panning a zoomed photo, and Flutter doesn't swipe pages with a mouse.
- Each thumbnail shows the photo's label, this problem's marks drawn on it, and a count of marks per role. The current photo has a highlighted border.
- **Phones:** the strip sits under the photo, about 92 dp high. In the editor, the role palette sits under the strip. In the view, the collapsible description sheet from [What are the MVP screens and navigation?](07-screens-and-navigation.md) comes below the strip.
- **≥ 600 dp:** the strip is a vertical column on the left. In the editor the palette is a side bar on the right; in the view, the details side panel is on the right.
- Each photo **keeps its own pan and zoom** while the screen is open, so going back to a photo returns to where the user was.
- Switching photos deselects the selected mark.
- A layout with a single photo hides the strip.

### Which photo shows first

- **Problem view:** the first photo (in `sortOrder`) that carries a **start** mark. If no photo has one, the first photo with any marks.
- **Editor, existing problem:** opens on the photo the view was showing.
- **Editor, new problem:** opens on the first photo of the layout.

### Photos without marks

- In the **view**, photos that carry none of this problem's marks are **dimmed in the strip but still selectable**, so the user can still look at the rest of the wall.
- In the **editor**, every photo looks the same.

### A hold on more than one photo

**Mark it once**, on whichever photo shows it best. Photos are separate views, and nothing maps a spot on one photo to the same spot on another, so marks are never linked or copied between photos. The strip's thumbnails show where a problem's marks are, which is enough to lead the user to them. Nothing stops the user from marking a hold on both photos, and the app doesn't detect it.

### Refinements to earlier decisions

- **"New marks reuse the last size"** ([How should marking holds feel on a dense wall?](05-mark-editing-interaction.md)) applies **per photo**, kept in memory for the editor session. A close-up shows the same hold larger, so a size carried over from another photo comes out wrong. A photo with no last size starts at about 1.8 % of the photo width.
- **Fit-to-screen** must scale all three axes evenly (`Matrix4.diagonal3Values(f, f, f)`). `InteractiveViewer` and `getMaxScaleOnAxis()` read the largest axis, so a z-scale of 1 reads as zoom 1 and makes hit radii and the "zoomed in" check wrong. The ticket 05 prototype had this bug.

Prototype (throwaway, kept as the primary source because there's no git branch to hold it): [prototypes/multi_photo/](../prototypes/multi_photo/README.md). Variant B is `VariantB` in `lib/variants.dart`. The shared zoomable canvas, the static marked thumbnail and the palette are in `lib/viewer.dart`.

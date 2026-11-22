# What does a reset do?

Type: grilling
Status: resolved
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

When the user **resets** a **wall** (starts a new **layout**), what exactly happens, and what can they still do with archived layouts?

Open points: are any wall photos carried over to the new layout, or always retaken? Can an archived layout and its problems be viewed, edited, copied forward ("this problem still works after the reset"), or deleted? Can a reset be undone? Can there be several walls, and how does the user switch between them? Does a layout have its own name or date?

## Answer

Resolved by grilling, 2026-11-21.

1. **A small change is not a reset.** When a few holds move, the user **retires** the problems that broke, one at a time; the layout stays current. A **reset** is for big changes. Photos in the current layout can't be replaced, because that would break every mark drawn on them; the user adds a new photo instead, and older problems keep the photo they were drawn on.
2. **A new layout starts with no photos.** The app asks for photos straight after a reset; nothing is copied from the old layout.
3. **No carrying problems forward in the MVP.** A later "copy forward" would copy name, grade and description, and the user re-marks the holds on a new photo. Marks are never copied, because positions on an old photo don't match a new one. Moved to the map's *Not yet specified*.
4. **Archived layouts can be browsed and deleted, not edited.** You can view their photos, problems and marks read-only, and delete the whole layout with undo; most of its space is photos. Retired problems behave the same way inside the current layout.
5. **A reset can only be undone straight away,** with a snackbar undo as in `training_logger`. After that it's permanent; there's no "make this layout current again".
6. **Several walls in the MVP.** The wall list is the start screen; each wall has exactly one current layout.
7. **A layout is identified by its start date plus an optional name**; it gets an end date when it's archived.

Glossary: added **Retired problem**; **Layout** and **Reset** already match.

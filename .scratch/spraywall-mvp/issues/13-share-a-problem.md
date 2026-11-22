# 13: ⭐ Share a problem (stretch)

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** Stretch goal, first in line. Share in the problem view menu (current, retired and archived problems) renders one JPEG per photo carrying the problem's marks, with a caption bar and role legend, and sends it to the share sheet, a save dialog or a download.

**Blocked by:** 10, 12 (ordering: stretch goals come after the core)

**Status:** done (2026-11-22)

- [x] Caption text (name · grade · wall name) is a pure function with unit tests
- [x] Render test: one image per photo with marks, at the photo's pixel size, each mark's ring sampled for its role colour
- [x] Images only; nothing importable on the other side

## Comments

- `lib/share/share_problem.dart`: pure `shareCaption` (`Arête · 6B · Home wall`; no grade when ungraded), `photosToShare` (photos carrying the problem's marks, layout order), `shareImageName` (`Arête.jpg`, or `Arête-Kicker.jpg` when there are several), `captionBarHeight` (7 % of the width, 48–220 px); `renderShareImage` draws with `dart:ui` (the stored JPEG, rings as the app draws them, a dark halo under each, stroke scaled to the photo at 0.3 % of its width, min 4 px), and `encodeShareJpeg` (quality 90, 4:4:4 chroma so thin rings keep their colour) runs in an isolate via `shareEncoderProvider`.
- The image is the photo at its stored pixel size with the caption bar added **below** it, not over it, so nothing at the bottom of the photo (the kicker) is hidden: height = photo height + bar. The legend shows the roles on that image.
- Share is in the problem view's menu everywhere: current (Edit, Share, Retire, Delete), retired (Share, Un-retire, Delete), archived (Share alone, so archived problems now have a menu). A progress dialog shows "Preparing image 1 of 2". All images go in one share.
- `shareFile` became `shareFiles` (a list): Android shares them together; the desktop saves one file with a save dialog, or asks for a folder for several; the web downloads each. Backup export uses it with a list of one. `fileSafe` (format_utils) now names both backups and share images; `roleLabel` (mark_geometry) is shared by the palette and the legend.
- Tests: `test/share_problem_test.dart` (8): the pure parts; the render at pixel level (an 800×600 photo comes out 800×656, each role's ring sampled for its colour, the hold inside left clear, the bar dark); and the flow (one share call with one JPEG per marked photo, sized photo + bar, named; the menus for current, retired and archived). Two older tests updated for Share in the menu.
- Planted bugs, all caught (12): every ring one colour; filled marks; no caption bar; rendered at half size; the grade dropped; the name untrimmed; every photo shared; one share per image; names ignoring "several"; no Share on an archived problem; Edit on an archived one; the bar not dark.
- Looked at a render (a 1280×960 fixture, test font) in the scratchpad: rings, halos, caption and legend laid out as intended. Not yet seen with real fonts on a device (on `release.sh`'s list).

# 13: ⭐ Share a problem (stretch)

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** Stretch goal, first in line. Share in the problem view menu (current, retired and archived problems) renders one JPEG per photo carrying the problem's marks, with a caption bar and role legend, and sends it to the share sheet, a save dialog or a download.

**Blocked by:** 10, 12 (ordering: stretch goals come after the core)

**Status:** ready-for-agent

- [ ] Caption text (name · grade · wall name) is a pure function with unit tests
- [ ] Render test: one image per photo with marks, at the photo's pixel size, each mark's ring sampled for its role colour
- [ ] Images only; nothing importable on the other side

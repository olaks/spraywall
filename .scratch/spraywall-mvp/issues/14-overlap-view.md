# 14: ⭐ Overlap view (stretch)

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** Stretch goal. A "Show problems" toggle on the full-screen photo draws every current, non-retired problem's marks faintly; tapping a mark lists the problems with overlapping marks, and tapping one opens it.

**Blocked by:** 13

**Status:** ready-for-agent

- [ ] Overlap is a pure function with unit tests: same photo, circles crossing or touching, compared in photo pixels, excluding the tapped mark's own problem
- [ ] Sheet lists name and grade; tap opens the problem view; no filters

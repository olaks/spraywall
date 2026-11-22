# 10: Wide windows

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** On windows ≥ 600 dp wide (landscape phones included) every screen uses the space: the photo strip becomes a left column, the role palette a right side bar, problem details a side panel, and lists are capped at about 720 px.

**Blocked by:** 06, 07, 09

**Status:** ready-for-agent

- [ ] Switch via `LayoutBuilder` per screen at 600 dp, not per platform
- [ ] Editor: left strip column, right palette side bar; view: left strip, right details panel; photo screens fill the window; lists capped ~720 px
- [ ] Widget tests at 400 and 800 dp wide for the editor and the problem view: palette, strip and panel in place, and placing a mark still works

# 07: Browsing the list

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** The wall screen becomes a usable problem list: grade-range and name filters, a sort toggle, rich rows, and the layout shown in the app bar.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] Grade-range and name filters and the sort (grade easiest first, ungraded last, ties by name; or newest set date) are pure functions with unit tests, ordering grades by position in the wall's scale
- [ ] Rows show name, grade, set date and the first marked photo's thumbnail
- [ ] App bar subtitle: layout name or start date
- [ ] Filters and sort live in memory, not the URL

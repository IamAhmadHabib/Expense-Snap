---
type: tasks
status: active
tags: [bugs]
---

# Known Bugs

Current known issues are mainly product gaps/design debt:

- Analytics detailed breakdown overlay cannot be opened.
- Analytics active-stat and insight copy still need fully real derived logic.
- Login, forgot-password, confirmed logout, account deletion, rating, and feedback actions are not functionally connected. Log Out now reaches its confirmation sheet.
- Personalization defaults to USD, does not enforce the documented category minimum, and does not persist selected categories.
- No current confirmed performance regression remains after the local polish pass; collect a fresh Flutter DevTools profile recording on device to verify remaining jank clusters.
- True launch readiness still needs golden tests, final icons, permissions copy, store screenshots, privacy policy copy, and physical-device QA.

Related:

- [[Open Tasks]]
- [[Phase 1 UI Shell]]
- [[Phase 2 Real Expense Flow]]

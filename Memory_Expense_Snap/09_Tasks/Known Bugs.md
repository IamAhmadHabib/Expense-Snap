---
type: tasks
status: active
tags: [bugs]
---

# Known Bugs

Current known issues are mainly product gaps/design debt:

- Analytics detailed breakdown overlay cannot be opened from the chart interaction.
- Profile account deletion ("Delete Forever"), store rating redirect, and email feedback dispatch are UI sheets without backend hooks.
- Personalization category selection does not strictly enforce the 3-category minimum before continuing.
- No current confirmed performance regression remains after the local polish pass; collect a fresh Flutter DevTools profile recording on device to verify remaining 120 Hz jank clusters.
- Launch readiness tasks pending: golden tests, final store icons, permissions copy, store screenshots, and privacy policy copy.

Related:

- [[Open Tasks]]
- [[Next Sprint]]
- [[Phase 1 UI Shell]]
- [[Phase 2 Real Expense Flow]]

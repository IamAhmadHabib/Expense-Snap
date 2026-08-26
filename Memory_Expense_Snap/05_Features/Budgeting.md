---
type: feature
status: implemented-local-and-firestore
tags: [budget]
---

# Budgeting

Budget configuration appears in Personalization, Dashboard, and Profile.

Implemented:

- Persistent monthly budget stored in `AppSettingsRepository` and synced to Firestore.
- Connected to real-time transaction totals on the Dashboard (calculating spent amount, remaining balance, and burn rate).
- Editable via Profile monthly budget sheet.

Related:

- [[Personalization]]
- [[Dashboard]]
- [[Profile]]
- [[Firebase Architecture]]
- [[Phase 3 Profile Budget State]]

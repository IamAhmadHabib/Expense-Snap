---
type: tasks
status: active
tags: [bugs]
---

# Known Bugs

Current known issues are mainly product gaps/design debt:

- [[Dashboard]] avatar is not connected.
- [[Dashboard]] notification bell is not connected.
- Dashboard Voice, Scan, and Manual quick actions are not connected.
- Dashboard tab changes recreate tab screens and reset their local state.
- [[History]] uses mock data.
- History edit does not update a transaction; delete/undo is screen-local.
- [[Analytics]] uses mock data.
- Analytics detailed breakdown overlay cannot be opened.
- [[Add Transaction]] save is simulated.
- Add Transaction opens on Manual instead of the intended Voice default, and no capture mode emits a real transaction.
- Several Profile controls are no-op or discard their edited values.
- Login, forgot-password, logout, account deletion, rating, and feedback actions are not functionally connected.
- Personalization defaults to USD, does not enforce the documented category minimum, and does not persist selected categories.
- [[Design Debt]] hardcoded colors remain.

Related:

- [[Open Tasks]]
- [[Phase 1 UI Shell]]
- [[Phase 2 Real Expense Flow]]

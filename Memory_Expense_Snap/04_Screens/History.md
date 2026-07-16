---
type: screen
status: local-data-connected
tags: [screen, history]
---

# History

Ledger-style transaction history.

Current live-code behavior:

- History reads from the shared local transaction repository.
- Edit opens a pre-filled [[Add Transaction]] sheet and saves back through the repository.
- Delete and undo mutate the shared repository.
- Food filtering normalizes Dining/Food/Food & Dining into the Food group.
- The This Month chip is treated as a date filter only, not as a category filter.

Remaining gaps:

- Search/filter UX is local to the screen and may need more complete saved filter behavior later.

Related:

- [[History Code]]
- [[Transactions]]
- [[Data Flow]]
- [[Phase 2 Real Expense Flow]]

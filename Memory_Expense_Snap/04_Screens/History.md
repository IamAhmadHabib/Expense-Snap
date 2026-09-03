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
- Transaction items use `CategoryUtils.style()` rendering 48×48 category pastel squircles with 24px filled icons (`PhosphorIconsStyle.fill`). The previous solid black 52×52 boxes have been eliminated for a lighter, breathing luxury layout.

Remaining gaps:

- Search/filter UX is local to the screen and may need more complete saved filter behavior later.

Related:

- [[History Code]]
- [[Transactions]]
- [[Data Flow]]
- [[Phase 2 Real Expense Flow]]
- [[Color Tokens]]
- [[Design System]]
- [[Dashboard]]
- [[Add Transaction]]

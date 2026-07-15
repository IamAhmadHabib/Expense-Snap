---
type: screen
status: ui-built-mock-data
tags: [screen, history]
---

# History

Ledger-style transaction history.

Confirmed live-code gaps:

- The screen owns and regenerates its own mock transaction list.
- Edit opens a pre-filled [[Add Transaction]] sheet but ignores the result, so edits are not applied.
- Delete and undo affect only the screen-local list.
- The local list resets when the Dashboard shell rebuilds this tab.

History should read and mutate the shared source in [[Repository Plan]].

Related:

- [[History Code]]
- [[Transactions]]
- [[Data Flow]]
- [[Phase 2 Real Expense Flow]]

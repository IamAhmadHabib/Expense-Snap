---
type: architecture
status: planned
tags: [state, flutter]
---

# State Management

Current state is mostly local to screens.

Near-term target:

- One repository/service for [[Transactions]].
- Dashboard, History, and Analytics read from it.
- Add/edit/delete write through it.

Future target:

- Repository abstracts local cache and [[Firebase Architecture]].

Related:

- [[Data Flow]]
- [[Repository Plan]]
- [[Phase 2 Real Expense Flow]]

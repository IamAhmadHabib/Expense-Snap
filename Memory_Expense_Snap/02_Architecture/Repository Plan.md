---
type: architecture
status: local-and-contract-ready
tags: [repository, transactions]
---

# Repository Plan

`TransactionRepository` is implemented as the local source of truth and now also implements a frontend contract for future sync.

Responsibilities:

- Create transaction.
- Update transaction.
- Delete transaction.
- List transactions.
- Provide derived totals for Dashboard/Analytics.
- List pending sync transactions.
- Map local transaction IDs to remote Firestore IDs.
- Mark sync failures using shared failure state.
- Preserve attachment IDs and sync metadata during serialization.

Future work:

- Replace the local no-op sync service with Firebase-backed sync.
- Decide whether remote-deleted transactions should be hidden immediately or shown as pending delete in admin/debug contexts.

Related:

- [[Transactions]]
- [[Transaction Model]]
- [[Data Flow]]
- [[Phase 2 Real Expense Flow]]

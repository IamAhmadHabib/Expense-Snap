---
type: feature
status: implemented-local-and-firestore
tags: [transactions, core]
---

# Transactions

Core app feature and data spine.

Implemented:

- Shared [[Repository Plan]] via `TransactionRepository`.
- Real save, edit, delete, and undo from [[Add Transaction]] and [[History]].
- Derived data and real-time reactive updates for [[Dashboard]], [[History]], and [[Analytics]].
- Cloud synchronization via `FirestoreTransactionSyncService` with last-write-wins and tombstone deletion.

Next:

- Attachment uploads via Firebase Storage.

Related:

- [[Transaction Model]]
- [[Data Flow]]
- [[Firebase Architecture]]
- [[Phase 2 Real Expense Flow]]

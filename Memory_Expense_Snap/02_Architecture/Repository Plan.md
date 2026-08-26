---
type: architecture
status: local-and-firestore-ready
tags: [repository, transactions]
---

# Repository Plan

`TransactionRepository` is implemented as the local source of truth and integrates with `AppSyncCoordinator` for cloud sync.

Responsibilities:

- Create transaction (`saveDraft`).
- Update transaction.
- Delete transaction (synchronous local delete + pending Firestore tombstone delete).
- Restore transaction (History Undo restores as pending upsert).
- List transactions.
- Provide derived totals for Dashboard/Analytics.
- List pending sync transactions.
- Map local transaction IDs to remote Firestore document IDs.
- Mark sync failures using shared failure state (`AppFailure`).
- Preserve attachment IDs, sync metadata (`syncState`, `lastSyncedAt`, `updatedAt`, `deletedAt`) during serialization.

Future work:

- Connect real file uploads via `AttachmentService` for receipt images and voice audio to Firebase Storage.
- Extend repository sync to handle multi-device streaming updates if real-time subscriptions are needed.

Related:

- [[Transactions]]
- [[Transaction Model]]
- [[Data Flow]]
- [[Firebase Architecture]]
- [[Phase 2 Real Expense Flow]]

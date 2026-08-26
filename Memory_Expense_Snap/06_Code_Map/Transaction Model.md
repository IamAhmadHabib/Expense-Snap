---
type: code-map
status: active
tags: [code, model, transactions]
---

# Transaction Model

Source:

```text
kharcha/lib/models/transaction.dart
```

Fields:

- `id`: Unique local identifier (UUID/timestamp string).
- `remoteId`: Maps the local transaction to a Firestore document ID.
- `merchant`: Merchant / store / recipient name.
- `category`: Spending category (normalized to primary groups).
- `amount`: Transaction amount.
- `date`: Expense date and time.
- `note`: Optional note text.
- `method`: Payment method ('Cash', 'Card', etc.).
- `source`: Capture source enum (`voice`, `scan`, `manual`).
- `isIncome`: Boolean flag for income vs expense.
- `syncState`: Sync status enum (`localOnly`, `synced`, `pendingUpsert`, `pendingDelete`, `failed`).
- `syncFailure`: Structured `AppFailure` for sync errors.
- `attachmentIds`: List of file IDs for attachments.
- `lastSyncedAt`: Timestamp of last successful remote sync.
- `updatedAt`: Timestamp for last-write-wins (LWW) conflict resolution in Firestore.
- `deletedAt`: Tombstone timestamp for soft deletion synchronization.

Phase 2 & C notes:

- Stable document IDs prevent duplicate expenses on retry.
- `updatedAt` ensures newer client edits defeat stale remote writes.
- `deletedAt` tombstones ensure offline deletes propagate without being overwritten by older updates.
- JSON serialization is backward-compatible with older local transactions.

Related:

- [[Transactions]]
- [[Repository Plan]]
- [[Data Flow]]
- [[Firebase Architecture]]

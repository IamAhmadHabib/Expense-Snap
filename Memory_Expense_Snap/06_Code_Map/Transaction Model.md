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

- id
- remoteId
- merchant
- category
- amount
- date
- note
- method
- source
- isIncome
- syncState
- syncFailure
- attachmentIds
- lastSyncedAt

Phase C notes:

- `remoteId` maps the local transaction to a future Firestore document ID.
- `syncState` tracks local-only, pending create/update/delete, synced, and failed states.
- `syncFailure` stores a structured retryable/non-retryable failure.
- `attachmentIds` prepares receipt/screenshot/voice attachment links for Firebase Storage.
- JSON serialization is backward-compatible with older local transactions that do not have these fields.

Related:

- [[Transactions]]
- [[Repository Plan]]
- [[Data Flow]]

---
type: code-map
status: active
tags: [code, transactions]
---

# Add Transaction Code

Source:

```text
kharcha/lib/features/transactions/add_transaction_sheet.dart
```

Current note: `_saveDraft` constructs a `TransactionDraft` and persists it to `TransactionRepository.saveDraft(...)`. If Firebase is enabled, it automatically triggers `AppSyncCoordinator.syncNow()`. `AddTransactionTab` selects the initial Manual, Scan, or Voice mode; new-entry default is Voice and edit default is Manual.

Manual layout note: the form is always vertically scrollable so its Save Expense action remains reachable across phone heights and keyboard states.

Related:

- [[Add Transaction]]
- [[Voice Tab]]
- [[Scan Tab]]
- [[Manual Tab]]
- [[Transactions]]

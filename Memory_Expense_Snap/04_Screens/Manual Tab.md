---
type: screen-section
status: connected
tags: [manual, transactions]
---

# Manual Tab

Fast manual entry path with amount, category, date/time, payment method, note, and save button.

Implemented flow: saves through [[Repository Plan]] into [[Transactions]] via `TransactionRepository.saveDraft(...)` and updates Dashboard/History/Analytics immediately.

Related:

- [[Add Transaction]]
- [[Transactions]]
- [[Repository Plan]]
- [[Phase 2 Real Expense Flow]]

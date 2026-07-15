---
type: screen
status: ui-built-needs-data
tags: [screen, transactions]
---

# Add Transaction

Bottom sheet for adding expenses.

Tabs:

- [[Voice Tab]]
- [[Scan Tab]]
- [[Manual Tab]]

Confirmed live-code gaps:

- The sheet currently opens on Manual, despite Voice being the intended default behavior.
- Manual save waits and closes with `true` but does not build or save a `Transaction`.
- Voice permission, capture, parsing, and result data are simulated; Voice save closes without returning a saved transaction result.
- Scan permission, capture, OCR, and extracted result data are simulated; Scan save closes the sheets without building or saving a transaction.
- Edit mode pre-fills fields but History does not receive or apply an updated transaction.

All three capture modes need to produce the same transaction draft/save contract through [[Repository Plan]].

Related:

- [[Add Transaction Code]]
- [[Phase 2 Real Expense Flow]]

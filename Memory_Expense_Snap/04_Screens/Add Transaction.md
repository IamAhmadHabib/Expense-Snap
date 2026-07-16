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

- Manual save waits and closes with `true` but does not build or save a `Transaction`.
- Voice permission, capture, parsing, and result data are simulated; Voice save closes without returning a saved transaction result.
- Scan permission, capture, OCR, and extracted result data are simulated; Scan save closes the sheets without building or saving a transaction.
- Edit mode pre-fills fields but History does not receive or apply an updated transaction.

Connected shell behavior:

- New transactions default to [[Voice Tab]].
- Dashboard Voice, Scan, and Manual actions select the requested initial tab.
- History edit mode opens [[Manual Tab]].
- The Manual form is vertically scrollable even when the keyboard is closed, keeping the complete Save Expense action reachable on shorter phones.
- Voice hint cycling uses a lifecycle-safe timer that is cancelled when the sheet is disposed.
- Capture pages are built through a lazy `PageView.builder`, wrapped in repaint isolation, and inactive capture pages have tickers disabled so Voice/Scan animation work does not continue while Manual is active.
- Confirm Amount returns to the active tab page after closing the numpad, preserving the user's Manual/Voice/Scan context.

All three capture modes need to produce the same transaction draft/save contract through [[Repository Plan]].

Related:

- [[Add Transaction Code]]
- [[Phase 2 Real Expense Flow]]

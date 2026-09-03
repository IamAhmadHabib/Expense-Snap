---
type: screen
status: repository-connected
tags: [screen, transactions]
---

# Add Transaction

Bottom sheet for adding expenses.

Tabs:

- [[Voice Tab]]
- [[Scan Tab]]
- [[Manual Tab]]

Implemented live-code capabilities:

- Manual save builds a `TransactionDraft` and persists via `_repository.saveDraft(...)`.
- Voice save flows through `_saveDraft` to create a `TransactionDraft` and persists into `TransactionRepository`.
- Scan save flows through `_saveDraft` to create a `TransactionDraft` and persists into `TransactionRepository`.
- Edit mode pre-fills existing transaction values and updates the existing `Transaction` in `TransactionRepository`.
- Any save or edit instantly triggers `AppSyncCoordinator.syncNow()` in the background if Firebase is active.

Connected shell behavior:

- New transactions default to [[Voice Tab]].
- Dashboard Voice, Scan, and Manual actions select the requested initial tab.
- History edit mode opens [[Manual Tab]].
- The Manual form is vertically scrollable even when the keyboard is closed, keeping the complete Save Expense action reachable on shorter phones.
- Voice hint cycling uses a lifecycle-safe timer that is cancelled when the sheet is disposed.
- Capture pages are built through a lazy `PageView.builder`, wrapped in repaint isolation, and inactive capture pages have tickers disabled so Voice/Scan animation work does not continue while Manual is active.
- Confirm Amount returns to the active tab page after closing the numpad, preserving the user's Manual/Voice/Scan context.
- Category picker in the Manual form uses 24px filled icons (`PhosphorIconsStyle.fill`) with mature metaphors (`forkKnife`, `carSimple`, `tote`, `ticket`, `firstAidKit`, `receipt`, `bookOpen`, `basket`, `airplaneTilt`, `tag`).
- Category selection highlights with the matching pastel tint, accent border, and subtle glow rather than turning into a solid black block.

Remaining integrations:

- Connect real Gemini API for voice natural language parsing.
- Connect real ML Kit / Google Cloud Vision for OCR receipt image parsing.

Related:

- [[Add Transaction Code]]
- [[Repository Plan]]
- [[Phase 2 Real Expense Flow]]
- [[Color Tokens]]
- [[Design System]]
- [[Dashboard]]
- [[History]]

---
type: snapshot
status: active
updated: 2026-07-15
tags: [current-state, snapshot]
---

# Current Snapshot

Kharcha currently has a high-fidelity Flutter UI but not yet a real backend/data spine.

## Implemented UI

- [[Onboarding]]
- [[Auth Login]]
- [[Personalization]]
- [[Dashboard]]
- [[Add Transaction]]
- [[Voice Tab]]
- [[Scan Tab]]
- [[Manual Tab]]
- [[Analytics]]
- [[History]]
- [[Profile]]

## Current Gaps

- [[Notifications Screen]] not connected.
- Dashboard avatar not connected to [[Profile]].
- Dashboard Voice, Scan, and Manual quick-action cards are visual only.
- Dashboard tab switching rebuilds tab screens, so screen-local History, Analytics, and Profile state resets after leaving a tab.
- [[Transactions]] are not persisted.
- [[Add Transaction]] defaults to Manual in live code and its Manual, Voice, and Scan save paths do not produce a real `Transaction`.
- [[History]] uses mock data.
- [[Analytics]] uses mock data.
- [[Dashboard]] does not refresh from saved expenses.
- Several [[Profile]] pickers and actions are sheet-local or no-op, so displayed profile/settings values do not update reliably.
- [[Firebase Architecture]] is planned, not implemented.
- [[Gemini Voice]] is planned, not implemented.
- [[OCR Scanning]] is planned, not implemented.
- [[Design Debt]] includes hardcoded colors and platform launch colors.

## Best Next Move

Finish the small [[Phase 1 UI Shell]] connection and tab-state fixes, then build one observable local transaction source for [[Add Transaction]], [[Dashboard]], [[History]], and [[Analytics]] in [[Phase 2 Real Expense Flow]].

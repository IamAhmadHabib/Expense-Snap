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
- [[Transactions]] are not persisted.
- [[History]] uses mock data.
- [[Analytics]] uses mock data.
- [[Dashboard]] does not refresh from saved expenses.
- [[Firebase Architecture]] is planned, not implemented.
- [[Gemini Voice]] is planned, not implemented.
- [[OCR Scanning]] is planned, not implemented.
- [[Design Debt]] includes hardcoded colors and platform launch colors.

## Best Next Move

Work on [[Phase 2 Real Expense Flow]] after the small [[Phase 1 UI Shell]] connection fixes.

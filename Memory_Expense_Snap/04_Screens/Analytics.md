---
type: screen
status: ui-built-mock-data
tags: [screen, analytics]
---

# Analytics

Purpose: turn raw spending into insight.

Confirmed live-code gaps:

- Line, category, active-stat, heatmap, and insight data are mock or deterministically random local values.
- The detailed breakdown overlay exists but has no code path that opens it.
- Period and activity selections reset when the Dashboard shell rebuilds this tab.

All derived data should come from [[Transactions]] through shared selectors/aggregation logic.

Related:

- [[Analytics Code]]
- [[Analytics Intelligence]]
- [[Data Flow]]
- [[Phase 2 Real Expense Flow]]

---
type: screen
status: local-data-connected
tags: [screen, analytics]
---

# Analytics

Purpose: turn raw spending into insight.

Current live-code behavior:

- Main trend chart, total expenditure, category distribution, and activity matrix read from the shared local transaction repository.
- Average Spending is displayed as average per real expense in the selected period, not average per chart bucket.
- Dynamic Peak Period calculation (`_getPeakStat()`): peak 4-hour window for Days (Today), peak weekday for Weeks (Monthly), and peak month for Months (Yearly) with exact spending totals.
- Dynamic Period Trend Delta (`_getTrendDelta()`): real percentage difference comparing current vs previous period spending with dynamic up/down badge styling.
- Smooth chart auto-scaling (`_getMaxY()`) handles small amounts (< Rs. 1,000) smoothly without flattening data.
- Category distribution uses normalized groups, so Dining/Food/Food & Dining roll up under Food.
- Category legend is stacked under the radial chart to avoid clipping labels on mobile widths.
- Main chart, distribution, heatmap, and insight sections are wrapped in repaint isolation.
- `RadialBarPainter.shouldRepaint` compares values/colors instead of repainting unconditionally.

Remaining gaps:

- The detailed breakdown overlay exists but has no direct code path that opens it.
- Period and activity selections reset when the Dashboard shell rebuilds this tab.

All remaining derived analytics should come from [[Transactions]] through shared selectors/aggregation logic.

Related:

- [[Analytics Code]]
- [[Analytics Intelligence]]
- [[Data Flow]]
- [[Phase 2 Real Expense Flow]]

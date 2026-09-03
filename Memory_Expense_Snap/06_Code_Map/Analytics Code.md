---
type: code-map
status: active
tags: [code, analytics]
---

# Analytics Code

Source:

```text
kharcha/lib/features/analytics/analytics_screen.dart
```

Current architecture:
- Reads live transactions from `TransactionRepository`.
- Computes trend line chart spots with dynamic auto-scaling via `_getLineChartSpots()` and `_getMaxY()`.
- Calculates dynamic period-over-period trend delta percentages via `_getTrendDelta()`.
- Computes period-aware peak periods and expenditure via `_getPeakStat()`.
- Groups category expenditure into normalized categories via `_getCategoryData()`.
- Computes 30-day activity matrix spending heatmap from real transaction dates.

Related:

- [[Analytics]]
- [[Analytics Intelligence]]
- [[Data Flow]]

---
type: screen
status: ui-built-needs-connections
tags: [screen, dashboard]
---

# Dashboard

Home base for Kharcha.

Current gaps:

- Avatar should route to [[Profile]].
- Notification bell should route to [[Notifications Screen]].
- Voice, Scan, and Manual quick-action cards have no tap handlers.
- Budget, weekly velocity, and top-spending values are hardcoded.
- The shell uses a switch instead of retained tab children, so History, Analytics, and Profile screen-local state resets on tab changes.
- Budget/spend data should come from [[Transactions]].

Related:

- [[Dashboard Code]]
- [[Data Flow]]
- [[Budgeting]]
- [[Phase 1 UI Shell]]
- [[Phase 2 Real Expense Flow]]

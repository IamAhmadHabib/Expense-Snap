---
type: screen
status: ui-built-connected-needs-data
tags: [screen, dashboard]
---

# Dashboard

Home base for Kharcha.

Connected behavior:

- Avatar routes to [[Profile]].
- Notification bell routes to [[Notifications Screen]].
- Voice, Scan, and Manual quick-action cards open their matching capture modes.
- The center add action opens Voice capture.
- Weekly velocity three-dot action opens [[Analytics]].
- Top Spending "See all" opens [[History]].
- Top Spending cards now render as up to five static vertical capsules in the main Dashboard page scroll instead of using an internal horizontal or vertical carousel.
- The extra internal bottom spacer under Top Spending was removed; the main screen still keeps bottom padding for the floating dock.
- Weekly velocity card height now accommodates the 48px analytics action target plus a full-height real spending bar without RenderFlex overflow.
- Dashboard now uses a cached page-based retained tab shell for smoother navigation instead of laying out all major tabs on every tab switch.
- Tab page widgets are cached between dock taps, adjacent tabs are implicitly warmed, and already-built tab pages use keep-alive wrappers so repeat navigation does not reconstruct the full screen.
- Major Dashboard cards are wrapped in repaint isolation to reduce unnecessary repaint work during navigation and repository updates.
- System back from Analytics, History, or Profile returns to Dashboard Home instead of leaving the authenticated shell.

Performance note:

- Add Transaction opening no longer performs an extra Dashboard-level dim overlay before the modal route appears; the modal route keeps the visual scrim/blur treatment.

Current data gaps:

- Budget planning still needs richer real-budget behavior beyond the local monthly budget value.
- Backend sync is still pending; current Dashboard spend summaries come from the local transaction repository.

Related:

- [[Dashboard Code]]
- [[Data Flow]]
- [[Budgeting]]
- [[Phase 1 UI Shell]]
- [[Phase 2 Real Expense Flow]]

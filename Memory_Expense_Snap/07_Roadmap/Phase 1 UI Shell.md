---
type: phase
status: complete
tags: [phase, ui-shell]
---

# Phase 1 UI Shell

Goal: connect the existing UI shell without changing visual identity.

Completed:

- Dashboard avatar routes to [[Profile]].
- Notification bell routes to the implemented [[Notifications Screen]].
- Dashboard quick actions and center add action open the intended [[Add Transaction]] modes.
- Dashboard tab state is retained across tab switches.
- Profile Log Out opens its confirmation sheet.
- Feature hardcoded colors were consolidated into [[Color Tokens]].
- Android, iOS, and web launch surfaces use the warm Kharcha background.
- Widget regression tests cover shell navigation, initial capture modes, retained state, logout confirmation, and launch colors.

Next: [[Phase 2 Real Expense Flow]].

Related:

- [[Dashboard]]
- [[Design Debt]]
- [[Open Tasks]]

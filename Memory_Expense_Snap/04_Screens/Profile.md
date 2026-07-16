---
type: screen
status: ui-built
tags: [screen, profile]
---

# Profile

Profile and settings screen.

Includes:

- Header card.
- Personal info.
- Budget settings.
- Currency.
- Notification toggles.
- App settings.
- Logout/Delete Account.

Confirmed live-code gaps:

- Header identity, stats, budget, currency, language, and reset-day display values are hardcoded.
- Notification and dark-mode toggles are local in-memory state. They now survive Dashboard tab switches, but are not persisted across app restarts; dark mode does not change the app theme.
- Edit name, budget, currency, category creation, language, rating, and feedback sheets do not return/apply durable values.
- Avatar edit is haptic-only. Log Out opens its existing confirmation sheet, but confirmed logout is not connected to an auth session. Delete Forever has an empty callback.
- Performance/lifecycle note: the delayed stats animation timer is now cancelled on dispose, and the profile header plus main settings sections have repaint isolation.
- Currency picker opens with the currently persisted currency selected instead of always defaulting to PKR.

Related:

- [[Profile Code]]
- [[Profile Settings]]
- [[Budgeting]]
- [[Phase 3 Profile Budget State]]

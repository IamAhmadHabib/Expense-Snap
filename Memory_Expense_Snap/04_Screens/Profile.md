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
- Notification and dark-mode toggles are local state and reset after leaving the tab; dark mode does not change the app theme.
- Edit name, budget, currency, category creation, language, rating, and feedback sheets do not return/apply durable values.
- Avatar edit is haptic-only, Log Out is not connected to its existing confirmation sheet, and Delete Forever has an empty callback.

Related:

- [[Profile Code]]
- [[Profile Settings]]
- [[Budgeting]]
- [[Phase 3 Profile Budget State]]

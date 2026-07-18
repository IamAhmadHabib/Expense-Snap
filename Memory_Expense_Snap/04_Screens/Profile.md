---
type: screen
status: ui-built
tags: [screen, profile]
---

# Profile

Profile and settings screen.

Includes:

- Fixed `My Profile` header with a compact inset charcoal identity/stat card. The header uses the same top SafeArea pattern as Analytics so its title clears the system status bar before the card begins. Profile settings cards use compact rows; the App card keeps a small top/bottom inset around its first and last rows.
- Personal info.
- Budget settings.
- Currency.
- Notification toggles.
- App settings.
- Logout/Delete Account.

Confirmed live-code gaps:

- Header identity/email and stats are repository-backed. The email is synchronized from Firebase Auth through `AppSettingsRepository`.
- Notification and dark-mode toggles are local in-memory state. They now survive Dashboard tab switches, but are not persisted across app restarts; dark mode does not change the app theme.
- Edit name, budget, currency, category creation, language, rating, and feedback sheets do not return/apply durable values.
- Avatar edit is haptic-only. Confirmed Log Out now calls the shared `AuthService`, then clears navigation back to onboarding. Delete Forever has an empty callback.
- Performance/lifecycle note: the delayed stats animation timer is now cancelled on dispose, and the profile header plus main settings sections have repaint isolation.
- Currency picker opens with the currently persisted currency selected instead of always defaulting to PKR.

Related:

- [[Profile Code]]
- [[Profile Settings]]
- [[Budgeting]]
- [[Phase 3 Profile Budget State]]

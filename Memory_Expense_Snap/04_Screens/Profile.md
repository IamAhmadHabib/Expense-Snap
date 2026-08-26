---
type: screen
status: repository-connected
tags: [screen, profile]
---

# Profile

Profile and settings screen.

Includes:

- Fixed `My Profile` header with a compact inset charcoal identity/stat card.
- Personal info (Name, Email synchronized from Firebase Auth/local session).
- Budget settings (Monthly budget, Reset day, Categories).
- Currency selection.
- Notification toggles (Weekly digest, Budget alerts, Spending insights, Daily reminder).
- App settings (Language, Dark Mode toggle, Rating, Feedback, Version).
- Logout confirmation & Danger Zone.

Implemented live-code capabilities:

- Header identity, email, and stats are repository-backed (`AppSettingsRepository` & `TransactionRepository`).
- Full Name, Monthly Budget, Budget Reset Day, Currency, Language, and Notification preferences are durably persisted in `AppSettingsRepository` and synced to Firestore.
- Dark mode toggle updates persisted `AppSettings` (full dynamic theme switching is in progress).
- Confirmed Log Out calls `AuthService.signOut()` and resets navigation back to Onboarding.
- The delayed stats animation timer is lifecycle-safe (cancelled on dispose), and major cards use repaint isolation.
- Currency picker opens initialized with the currently persisted currency.

Remaining gaps:

- Rating and Feedback actions open modals but do not dispatch store reviews or external emails yet.
- Delete Forever action currently has an empty callback.

Related:

- [[Profile Code]]
- [[Profile Settings]]
- [[Budgeting]]
- [[Phase 3 Profile Budget State]]

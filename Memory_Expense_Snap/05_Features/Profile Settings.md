---
type: feature
status: implemented-local-and-firestore
tags: [profile, settings]
---

# Profile Settings

Profile settings are durably persisted in `AppSettingsRepository` and synchronized to Firestore.

Includes:

- Name & profile email (hydrated from Firebase Auth session).
- Monthly Budget & Reset Day.
- Currency selection.
- Notification toggles (Weekly digest, Budget alerts, Spending insights, Daily reminder).
- Language & dark mode preferences.

Related:

- [[Profile]]
- [[Budgeting]]
- [[Firebase Architecture]]
- [[Phase 3 Profile Budget State]]

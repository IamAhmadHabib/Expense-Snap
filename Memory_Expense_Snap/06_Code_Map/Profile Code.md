---
type: code-map
status: active
tags: [code, profile]
---

# Profile Code

Source:

```text
kharcha/lib/features/profile/profile_screen.dart
```

Current shell note: Profile binds directly to `AppSettingsRepository` and `TransactionRepository`. Name, budget, currency, reset day, language, and notification settings persist durably and trigger background sync. Confirmed Log Out executes `AuthService.signOut()` and resets navigation to Onboarding.

Related:

- [[Profile]]
- [[Profile Settings]]
- [[Budgeting]]
- [[Firebase Architecture]]
- [[Design Debt]]

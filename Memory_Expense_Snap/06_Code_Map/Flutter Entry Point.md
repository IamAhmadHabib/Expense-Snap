---
type: code-map
status: active
tags: [code, entry]
---

# Flutter Entry Point

Source:

```text
kharcha/lib/main.dart
```

Current behavior:

- Initializes `FirebaseBootstrap` (guarded by `KHARCHA_FIREBASE_ENABLED`).
- Runs `KharchaBootstrap.local()` to create local repositories (`TransactionRepository`, `AppSettingsRepository`), resolve active session via `AuthService`, and initialize `AppSyncCoordinator`.
- Injects dependencies into the widget tree via `RepositoryScope`.
- Applies warm theme and dynamically chooses initial route based on session state (`DashboardScreen` if authenticated/existing session, else `OnboardingScreen`).

Related:

- [[Navigation Map]]
- [[Onboarding]]
- [[Dashboard]]
- [[Theme Layer]]

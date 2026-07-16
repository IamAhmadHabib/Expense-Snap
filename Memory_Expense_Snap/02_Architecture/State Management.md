---
type: architecture
status: local-and-contract-ready
tags: [state, flutter]
---

# State Management

Core expense state now lives in repositories injected through `RepositoryScope`.

Current state:

- `TransactionRepository` stores local transactions and sync metadata.
- `AppSettingsRepository` stores personalization/profile settings.
- `RepositoryScope` injects repositories plus `AppServices`.
- `KharchaBootstrap` creates the repositories/services and restores the session route.
- Dashboard, History, Analytics, and Profile listen to repository changes.

Future target:

- Firebase-backed services implement the existing auth, sync, attachment, voice, and OCR contracts.

Related:

- [[Data Flow]]
- [[Repository Plan]]
- [[Phase 2 Real Expense Flow]]

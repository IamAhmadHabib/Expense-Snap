---
type: architecture
status: active
tags: [architecture, overview]
---

# Architecture Overview

Current app: Local-first Flutter architecture with optional Firebase cloud sync under `kharcha/`.

Implemented architecture:

[[Feature Screens]] → `RepositoryScope` → `TransactionRepository` & `AppSettingsRepository` → `LocalKeyValueStore` (SharedPreferences / InMemory) + `AppSyncCoordinator` (`FirestoreTransactionSyncService` / Local fake).

Next target:

Firebase Storage attachment uploads, Gemini Voice integration, and ML Kit OCR parsing behind the existing service contracts.

Related:

- [[Navigation Map]]
- [[Data Flow]]
- [[State Management]]
- [[Repository Plan]]
- [[Firebase Architecture]]
- [[Integrations]]

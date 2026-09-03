---
type: product
status: active
tags: [current-state]
---

# Current State

See [[Current Snapshot]] for the current project truth.

Summary:

- High-fidelity Flutter UI is fully built and connected.
- Local-first data spine (`TransactionRepository`, `AppSettingsRepository`, `LocalKeyValueStore`) is complete.
- Firebase Phase 1 (Auth: Email/Password & Google OAuth) and Phase 2 (Firestore real-time/offline sync with LWW and tombstone deletion) are implemented.
- Firebase Phase 1 & 2 (Auth & Firestore sync), Phase 4 (Firebase Storage attachments), and Phase 5 (Gemini Voice parsing & native Android widget overlay) are implemented.
- ML Kit OCR scanning and export integrations remain planned.

Related:

- [[Architecture Overview]]
- [[Firebase Architecture]]
- [[Current Snapshot]]
- [[Open Tasks]]

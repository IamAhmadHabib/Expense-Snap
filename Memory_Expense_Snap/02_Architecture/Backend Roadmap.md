---
type: architecture
status: in-progress
tags: [backend, roadmap]
---

# Backend Roadmap

Backend foundation (Phase 1 Auth & Phase 2 Firestore sync) is implemented behind Phase C service contracts.

Backend status:

- [[Firebase Architecture]]
- Firebase Auth (Google OAuth & Email/Password) — **Implemented**.
- Firestore transaction and settings sync (LWW conflict resolution & tombstones) — **Implemented**.
- Firebase Storage for receipts/attachments — **Planned (Next)**.
- Firebase Cloud Messaging for alerts/insights — **Planned**.
- Gemini API for voice parsing — **Planned**.
- ML Kit OCR for receipt/screenshot scanning — **Planned**.
- Google Sheets API sync — **Planned**.
- CSV/PDF export — **Planned**.

Frontend readiness already added:

- `AuthService` and session routing via `KharchaBootstrap`.
- `TransactionSyncService` contract with `FirestoreTransactionSyncService` implementation.
- `AttachmentService` contract for local and future uploaded attachments.
- `PermissionService` contract for microphone/camera/photos/notifications.
- Voice and OCR parser adapter contracts with correction workflow models.

Related:

- [[Phase 4 Firebase Backend]]
- [[Phase 5 Gemini Voice]]
- [[Phase 6 OCR]]
- [[Phase 8 Export Sync]]

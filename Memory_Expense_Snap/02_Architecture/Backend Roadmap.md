---
type: architecture
status: planned
tags: [backend, roadmap]
---

# Backend Roadmap

Backend is planned but not implemented. The frontend now has Phase C contracts and local fake services ready for backend integration.

Target backend:

- [[Firebase Architecture]]
- Firebase Auth.
- Firestore.
- Firebase Storage.
- Firebase Cloud Messaging.
- Gemini API.
- ML Kit OCR.
- Google Sheets API.
- CSV/PDF export.

Frontend readiness already added:

- `AuthService` and session routing via `KharchaBootstrap`.
- `TransactionSyncService` contract plus transaction sync metadata.
- `AttachmentService` contract for local and future uploaded attachments.
- `PermissionService` contract for microphone/camera/photos/notifications.
- Voice and OCR parser adapter contracts with correction workflow models.

Related:

- [[Phase 4 Firebase Backend]]
- [[Phase 5 Gemini Voice]]
- [[Phase 6 OCR]]
- [[Phase 8 Export Sync]]

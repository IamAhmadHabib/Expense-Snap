---
type: phase
status: frontend-ready
tags: [phase, firebase]
---

# Phase 4 Firebase Backend

Goal: real account-backed persistence.

Frontend readiness in place:

- App bootstrap restores a session and chooses onboarding/dashboard route.
- `AuthService` contract exists for Firebase Auth replacement.
- `TransactionRepository` stores remote IDs and sync state.
- `TransactionSyncService` contract exists for Firestore sync.
- `AttachmentService` contract exists for Firebase Storage upload mapping.

Next implementation work:

- Add Firebase packages/config.
- Implement Firebase-backed auth service.
- Implement Firestore transaction/settings sync behind the existing contracts.
- Implement Storage-backed attachment upload behind the existing attachment contract.

Related:

- [[Firebase Architecture]]
- [[Auth Feature]]
- [[Transactions]]

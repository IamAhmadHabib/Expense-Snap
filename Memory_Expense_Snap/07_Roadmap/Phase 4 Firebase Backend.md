---
type: phase
status: phase-2-firestore-code-ready
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
- Firebase packages and a safe startup bootstrap are now in place.
- Firebase initialization is guarded by `KHARCHA_FIREBASE_ENABLED`, so local development/tests do not require real Firebase credentials yet.
- Firebase project `kharcha-expense-snap` and Android/iOS Firebase app configs are now in place.
- `FirebaseAuthService` exists behind `AuthService`.
- `FirestoreTransactionSyncService`, local-first transaction/settings sync coordination, remote-ID mapping, and owner-only Firestore rules are implemented in code.

Completed:

- Add Firebase packages.
- Add disabled-by-default Firebase bootstrap.
- Create fresh Firebase project `kharcha-expense-snap`.
- Add Android/iOS Firebase app config files and generated `firebase_options.dart`.
- Implement Firebase-backed auth service for anonymous and email/password auth.
- Wire Login screen to email/password auth through `AuthService`.
- Add a bootstrap guard test.
- Add Firestore sync coordinator contract coverage.
- Verify a real Google-authenticated Android device can create, update, delete, undo-delete, and restore transactions across restart, with profile/settings sync.
- Queue an Undo after a completed remote delete as a Firestore upsert using the transaction's stable document ID.
- Apply version-one Firestore conflict handling: `updatedAt` last-write-wins and `deletedAt` tombstones that defeat stale updates.
- Sync Firebase Auth email/display name through the local `AppSettingsRepository` profile model after first pulling cloud settings, and remove the Profile screen's hardcoded email.

Next implementation work:

- Implement Storage-backed attachment upload behind the existing attachment contract.

Related:

- [[Firebase Architecture]]
- [[Auth Feature]]
- [[Transactions]]

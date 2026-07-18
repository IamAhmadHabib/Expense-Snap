---
type: architecture
status: phase-2-firestore-code-ready
tags: [firebase, backend]
---

# Firebase Architecture

Planned Firebase services:

- Auth for Google, Apple, Email.
- Firestore for transactions, budgets, categories, profile/settings.
- Storage for receipts and scanned images.
- FCM for reminders, budget alerts, weekly digest, spending insights.

Phase 0 implemented:

- Flutter Firebase packages are installed in `kharcha/pubspec.yaml`.
- `FirebaseBootstrap.initialize()` is called during app startup.
- Firebase is disabled by default through `KHARCHA_FIREBASE_ENABLED`.
- Firebase project `kharcha-expense-snap` was created under `ahmadhabib2005@gmail.com`.
- Android app `com.kharcha.kharcha` is registered as `1:292863323201:android:9546dd978bf00251c0eac0`.
- iOS app `com.kharcha.kharcha` is registered as `1:292863323201:ios:14650d3f513e114ec0eac0`.
- `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart` point to `kharcha-expense-snap`.
- Local app behavior remains the default runtime unless Firebase is enabled with `KHARCHA_FIREBASE_ENABLED=true`.

Phase 1 implemented:

- `FirebaseAuthService` implements the `AuthService` contract using Firebase Auth.
- Email/password login is wired through the existing Login UI and routes to Dashboard on success.
- Local auth still satisfies the same contract for tests and offline/local development.

Phase 2 implemented:

- `FirestoreTransactionSyncService` stores data under `users/{uid}/transactions/{localTransactionId}` and `users/{uid}` for settings.
- Transaction document IDs are stable local IDs, making retries idempotent and preventing duplicate expenses.
- `AppSyncCoordinator` preserves local-first behavior: save/edit/delete/undo/settings update locally, then start a background sync when Firebase services are active.
- Remote transaction records are merged only when the local record has no pending local change.
- `firestore.rules` restricts every user document and transaction subcollection to its matching authenticated Firebase UID.
- Live Android verification confirmed Google-authenticated create, update, delete, restart restore, settings sync, and profile/budget sync against the deployed owner-only rules.
- A History Undo after a completed remote delete restores the transaction as a pending upsert with the same stable document ID, recreating the Firestore record on the next sync.
- Sync requests made during an active pass are coalesced into a follow-up pass. Remote delete completion only removes a transaction that is still `pendingDelete`, protecting an immediate Undo from an in-flight delete race.
- Version-one conflict policy is complete: transaction writes use `updatedAt` last-write-wins checks inside Firestore transactions, and deletes write `deletedAt` tombstones. A tombstone wins over older updates; a newer Undo/edit clears it and recreates the transaction.

Phase 4 implemented:

- `AppSettingsRepository` remains the single source of truth for local-first name, budget, currency, categories, and notification preferences.
- Firebase Auth supplies the signed-in email and display name. Bootstrap pulls existing cloud settings first, then fills missing identity fields and performs a background settings sync, preventing a fresh install from overwriting another device's settings.
- Profile displays the synced Auth-backed email instead of a hardcoded address; profile statistics remain derived from local transactions.

Next:

- Enable Email/Password sign-in in Firebase Console if it is not already enabled.
- Add Firebase Storage-backed attachment upload.

Related:

- [[Auth Feature]]
- [[Transactions]]
- [[Budgeting]]
- [[Notifications Feature]]
- [[Phase 4 Firebase Backend]]

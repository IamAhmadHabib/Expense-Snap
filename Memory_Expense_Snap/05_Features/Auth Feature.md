---
type: feature
status: firebase-service-ready
tags: [auth, firebase]
---

# Auth Feature

Current:

- Auth UI exists.
- Firebase project `kharcha-expense-snap` exists.
- `FirebaseAuthService` implements `AuthService`.
- Login button uses `AuthService.signInWithEmail()` and navigates to Dashboard on success.
- Continue with Google now uses `AuthService.signInWithGoogle()`: local mode provides a deterministic local session, while Firebase mode signs in with Google OAuth and exchanges the credential with Firebase Auth.
- Firebase runtime is guarded by `KHARCHA_FIREBASE_ENABLED=true`; local auth remains default for tests/local development.

Still planned:

- Apple sign-in.
- Account creation UI and password reset wiring.
- Confirm Email/Password provider is enabled in Firebase Console.

Related:

- [[Auth Login]]
- [[Firebase Architecture]]
- [[Phase 4 Firebase Backend]]

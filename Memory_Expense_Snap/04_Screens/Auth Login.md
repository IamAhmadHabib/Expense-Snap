---
type: screen
status: auth-connected
tags: [screen, auth]
---

# Auth Login

Purpose: let users enter through Google, Apple, or Email.

Current state:

- `AuthScreen` is wired to Google Sign-In (`AuthService.signInWithGoogle()`).
- `LoginScreen` is wired to Email/Password authentication (`AuthService.signInWithEmail()`).
- Both flows route to Dashboard on successful authentication.
- Local fake auth serves as fallback during offline or test runs; Firebase auth takes over when `KHARCHA_FIREBASE_ENABLED=true`.

Related:

- [[Auth Feature]]
- [[Firebase Architecture]]
- [[Auth Code]]
- [[Personalization]]

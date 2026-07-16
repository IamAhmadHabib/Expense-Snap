---
type: tasks
status: active
tags: [sprint]
---

# Next Sprint

Recommended sprint:

1. Add Firebase packages/config for Android and iOS.
2. Implement Firebase-backed `AuthService` behind the existing Phase C interface.
3. Implement Firestore-backed transaction/settings sync using `remoteId`, `syncState`, and `syncFailure`.
4. Implement Firebase Storage upload behind `AttachmentService`.
5. Add integration tests using fake Firebase-style services before touching real network calls.

Sprint outcome: local expenses can map to account-scoped remote records without changing the current UI design.

Related:

- [[Open Tasks]]
- [[Decision Log]]

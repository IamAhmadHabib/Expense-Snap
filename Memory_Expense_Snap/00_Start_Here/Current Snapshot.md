---
type: snapshot
status: active
updated: 2026-07-18
tags: [current-state, snapshot]
---

# Current Snapshot

Kharcha currently has a high-fidelity Flutter UI with a local-first, Firebase-synced expense spine. Storage, Gemini, OCR, and other backend integrations are still pending.

## Implemented UI

- [[Onboarding]]
- [[Auth Login]]
- [[Personalization]]
- [[Dashboard]]
- [[Add Transaction]]
- [[Voice Tab]]
- [[Scan Tab]]
- [[Manual Tab]]
- [[Analytics]]
- [[History]]
- [[Profile]]
- [[Notifications Screen]]

## Connected UI Shell

- [[Onboarding]] now uses three transparent PNG illustrations with a persistent viewport, overlapping 900 ms page transitions, synchronized text/indicator motion, rapid-tap locking, retained swipe/Skip/Get Started behavior, image precaching, responsive sizing, meaningful illustration semantics, and a reduced-motion cross-fade.
- Dashboard avatar opens [[Profile]].
- Dashboard notification bell opens [[Notifications Screen]] and system back returns to Home.
- Dashboard Voice, Scan, and Manual quick actions open the matching [[Add Transaction]] mode.
- Dashboard weekly velocity three-dot action opens [[Analytics]].
- Dashboard Top Spending "See all" opens [[History]].
- Dashboard Top Spending shows up to five static vertical capsules in the main page scroll; the full list remains available through [[History]] via "See all".
- The center add action opens [[Voice Tab]], while History edits open [[Manual Tab]].
- Dashboard tab children are retained, so screen-local state survives tab switches.
- System back from [[Analytics]], [[History]], or [[Profile]] selects Dashboard Home instead of popping to authentication.
- The [[Manual Tab]] form remains vertically scrollable without the keyboard, so Save Expense is reachable on shorter phone viewports.
- Manual saves, simulated Voice saves, and simulated Scan saves now flow through the same local transaction repository.
- Dashboard, History, Analytics, and Profile listen to shared local transaction/settings repositories.
- App startup now goes through `KharchaBootstrap`, which creates repositories, restores the local session, injects `AppServices`, and chooses the initial session route.
- `RepositoryScope` now carries repositories plus backend-readiness services for auth, permissions, attachments, voice parsing, OCR parsing, and transaction sync.
- `Transaction` now stores remote ID, sync state, sync failure, attachment IDs, and last-synced timestamp for future Firebase/Storage sync.
- Phase C service contracts exist with local fake implementations for auth, permissions, attachments, voice parsing, OCR parsing, and sync.
- Firebase Phase 1 foundation is implemented: a fresh Firebase project `kharcha-expense-snap` exists under `ahmadhabib2005@gmail.com`, Android/iOS app configs are present, `firebase_options.dart` points to that project, `FirebaseBootstrap` can enable Firebase with `KHARCHA_FIREBASE_ENABLED=true`, and `FirebaseAuthService` implements the existing `AuthService` contract for anonymous and email/password auth.
- The existing Login screen now calls `AuthService.signInWithEmail()` and routes to Dashboard on success without changing the visual design.
- The Auth screen's Continue with Google action now uses the shared auth contract, with a local fallback and Firebase Google OAuth implementation; successful sign-in routes to Dashboard.
- Firebase Phase 2 has been verified live on Android: Google sign-in and Firestore transaction/settings create, update, delete, restart restore, and profile/budget sync all work with `KHARCHA_FIREBASE_ENABLED=true`.
- Phase 4 profile/settings persistence is complete: `AppSettingsRepository` is the source for name, budget, currency, categories, notification preferences, and profile email. After a Firebase sign-in, existing cloud settings are pulled first, then Firebase Auth email/display name hydrate only missing profile identity fields and sync back without delaying the UI.
- History Undo now restores a remotely deleted transaction as a pending upsert using its stable document ID, so it is recreated in Firestore as well as locally.
- The sync coordinator coalesces writes arriving during an active sync into a follow-up pass; an immediate Undo during a Firestore delete cannot be dropped or removed by that delete's completion.
- Firestore sync now applies version-one last-write-wins using transaction `updatedAt` values. Deletes write `deletedAt` tombstones rather than removing the document, so a newer deletion defeats stale offline updates while an Undo/newer edit can intentionally recreate the transaction.
- History swipe-to-delete removes the dismissed row from the widget tree synchronously before local persistence and background sync, preventing the transient Flutter `Dismissible` assertion; Undo shows the row again.
- Category grouping normalizes Dining/Food/Food & Dining into the Food group for totals, filters, and icons.
- Analytics shows average per real expense for the selected period, not average per chart bucket, and its category legend is laid out below the ring so labels can display fully.
- Analytics compact-width rows are responsive on 390px mobile widths for By Category, Active Stat, and Activity Matrix headers/details.
- Performance polish now keeps the current visual design while reducing transition work: Dashboard uses cached page-based retained tab widgets instead of reconstructing the tab page tree on every dock tap, adjacent tabs are implicitly warmed by the PageView, built tabs are kept alive for repeat visits, Add Transaction lazily builds capture pages with inactive tickers disabled, heavy dashboard/analytics/history/profile regions have repaint isolation, and Analytics radial painting repaints only when values/colors change.
- Add Transaction modal opening no longer triggers an extra Dashboard-level dim overlay before the bottom sheet route; the modal route still provides the existing scrim/blur presentation.
- Profile's delayed stats animation timer is lifecycle-safe and is cancelled on dispose.
- Profile currency picker now initializes from the persisted currency symbol, so changing to dollars opens the picker with USD selected.
- Profile Log Out opens its existing confirmation sheet.
- Feature colors use the central theme tokens, and Android, iOS, and web launch surfaces use the warm Kharcha background.

## Current Gaps

- Firebase remains intentionally opt-in through `--dart-define=KHARCHA_FIREBASE_ENABLED=true`; without it, the app remains local-only.
- Storage, FCM, Gemini, and ML Kit OCR service implementations are not connected yet.
- Analytics still has some secondary mock/placeholder intelligence copy and active-stat logic.
- Further performance tuning should be guided by fresh DevTools recordings after this polish pass, especially on 120 Hz devices.
- Golden tests, physical-device DevTools profiling, final app icons, full permissions copy, and store listing assets are still pending launch tasks.
- [[Gemini Voice]] is planned, not implemented.
- [[OCR Scanning]] is planned, not implemented.

## Best Next Move

Implement Firebase Storage-backed attachment upload behind the existing attachment contract.

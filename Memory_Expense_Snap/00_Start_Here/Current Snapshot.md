---
type: snapshot
status: active
updated: 2026-08-27
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

- In-Widget Instant Voice Logging (Zero Full-App Launch):
  - Tapping the widget's amber microphone invokes native `VoiceWidgetActivity`.
  - Android displays the native voice recognition prompt directly above the home screen wallpaper.
  - Spoken expense is parsed via `VoiceTransactionParser` (supporting English and colloquial Urdu denominations like derh sau, dhai sau, hazar, lakh).
  - Transaction is appended directly to `FlutterSharedPreferences` (`flutter.kharcha.transactions.v1`).
  - Today's spending total is recalculated and the home screen widget is updated in real time via `AppWidgetManager`.
  - Toast confirmation appears right on the home screen (`✓ Added Rs. 350 for Burger`) and the activity closes instantly with no full app window opened.

- Native Android Home Screen Widget (`KharchaWidgetProvider`) implemented via `home_widget: ^0.9.3`:
  - Visuals: Quiet luxury card layout with warm cream/white background, 24dp rounded corners, and branded "KHARCHA" header.
  - Glance metrics: Displays real-time today's total spending (e.g., `Rs 11,200`) and today's expense count (`4 expenses today`).
  - Quick action shortcuts:
    - 🎙️ Voice Action (`@id/widget_action_voice`): Signature warm amber button that deep-links (`kharcha://capture/voice`) straight into `AddTransactionSheet(initialTab: AddTransactionTab.voice)`.
    - 📷 Scan Action (`@id/widget_action_scan`): Deep-links (`kharcha://capture/scan`) directly into receipt scan.
    - ➕ Manual Action (`@id/widget_action_manual`): Deep-links (`kharcha://capture/manual`) directly into manual expense form.
    - Whole card tap deep-links (`kharcha://home`) to Dashboard.
  - Real-time updates: `HomeWidgetService.updateWidgetData()` automatically syncs today's spending whenever transactions or settings are created, updated, or deleted.

- Weekly Velocity card features subtle greyish stadium pill tracks (`AppColors.chartTrack`) behind all days, with small dark baseline indicators for zero-spending slots and generous top breathing headroom inside the pill container so peak amounts don't touch the upper ceiling, while maintaining original 32px pill width.
- Google Sign-In is configured with explicit pre-sign-in session clearing (`signOut()` before `signIn()`), ensuring the native Google Account Picker prompt appears every time the user taps "Continue with Google".
- Microphone permission handling is fully automated via `permission_handler: ^12.0.3` with proactive OS permission prompts upon entering the Voice tab, graceful settings fallbacks, and real-time STT waveform streaming with zero mock text.
- Firebase is enabled by default for mobile/desktop runtimes with fallback detection, while automatically disabled in `FLUTTER_TEST` execution.

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
- Profile now uses a compact fixed `My Profile` header with an inset charcoal identity/stat card, inspired by the selected reference while retaining Kharcha's cream/charcoal/amber system. Only settings content scrolls, and both identity surfaces show the same synced profile email.
- Confirmed Profile logout now calls the shared auth service and resets the route stack to onboarding; users can leave an authenticated Firebase session and start the onboarding/sign-in flow again.
- The floating bottom dock now uses a reference-inspired expanding-tab micro-interaction: inactive destinations are icon-only, the real selected destination expands into a warm icon-plus-label capsule, and only its two-item group redistributes. The outer glass dock and centered Add action remain fixed; the action is a restrained amber squircle with a custom charcoal plus, while rapid switching, reduced motion, and responsive widths are covered by widget tests.
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
- Phase 4 Firebase Storage attachment service (`FirebaseStorageAttachmentService`) is implemented and wired into `KharchaBootstrap` and `AppServices.withAuth`, with storage security rules configured in `storage.rules` and `firebase.json`.
- Phase 5 Gemini AI voice logging (`GeminiVoiceExpenseParser`) and on-device speech-to-text (`SpeechRecognitionService`) are implemented and fully wired into `_VoiceTabView` in `AddTransactionSheet`, supporting Roman Urdu, Urdu, English, and Pakistani denominations with offline heuristic fallback.

## Current Gaps

- Firebase remains intentionally opt-in through `--dart-define=KHARCHA_FIREBASE_ENABLED=true`; without it, the app remains local-only.
- Storage, FCM, Gemini, and ML Kit OCR service implementations are not connected yet.
- Gemini API key is configured via `--dart-define=GEMINI_API_KEY=...`; without it, the app uses the built-in multilingual heuristic parser seamlessly.
- FCM push notifications and ML Kit OCR service implementations are not connected yet.
- Analytics still has some secondary mock/placeholder intelligence copy and active-stat logic.
- Further performance tuning should be guided by fresh DevTools recordings after this polish pass, especially on 120 Hz devices.
- Golden tests, physical-device DevTools profiling, final app icons, full permissions copy, and store listing assets are still pending launch tasks.
- [[Gemini Voice]] is planned, not implemented.
- [[OCR Scanning]] is planned, not implemented.

## Best Next Move

Implement Firebase Storage-backed attachment upload behind the existing attachment contract.
Proceed to Phase 6: Implement Google ML Kit on-device receipt OCR scanning behind the existing OCR capture adapter.

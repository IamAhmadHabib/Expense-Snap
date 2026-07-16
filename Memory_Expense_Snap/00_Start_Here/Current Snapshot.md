---
type: snapshot
status: active
updated: 2026-07-15
tags: [current-state, snapshot]
---

# Current Snapshot

Kharcha currently has a high-fidelity Flutter UI with a local repository-backed expense spine. Backend/Firebase/Gemini/OCR integrations are still pending.

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

- Local transactions/settings are persisted on device only; no cloud sync exists yet.
- Service implementations are local/fake; Firebase Auth, Firestore, Storage, Gemini, and ML Kit OCR are not connected yet.
- Analytics still has some secondary mock/placeholder intelligence copy and active-stat logic.
- Further performance tuning should be guided by fresh DevTools recordings after this polish pass, especially on 120 Hz devices.
- Golden tests, physical-device DevTools profiling, final app icons, full permissions copy, and store listing assets are still pending launch tasks.
- [[Firebase Architecture]] is planned, not implemented.
- [[Gemini Voice]] is planned, not implemented.
- [[OCR Scanning]] is planned, not implemented.

## Best Next Move

Connect the Phase C contracts to real Firebase Auth/Firestore/Storage first, then plug Gemini voice parsing and OCR into the prepared adapter interfaces.

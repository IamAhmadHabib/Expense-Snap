# Kharcha Build Phases

Last updated: 2026-07-15

This roadmap keeps implementation focused. When choosing between tasks, prefer the earliest unfinished phase unless Ahmad explicitly changes priorities.

## Phase 0 — Context Preservation

Goal: make sure future work always starts with the right product and architecture context.

Deliverables:

- `PRD.md`
- `Architecture.md`
- `Rules.md`
- `Phases.md`
- `Design.md`

Status: in progress / documentation created.

## Phase 1 — Stabilize the Current UI Shell

Goal: turn the high-fidelity UI into a connected app shell without changing the visual identity.

Tasks:

- Connect dashboard avatar to Profile tab/screen.
- Connect notification bell to a Notifications screen.
- Add a notifications screen if needed.
- Replace hardcoded colors with `AppColors` tokens.
- Replace web manifest Flutter blue with Kharcha background/theme colors.
- Fix Android launch background color.
- Fix iOS launch/storyboard white background where needed.
- Audit bottom navigation behavior.
- Audit Add Transaction modal behavior.
- Preserve existing premium animations.

Acceptance criteria:

- Navigation feels connected.
- No obvious dead top-level controls remain.
- No forbidden accent colors remain in primary screens.

## Phase 2 — Real Local Expense Flow

Goal: make the core expense loop work without waiting for Firebase.

Tasks:

- Create a shared transaction repository or app state layer.
- Make Add Transaction produce a real `Transaction`.
- Feed Dashboard from saved transactions.
- Feed History from saved transactions.
- Feed Analytics from saved transactions.
- Keep edit/delete behavior connected to the same source.
- Replace internal mock transaction state where appropriate.

Acceptance criteria:

- Add a manual expense.
- It appears in History.
- Dashboard totals update.
- Analytics changes based on the saved expense.
- Delete/edit changes are reflected everywhere.

## Phase 3 — Profile, Budget, and Settings State

Goal: persist the user’s personalization and key preferences.

Tasks:

- Persist user name.
- Persist monthly budget.
- Persist currency.
- Persist selected categories.
- Persist notification preferences.
- Persist theme/language choices if implemented.
- Ensure Profile edits update Dashboard where relevant.

Acceptance criteria:

- Personalization values survive app navigation/restart once persistence exists.
- Profile and Dashboard agree on user/budget/currency values.

## Phase 4 — Firebase Auth and Cloud Persistence

Goal: turn the local app into a real account-backed product.

Tasks:

- Add Firebase packages.
- Configure Firebase project for Android and iOS.
- Implement Firebase Auth for Google, Apple, and Email.
- Add Firestore data model.
- Sync transactions to Firestore.
- Sync profile/budget/category settings.
- Add Firebase Storage for receipt images.
- Handle offline/cache strategy.

Acceptance criteria:

- User can sign in.
- User data is scoped to their account.
- Expenses survive reinstall/sign-in on another device.

## Phase 5 — AI Voice Logging

Goal: make Kharcha’s hero interaction real.

Tasks:

- Add microphone permission handling.
- Add speech capture.
- Send transcript to Gemini parser.
- Parse amount, category, merchant, date, note, and payment method.
- Support Urdu, English, and mixed Roman Urdu.
- Add confirmation UI.
- Add correction flow: “No, make it 500.”
- Save confirmed parsed transaction.

Acceptance criteria:

- User taps mic.
- Speaks a mixed-language expense.
- App shows parsed result.
- User confirms or corrects.
- Saved transaction updates Dashboard, History, and Analytics.

## Phase 6 — OCR Receipt and Screenshot Scanning

Goal: make the Scan tab production-capable.

Tasks:

- Add camera permission.
- Add gallery picker.
- Integrate ML Kit OCR.
- Support paper receipts.
- Support screenshots.
- Support WhatsApp spending messages.
- Support Easypaisa/JazzCash screenshots.
- Support bank app/payment screenshots.
- Extract merchant, amount, date, category hints, and note.
- Store receipt image when appropriate.

Acceptance criteria:

- User scans/uploads an image.
- App extracts likely transaction fields.
- User confirms/edits.
- Saved transaction updates the app.

## Phase 7 — Notifications and Intelligence

Goal: make Kharcha feel proactive and helpful.

Tasks:

- Add notification scheduling.
- Add Firebase Cloud Messaging if remote notifications are needed.
- Weekly digest.
- Budget alerts.
- Spending insights.
- Daily reminder.
- Anomaly alerts.
- Budget forecasting.
- Habit pattern detection.

Acceptance criteria:

- Notifications respect user settings.
- Alerts are useful, timely, and not noisy.

## Phase 8 — Export and Sync

Goal: give users ownership and portability of their financial data.

Tasks:

- CSV export.
- PDF export.
- Google Sheets sync.
- Optional recurring Sheets append behavior.
- Export filters by date/category.

Acceptance criteria:

- User can export transactions.
- Exported totals match in-app totals.
- Sheets sync appends clean rows.

## Phase 9 — Launch Polish

Goal: prepare Kharcha for real app-store submission.

Tasks:

- Full design token audit.
- Performance profiling.
- Accessibility pass.
- Empty/error/loading states.
- Offline states.
- App icons and splash screens.
- Store screenshots.
- Privacy policy and permissions copy.
- Crash reporting.
- Analytics events.
- End-to-end QA.

Acceptance criteria:

- The app feels coherent, stable, polished, and trustworthy.

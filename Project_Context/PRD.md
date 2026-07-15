# Kharcha PRD

Last updated: 2026-07-15

Kharcha is a premium Flutter personal finance and expense tracking app built for Pakistani users. The product is AI-first, voice-first, and designed to make logging expenses feel faster than typing.

## Product Positioning

Kharcha means “expense” in Urdu. The app should feel elite, warm, calm, and launch-ready for both the Google Play Store and iOS App Store.

The core product promise:

> Track every rupee with less effort than typing.

## Target Users

- Pakistani users tracking personal, household, student, freelance, or small-business spending.
- Users who naturally mix Urdu, English, and Roman Urdu when speaking.
- Users who want fast expense capture, beautiful summaries, and export/sync options.
- Users who do not want a generic finance tracker with cold, bright, banking-style UI.

## Product Pillars

1. Voice-first expense logging.
2. Receipt, screenshot, WhatsApp, Easypaisa/JazzCash, and bank-message scanning.
3. Warm premium “quiet luxury” design.
4. Real financial summaries across dashboard, history, and analytics.
5. AI intelligence: categorization, insights, anomaly alerts, budget forecasting, and monthly stories.

## Current Implemented State

Implemented UI groups:

- Onboarding flow.
- Auth/sign-up/login screens.
- Personalization flow.
- Dashboard.
- Add Transaction bottom sheet with Voice, Scan, and Manual tabs.
- Analytics screen.
- History screen.
- Profile screen.
- Bottom navigation shell.

Current live route flow:

- `kharcha/lib/main.dart` starts at `OnboardingScreen`.
- Onboarding transitions to `AuthScreen`.
- Auth social/email buttons currently route to `PersonalizationFlow`.
- Login screen exists, but authentication is not wired to a backend.
- Personalization routes to `DashboardScreen`.
- Dashboard bottom nav switches between Dashboard, Analytics, History, and Profile.
- Dashboard add button opens `AddTransactionSheet`.
- History edit action can also open `AddTransactionSheet`.

## Current Data Reality

The `Transaction` model exists at `kharcha/lib/models/transaction.dart`, but there is not yet a shared data repository or persistent storage layer.

Current behavior:

- History creates mock transactions internally.
- Analytics uses screen-local mock chart data.
- Add Transaction simulates saving with a delay, then returns `true`.
- Dashboard has a placeholder refresh hook after Add Transaction closes, but no real data refresh logic.
- Dashboard, History, and Analytics are not yet connected to one source of truth.

## Known Product Gaps

- Notification bell is visual only and not connected to a notifications screen.
- Dashboard profile avatar is visual only and not connected to the Profile tab/screen.
- Expenses saved from Add Transaction do not persist.
- Dashboard does not update from saved expenses.
- History does not populate from saved expenses.
- Analytics does not derive charts from saved expenses.
- Firebase backend is not configured.
- Gemini voice parsing is not integrated.
- ML Kit OCR is not integrated.
- Google Sheets sync is not integrated.
- CSV/PDF export is not implemented.
- Notification scheduling and FCM are not implemented.
- Hardcoded colors still exist and must be mapped to design tokens.

## MVP Success Criteria

Kharcha MVP should prove the core loop:

1. User completes onboarding/personalization.
2. User adds an expense manually, by voice, or by scan UI path.
3. Expense is saved to a central transaction source.
4. Dashboard updates budget/spend summaries.
5. History shows the saved expense.
6. Analytics reflects the saved expense.
7. The app remains visually consistent with the warm charcoal-and-amber design system.

## V1 Success Criteria

V1 should add real backend and intelligence:

- Firebase Auth.
- Firestore expense persistence.
- Firebase Storage for receipt images.
- Gemini parsing for multilingual voice logging.
- ML Kit OCR for receipt/screenshot scanning.
- Notifications.
- CSV/PDF export.

## V2 Success Criteria

V2 should make Kharcha meaningfully smarter than a generic tracker:

- Google Sheets sync.
- WhatsApp weekly summary.
- Monthly AI story.
- Anomaly detection.
- Habit pattern detection.
- Budget forecasting.
- Goal tracking and savings coaching.
- Personal vocabulary learning for merchants/categories.

## Non-Negotiable Product Direction

- Preserve the AI-first and voice-first identity.
- Preserve the Pakistani user context.
- Preserve warm premium design.
- Never introduce ambient listening.
- Keep expense capture fast, tactile, and confidence-building.

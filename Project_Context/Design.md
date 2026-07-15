# Kharcha Design System

Last updated: 2026-07-15

Kharcha’s design language is warm, premium, charcoal-and-amber, and quietly luxurious. It should feel more like a crafted personal-money companion than a cold banking dashboard.

## Brand Feel

Kharcha should feel:

- Premium.
- Warm.
- Calm.
- Confident.
- Pakistani-context aware.
- Fast and effortless.
- AI-native without feeling gimmicky.
- Tactile and polished.

Visual language:

- Warm cream backgrounds.
- Deep charcoal structure.
- Amber as selective emphasis.
- Soft white surfaces.
- Rounded cards/sheets.
- Careful spacing.
- Restrained but delightful motion.

## Core Palette

Use `AppColors` from `kharcha/lib/theme/app_colors.dart`.

Primary design tokens:

- `AppColors.background` — app background.
- `AppColors.backgroundDark` — dark surfaces/backgrounds.
- `AppColors.surface` — cards, sheets, primary white surfaces.
- `AppColors.sectionCard` — profile/settings cards.
- `AppColors.surfaceVariant` — inactive chips and subtle containers.
- `AppColors.primary` — deep charcoal buttons, icons, and strong labels.
- `AppColors.primaryLight` — light primary-tinted surfaces.
- `AppColors.accent` — amber active/CTA state.
- `AppColors.accentLight` — soft amber tint.
- `AppColors.success` — income and positive state.
- `AppColors.danger` — error and over-budget state.
- `AppColors.dangerMuted` — destructive account actions.
- `AppColors.headerCard` — dashboard/profile hero cards.
- `AppColors.textPrimary` — main text.
- `AppColors.textSecondary` — secondary text.
- `AppColors.textTertiary` — tertiary text.
- `AppColors.profileDivider` — warm dividers.
- `AppColors.profileChevron` — profile chevrons.
- `AppColors.profileSubtext` — profile secondary text.

## Non-Negotiables

- No purple accents.
- No teal accents.
- No bright blue accents.
- No Flutter default blue.
- No hardcoded colors when a token exists.
- App background remains `#FAF8F4`.
- Amber is premium seasoning, not the whole meal.

## Typography

Current typography is centralized in `kharcha/lib/theme/app_typography.dart`.

General rules:

- Prefer confident hierarchy over many font sizes.
- Large money amounts should feel bold, readable, and calm.
- Labels should be crisp and not overly decorative.
- Secondary text should be warm-muted, not low-contrast gray sludge.

## Spacing

Current spacing is centralized in `kharcha/lib/theme/app_spacing.dart`.

General rules:

- Use spacing tokens when possible.
- Keep touch targets thumb-friendly.
- Bottom sheets need generous safe-area padding.
- The floating dock/add button should never crowd screen content.

## Motion Principles

Motion should feel premium and physical:

- Gentle rise.
- Soft blur.
- Radial reveal.
- Breathing mic rings.
- Smooth sliding tab pill.
- Count-up stats.
- Haptic feedback for meaningful actions.

Avoid:

- Hyperactive animations.
- Cheap bounce effects.
- Distracting loops.
- Motion that slows down expense capture.

## Screen Design Notes

### Onboarding

Purpose: teach the product promise quickly.

Requirements:

- Three-screen story.
- Voice/scan/manual introduction.
- Warm illustrations.
- Continue and Skip controls.
- Dot indicators.
- Final CTA transitions to Auth with radial reveal.

### Auth/Login

Purpose: feel trustworthy and lightweight.

Requirements:

- Warm cream background.
- Charcoal primary buttons.
- Google, Apple, and Email entry points.
- Amber/gold only for links or selected emphasis.
- Input fields use warm white fill.
- Focus styling should use charcoal/warm lift shadow, not amber borders.

### Personalization

Purpose: make the app feel personal from the first session.

Requirements:

- Monthly budget input.
- Category chip selector.
- At least three spending categories.
- First name input.
- Progress indicator.
- Skip option unless intentionally removed.

### Dashboard

Purpose: home base and fastest expense entry.

Requirements:

- Greeting with profile avatar.
- Notification bell.
- Budget hero card.
- Voice-first quick action layout.
- Weekly velocity chart.
- Top spending/category cards.
- Floating bottom dock.
- Amber center add button.

Design emphasis:

- Voice should remain the hero action.
- Budget hero uses deep charcoal.
- Active nav item uses amber.

### Add Transaction

Purpose: fastest way to save spending.

Requirements:

- Modal bottom sheet.
- Drag handle.
- Close button.
- Centered “Add Transaction” title.
- Tabs: Voice, Scan, Manual.
- Default active tab: Voice.
- Amber underline for active tab.
- Sliding pill/tab animation.

Voice tab:

- Language selector.
- Bottom-anchored mic.
- Three breathing concentric rings.
- Idle, Listening, Processing, Confirmed states.
- Parsed result confirmation.
- Correction path.

Scan tab:

- Rounded camera viewfinder.
- Amber corner brackets.
- Amber scanning beam.
- Format chips: Receipt, Screenshot, WhatsApp, Bank SMS.
- Gallery upload.
- Flash toggle.
- Processing/result states.

Manual tab:

- Large amount input.
- Custom numpad.
- Category picker.
- Description/title field.
- Date and time chips.
- Payment method chips.
- Optional note.
- Full-width save button.

### Analytics

Purpose: turn raw spending into insight.

Requirements:

- Period selector.
- Total spend card.
- Main chart.
- Category breakdown.
- Budget progress bars.
- Top merchants.
- AI insight card.

Design emphasis:

- Charts should use amber/charcoal/warm neutrals.
- Over-budget indicators should use muted red.
- AI insight card may use amber tint.

### History

Purpose: searchable, trustworthy transaction ledger.

Requirements:

- Header with running total.
- Search.
- Filters.
- Date-grouped transactions.
- Daily/monthly summaries.
- Expandable rows.
- Edit/delete actions.
- Swipe delete with undo.
- Empty state.

Design emphasis:

- Warm neutral category icons only.
- Amber for expenses/accent strips.
- Green only for income.
- No bright category colors.

### Profile

Purpose: personal settings and trust controls.

Requirements:

- Deep charcoal header card.
- Avatar with amber detail.
- Name and email.
- Stats row.
- Personal info settings.
- Budget settings.
- Currency selector.
- Notification toggles.
- App settings.
- Logout.
- Delete Account.

Design emphasis:

- Settings cards are warm white on cream.
- Toggles are amber when active.
- Delete Account is muted red and visually separate.

## Current Design Debt

Known issues:

- Hardcoded colors remain in multiple files.
- Web manifest still uses Flutter default blue.
- Some platform launch backgrounds are default white/blue.
- Some `Colors.white`, `Colors.black`, and transparent usages need review.
- Some hardcoded colors may be valid brand-adjacent values but should become named tokens before wider use.

Known files to audit first:

- `kharcha/lib/features/transactions/add_transaction_sheet.dart`
- `kharcha/lib/features/analytics/analytics_screen.dart`
- `kharcha/lib/features/history/history_screen.dart`
- `kharcha/lib/features/dashboard/dashboard_screen.dart`
- `kharcha/lib/features/profile/profile_screen.dart`
- `kharcha/lib/features/onboarding/illustrations/iphone_skeleton.dart`
- `kharcha/web/manifest.json`
- `kharcha/android/app/src/main/res/`
- `kharcha/ios/Runner/Base.lproj/`

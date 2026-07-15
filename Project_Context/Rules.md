# Kharcha Rules

Last updated: 2026-07-15

These rules are the project guardrails. Read this before changing UI, product behavior, architecture, or dependencies.

## Product Rules

- Kharcha is built for Pakistani users.
- Preserve the app’s AI-first and voice-first direction.
- Urdu, English, Roman Urdu, and mixed code-switching are core product requirements.
- Mic activates only when the user taps. Never implement ambient listening.
- Every feature should feel polished enough for a real store launch.
- Prefer fast capture and confidence-building confirmation over complex forms.
- Do not turn Kharcha into a generic finance dashboard.

## Design Rules

Use centralized tokens from `kharcha/lib/theme/app_colors.dart`.

Never hardcode a color when a token exists.

Official core tokens:

- Background: `#FAF8F4`
- Background dark: `#1C1C1E`
- Surface / section card: `#FFFFFF`
- Surface dark: `#2C2C2E`
- Surface variant: `#F0EDE8`
- Surface variant dark: `#3A3A3C`
- Primary / section label: `#1C1C1E`
- Primary light: `#FAF7F2`
- Accent: `#E5A33C`
- Accent light: `#F5DEB3`
- Success: `#34C759`
- Success dark: `#30D158`
- Danger: `#E8634A`
- Danger dark: `#FF6961`
- Text primary: `#3D3D3D`
- Text secondary: `#8E8E93`
- Text tertiary: `#AEAEB2`
- Border: `#E5E5EA`
- Divider: `#F2F2F7`
- Header card: `#141210`
- Amber gold: `#C9973A`
- Danger muted: `#A0392B`
- Profile divider: `#EDE6DC`
- Profile chevron: `#C4B8A8`
- Profile subtext: `#9C8E7E`
- Dot active: `#1C1C1E`
- Dot inactive: `#D1D1D6`

## Forbidden Visual Direction

Do not use:

- Purple accents.
- Teal accents.
- Bright blue accents.
- Flutter default blue.
- Cold banking-dashboard color palettes.

Known forbidden/problem colors that should be removed or mapped:

- `#9D4EDD`
- `#2EC4B6`
- `#4361EE`
- `#0175C2`

Other known hardcoded values to audit:

- `#0A0A0A`
- `#0C0C0C`
- `#0D1821`
- `#18181A`
- `#1A1612`
- `#1B2F45`
- `#1E1E20`
- `#242018`
- `#2D6A4F`
- `#2D7A4F`
- `#333336`
- `#383838`
- `#4A4A4A`
- `#635647`
- `#8C7E6E`
- `#908D89`
- `#D32F2F`
- `#D4AF37`
- `#E0E0E0`
- `#E6A300`
- `#E8DDD0`
- `#EFEDE8`
- `#F0EBE4`
- `#FAF6F0`
- `#FAF9F6`
- `#FBFBFB`
- `#FF9F1C`
- `#FFECEC`

## Accent Usage Rules

Use `#E5A33C` sparingly for:

- Primary CTA buttons.
- Active nav item.
- Active Add Transaction tab underline.
- Active toggle switches.
- Links.
- Current-day/chart highlights.
- Important positive brand emphasis.

Do not use amber as a generic field border everywhere.

## Semantic Color Rules

- Success is for income, connected integration status, and positive trends only.
- Danger is for over-budget warnings and error states.
- Danger muted is for Delete Account text and destructive confirmation only.
- Header card is for the dashboard budget hero and profile header.
- Background must remain `#FAF8F4` across screens unless Ahmad explicitly changes the brand direction.

## Screen Rules

### Onboarding

- Three screens.
- Continue and Skip behavior.
- Dot indicators.
- Final action transitions to Auth with radial reveal.

### Auth/Login

- Warm cream background.
- Charcoal primary buttons.
- Amber/gold only for links/emphasis.
- Input focus should use charcoal/warm shadow, not amber border.

### Personalization

- Budget input first.
- Category selection requires at least three categories.
- Name input last.
- Skip remains available unless intentionally removed by product decision.

### Dashboard

- Voice quick action is the hero action and should remain dominant.
- Center add button is amber and elevated.
- Budget hero uses deep charcoal.
- Notification bell must route to notifications once that screen exists.
- Profile avatar should route to Profile.

### Add Transaction

- Opens as a modal bottom sheet.
- Default tab is Voice, not Manual.
- Voice tab must never start listening until user taps.
- Scan tab should support Receipt, Screenshot, WhatsApp, and Bank SMS/payment screenshots.
- Manual tab must remain fast and thumb-friendly.

### History

- Category icon backgrounds use warm neutral tints only.
- No blues, teals, or bright category colors.
- Expenses use charcoal amounts.
- Income uses green.
- Swipe delete should offer undo.

### Profile

- Header uses deep charcoal.
- Toggles use amber only when active.
- Delete Account uses muted red and is visually separate.

## Code Rules

- Prefer shared repositories/services over isolated mock state.
- Do not duplicate transaction state across screens.
- If Add Transaction changes, check Dashboard, History, and Analytics effects.
- If color changes, check `AppColors` first.
- If adding packages, verify they are needed for the next milestone.
- Keep animations purposeful and premium.
- Avoid large rewrites when a small connected change will preserve the current high-fidelity UI.

## Current Priority Rules

1. Create a real saved-expense flow.
2. Connect Dashboard, History, and Analytics to one transaction source.
3. Connect dashboard notification bell.
4. Connect dashboard profile avatar.
5. Clean hardcoded colors and platform launch colors.

---
type: screen
status: polished
tags: [screen, onboarding]
---

# Onboarding

Purpose: introduce Kharcha's core promise through three premium screens.

Current behavior:

- Page 1 uses `onboarding_capture.png` for voice, scan, receipt, and keyboard capture.
- Page 2 uses `onboarding_insights.png` for automatic transaction organization because the current visual asset content maps to the categories story.
- Page 3 uses `onboarding_categories.png` for monthly insights/story because the current visual asset content maps to the insights story.
- The illustration viewport stays mounted while outgoing and incoming PNGs overlap, preventing blank frames between pages.
- Continue and swipe navigation share one authoritative page transition with a rapid-tap lock.
- Skip and Get Started preserve the existing route to [[Auth Login]].
- The layout keeps the CTA reachable from 360x640 through tall-phone dimensions, with a slightly larger illustration viewport and the text block nudged down for better phone balance.
- Images are precached and decode-capped, while the illustration viewport is isolated with `RepaintBoundary`.
- Reduced-motion users receive a short cross-fade without rotation or large translation.
- Each illustration exposes a meaningful accessibility label.

Related:

- [[Product Vision]]
- [[Animation Rules]]
- [[Onboarding Code]]
- [[Auth Login]]

Code:

- `kharcha/lib/features/onboarding/onboarding_screen.dart`
- `kharcha/lib/features/onboarding/widgets/`
- `kharcha/assets/images/onboarding/`
- `kharcha/test/onboarding_screen_test.dart`

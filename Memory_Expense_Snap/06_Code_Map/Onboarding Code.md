---
type: code-map
status: active
tags: [code, onboarding]
---

# Onboarding Code

Sources:

```text
kharcha/lib/features/onboarding/onboarding_screen.dart
kharcha/lib/features/onboarding/personalization_flow.dart
kharcha/lib/features/onboarding/widgets/onboarding_illustration_transition.dart
kharcha/lib/features/onboarding/widgets/onboarding_text_transition.dart
kharcha/lib/features/onboarding/widgets/onboarding_page_indicator.dart
kharcha/lib/features/onboarding/widgets/onboarding_primary_button.dart
kharcha/assets/images/onboarding/
kharcha/test/onboarding_screen_test.dart
```

Architecture:

- `onboarding_screen.dart` owns the single current-page state, transition lock, swipe direction, image precaching, CTA behavior, and existing Auth navigation.
- `OnboardingIllustrationTransition` overlaps the outgoing and incoming PNGs in one persistent `RepaintBoundary` viewport.
- `OnboardingTextTransition` coordinates the independent title/description motion without layout jumps.
- `OnboardingPageIndicator` derives its active page from the same transition state.
- `OnboardingPrimaryButton` keeps the CTA location stable and provides the press-scale feedback.
- The old Flutter-built phone/mockup illustration sources and obsolete PNGs were removed after confirming no remaining references.

Related:

- [[Onboarding]]
- [[Personalization]]
- [[Animation Rules]]

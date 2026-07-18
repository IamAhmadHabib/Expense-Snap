---
type: phase
status: in-progress
tags: [phase, launch]
---

# Phase 9 Launch Polish

Goal: app-store readiness.

Completed polish pass:

- Dashboard weekly velocity three-dot control now routes to [[Analytics]].
- Dashboard Top Spending "See all" now routes to [[History]].
- Dashboard Top Spending now shows up to five static vertical capsules in the main page scroll, with the rest reachable through [[History]] via "See all".
- Compact-width Analytics overflow fixes were added for 390px mobile layouts.
- [[Onboarding]] now uses transparent production PNGs with coordinated overlapping transitions, input locking, responsive sizing, preserved swipe/navigation behavior, image precaching, accessibility semantics, and reduced-motion support.
- Legacy onboarding phone/mockup widgets and obsolete checkerboard/illustration assets were removed after reference checks.
- Analyzer is clean and the Flutter test suite passes after this pass.

Still pending for true launch readiness:

- Golden tests for core screens.
- Fresh Flutter DevTools profile recordings on a physical phone.
- Final app icons and adaptive icon review.
- Final permissions copy for microphone/camera/photos/notifications.
- Store listing screenshots, privacy policy copy, and release QA checklist.

Related:

- [[Accessibility]]
- [[Design Debt]]
- [[Success Criteria]]
- [[Known Bugs]]

---
type: decisions
status: active
tags: [decisions, log]
---

# Decision Log

Use this note to link decisions.

## Current Decisions

- Ensure Google OAuth always prompts for account selection by calling `GoogleSignIn().signOut()` before `signIn()`.
- Use `permission_handler` to proactively request OS-level runtime audio permissions when navigating to Voice capture.
- Standardize weekly chart empty slots using `AppColors.chartTrack` with a subtle circular dot at the base and 14px headroom at the pill top.

- Use Obsidian as the living memory graph for Kharcha.
- Keep `Project_Context/` as the formal handoff pack.
- Use [[Kharcha Home]] as the vault hub.
- Build [[Phase 2 Real Expense Flow]] before deep Firebase/Gemini/OCR.
- Use an expanding selected-tab interaction for the main floating dock: inactive destinations stay icon-only, only the active destination reveals its label, each side redistributes independently around a fixed center Add action, and motion must honor reduced-motion settings.

Related:

- [[ADR Template]]
- [[Product Decisions]]
- [[Technical Decisions]]

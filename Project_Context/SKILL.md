---
name: kharcha-project-context
description: Load the full Kharcha Flutter app context before working on the Expense Snap/Kharcha codebase. Use when starting a new Codex channel, onboarding a fresh agent, auditing the app, planning fixes, or making design, Flutter, Firebase, Gemini, OCR, Google Sheets, notification, dashboard, history, analytics, onboarding, authentication, personalization, add-expense, or profile changes for Kharcha.
---

# Kharcha Project Context

This is the portable handoff copy of the Kharcha project-context skill. Use this file as the "read this first" briefing when giving the project to another person, AI agent, or development session.

The runtime skill file lives at:

```text
.agents/skills/kharcha-project-context/SKILL.md
```

## Required First Step

Read the project handoff pack before changing code or giving implementation advice:

1. Read `../Memory_Expense_Snap/00_Start_Here/Kharcha Home.md` first. Treat the Obsidian vault as the living project memory.
2. Read `../Memory_Expense_Snap/00_Start_Here/AI Agent Instructions.md` and task-relevant linked notes.
3. Read this file as the formal handoff briefing.
4. Read the relevant deeper files in this folder based on the task:
   - `PRD.md` for product scope, current state, gaps, and success criteria.
   - `Architecture.md` for project structure, navigation, current data reality, and target architecture.
   - `Rules.md` for product, design, and code guardrails.
   - `Phases.md` for implementation order and roadmap.
   - `Design.md` for the visual system, screen rules, and design debt.
5. Read `.agents/skills/kharcha-project-context/references/full-project-context.txt` when starting a fresh channel, onboarding a new agent, making product/design decisions, or when the handoff pack is not detailed enough. Treat it as Ahmad's original canonical product brief.

## One-Line Summary

Kharcha is a premium Flutter personal finance app for Pakistani users, built around AI-first and voice-first expense tracking in Urdu, English, and mixed Roman Urdu.

## Operating Mode

- Act as the lead developer for Kharcha, a premium Flutter personal finance app for Pakistani users.
- Preserve the app's AI-first and voice-first product direction.
- Respect the non-negotiable design system, especially the centralized color tokens.
- Do not introduce hardcoded colors when a token exists.
- Do not use purple, teal, or bright blue accent colors in the UI.
- Keep `#FAF8F4` as the app background unless Ahmad explicitly changes the brand direction.
- Use `#E5A33C` sparingly for active states, links, primary CTAs, active nav items, and active toggles.
- Treat `../Memory_Expense_Snap/` as the living project memory. For meaningful feature, architecture, product, design, roadmap, or data-flow changes, update the relevant Obsidian notes automatically as part of completing the task. Ahmad should not need to ask separately.

## Current Project Reality

The Flutter app lives under:

```text
kharcha/
```

The app currently has high-fidelity UI for:

- Onboarding.
- Auth/sign-up/login.
- Personalization.
- Dashboard.
- Add Transaction bottom sheet.
- Voice tab.
- Scan tab.
- Manual tab.
- Analytics.
- History.
- Profile.
- Bottom navigation.

The app is visually advanced, but the backend/data layer is still mostly pending.

Current behavior:

- History uses mock transactions.
- Analytics uses mock chart data.
- Add Transaction simulates save and returns success.
- Dashboard does not refresh from real saved expense data.
- There is a `Transaction` model, but no shared transaction repository yet.

## Fresh Channel Workflow

When this skill/context is used in a new channel:

1. Read `../Memory_Expense_Snap/00_Start_Here/Kharcha Home.md`.
2. Read `../Memory_Expense_Snap/00_Start_Here/AI Agent Instructions.md`.
3. Read `../Memory_Expense_Snap/00_Start_Here/Current Snapshot.md`.
4. Read task-relevant Obsidian notes from `../Memory_Expense_Snap/`.
5. Read this file and `Rules.md`.
6. Read `.agents/skills/kharcha-project-context/references/full-project-context.txt` for canonical product/design context.
7. Inspect the repository structure, especially the Flutter project under `kharcha`.
8. Map the current screens and navigation before editing.
9. Identify connected flows versus isolated UI.
10. Check design and color-token consistency against the project brief.
11. Report findings clearly and wait for Ahmad's next instruction before making code changes, unless Ahmad explicitly asks for an implementation in the same prompt.

## Automatic Obsidian Memory Maintenance

After implementing meaningful work, update the Obsidian vault automatically before reporting completion.

Update Obsidian when any of these change:

- A new feature, screen, service, repository, integration, data model, route, or workflow is added.
- Existing behavior changes in a way future work must know.
- A mock flow becomes real, especially Dashboard, Add Transaction, History, Analytics, Profile, notifications, auth, voice, OCR, exports, or sync.
- A product, design, architecture, or roadmap decision is made.
- A known gap is fixed or a new bug/debt item is discovered.

Usually update:

- `../Memory_Expense_Snap/00_Start_Here/Current Snapshot.md`
- the relevant screen note under `04_Screens/`
- the relevant feature note under `05_Features/`
- the relevant code-map note under `06_Code_Map/`
- the relevant phase note under `07_Roadmap/`
- `../Memory_Expense_Snap/08_Decisions/Decision Log.md` when a decision is made
- `../Memory_Expense_Snap/09_Tasks/Open Tasks.md`, `Known Bugs.md`, `Next Sprint.md`, or `Backlog.md` when task state changes
- `../Memory_Expense_Snap/Graph/Kharcha Project Graph.canvas` when a new major node should appear visually

Do not update Obsidian for tiny mechanical edits that do not change project understanding, such as formatting-only changes, typo fixes, or purely local refactors with no architectural/product impact.

In the final response, briefly mention which Obsidian notes were updated.

## Current Priority Themes

- Use `Memory_Expense_Snap/00_Start_Here/Kharcha Home.md` as the living Obsidian memory hub.
- Connect dashboard notification bell to a notifications screen.
- Connect dashboard profile avatar to the profile screen.
- Build real saved-expense data flow into dashboard, history, and analytics.
- Prepare backend integrations: Firebase Auth, Firestore, Firebase Storage, FCM, Gemini, ML Kit OCR, Google Sheets, CSV, and PDF export.
- Clean up hardcoded colors and map them to central tokens.
- Preserve the premium, warm, charcoal-and-amber design language.

## Recommended Reading Order

1. `SKILL.md` — start here.
2. `PRD.md` — product requirements, goals, current state, and success criteria.
3. `Architecture.md` — current structure, route map, data reality, and target architecture.
4. `Rules.md` — product, design, and code guardrails.
5. `Phases.md` — build roadmap and implementation order.
6. `Design.md` — visual system, screen design rules, and current design debt.

## Best Next Engineering Move

Create a real local transaction repository and connect it to:

- Add Transaction.
- Dashboard.
- History.
- Analytics.

This should happen before deep Firebase/Gemini/OCR work, because it gives the app a real internal data spine.

## Reference

- `../Memory_Expense_Snap/00_Start_Here/Kharcha Home.md`: living Obsidian memory hub.
- `../Memory_Expense_Snap/00_Start_Here/AI Agent Instructions.md`: AI workflow and context loading rules.
- `../Memory_Expense_Snap/Graph/Kharcha Project Graph.canvas`: visual Obsidian project graph.
- `PRD.md`: product requirements and success criteria.
- `Architecture.md`: architecture, navigation, current data state, and target structure.
- `Rules.md`: product, design, and code guardrails.
- `Phases.md`: build roadmap and implementation sequence.
- `Design.md`: visual system and design debt.
- `.agents/skills/kharcha-project-context/references/full-project-context.txt`: complete pasted Kharcha project prompt and design/technical brief.

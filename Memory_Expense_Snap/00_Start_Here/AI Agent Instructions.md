---
type: instruction
status: active
tags: [ai-agent, workflow, rules]
---

# AI Agent Instructions

Before implementing anything in Kharcha:

1. Read [[Kharcha Home]].
2. Read [[Current Snapshot]].
3. Read [[Rules Summary]] and [[Design System]].
4. Read the relevant screen, feature, code, or phase note.
5. Inspect the live code before assuming behavior.

## Non-Negotiables

- Preserve [[Product Vision]].
- Preserve [[Color Tokens]].
- Do not hardcode colors when a token exists.
- Do not use purple, teal, bright blue, or Flutter default blue.
- Mic activates only after user tap; never ambient listening.
- If work touches expenses, check [[Transactions]], [[Data Flow]], [[Dashboard]], [[History]], and [[Analytics]].

## Preferred Context Loading

Load only the relevant graph slice:

- Product work: [[Product Vision]], [[Target Users]], [[PRD Summary]].
- UI work: [[Design System]], [[Screen Design Rules]], specific screen note.
- Data work: [[Data Flow]], [[State Management]], [[Transaction Model]], [[Repository Plan]].
- Roadmap work: [[Phase 1 UI Shell]] through [[Phase 9 Launch Polish]].

## Update Rule

Obsidian memory maintenance is part of the definition of done. Ahmad should not need to separately ask for it.

After meaningful implementation, update:

- [[Current Snapshot]]
- relevant screen/feature/code notes
- [[Decision Log]] if a decision was made
- [[Open Tasks]] or [[Known Bugs]] if scope changes

## Automatic Graph Update Policy

Update the vault automatically when any of these happen:

- A new feature, screen, service, repository, integration, model, route, or workflow is added.
- Existing behavior changes in a way future work must know.
- A mock flow becomes real.
- A product/design/architecture/roadmap decision is made.
- A known gap is fixed.
- A new bug, design debt, or technical debt item is discovered.

Usually update the matching notes in:

- [[Current Snapshot]]
- [[04_Screens]]
- [[05_Features]]
- [[06_Code_Map]]
- roadmap phase notes
- [[Decision Log]]
- [[Open Tasks]]
- [[Known Bugs]]
- [[Next Sprint]]

Update `Graph/Kharcha Project Graph.canvas` when a new major feature/screen/system deserves a visible graph node.

Skip Obsidian updates for tiny mechanical changes that do not affect project understanding, such as typo-only edits, formatting-only edits, or isolated refactors with no behavior/product/architecture impact.

In the final response, state which Obsidian notes were updated.

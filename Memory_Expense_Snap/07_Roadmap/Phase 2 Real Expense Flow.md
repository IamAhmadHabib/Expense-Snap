---
type: phase
status: priority
tags: [phase, transactions]
---

# Phase 2 Real Expense Flow

Goal: make the core expense loop real.

Tasks:

- Build [[Repository Plan]].
- Save real [[Transactions]] from [[Add Transaction]].
- Feed [[Dashboard]], [[History]], and [[Analytics]].
- Preserve the existing design while polishing local frontend performance: cached retained page-based tab shell, implicit adjacent tab warming, keep-alive wrappers for built tabs, Add Transaction lazy capture pages, repaint isolation for heavy regions, lifecycle-safe timers, and painter repaint guards are now in place.

Related:

- [[Data Flow]]
- [[Transaction Model]]
- [[Open Tasks]]

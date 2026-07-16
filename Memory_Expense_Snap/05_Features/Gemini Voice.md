---
type: feature
status: planned
tags: [gemini, voice, ai]
---

# Gemini Voice

Gemini Voice is the planned AI parsing layer behind [[Voice Logging]].

Responsibilities:

- Parse Urdu, English, and Roman Urdu expense phrases.
- Extract amount, merchant, category, date, note, and payment method.
- Support correction flow.
- Return confirmed transaction data to [[Transactions]].

Frontend readiness:

- `ExpenseCaptureAdapter<VoiceCaptureInput>` exists.
- `CaptureParseResult` wraps a `TransactionDraft`, confidence, warnings, and correction workflow.
- `CaptureCorrection` can update amount, merchant, category, date, note, method, and income flag before save.
- Current implementation is a local simulated parser; Gemini is not connected yet.

Related:

- [[Voice Tab]]
- [[Voice Logging]]
- [[Phase 5 Gemini Voice]]
- [[Data Flow]]

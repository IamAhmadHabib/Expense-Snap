---
type: feature
status: planned
status: implemented
tags: [gemini, voice, ai]
---

# Gemini Voice

Gemini Voice is the planned AI parsing layer behind [[Voice Logging]].
Gemini Voice is the AI parsing layer behind [[Voice Logging]], integrated in Phase 5.

Responsibilities:
Responsibilities & Architecture:

- Parse Urdu, English, and Roman Urdu expense phrases.
- Extract amount, merchant, category, date, note, and payment method.
- Support correction flow.
- Return confirmed transaction data to [[Transactions]].
- **Gemini GenerativeModel**: Powered by `gemini-1.5-flash` (`google_generative_ai: ^0.4.7`). Configured with JSON response MIME type and financial extraction prompt tailored to Pakistani colloquial and formal expense expressions.
- **Multilingual Support**: Parses Urdu, English, and Roman Urdu phrases seamlessly.
- **Pakistani Currency Understanding**: Handles `sau`, `dhai sau` (250), `derh sau` (150), `hazar` (1000), `dhai hazar` (2500), and `lakh` (100000).
- **Field Extraction**: Accurately extracts `amount`, `merchant`, `category`, `date`, `note`, `method` (Cash/Card/Transfer), and `isIncome` flag.
- **Local Fallback**: Full offline heuristic parser activates when offline or when no Gemini API key is configured.
- **Inline Editing & Confirmation**: Spoken results display immediately with full inline editing capability before committing to the database.
- **Repository & Sync Integration**: Saved transactions pass through `TransactionRepository` and sync to Cloud Firestore.

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

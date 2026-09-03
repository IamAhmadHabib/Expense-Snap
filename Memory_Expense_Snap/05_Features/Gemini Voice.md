---
type: feature
status: implemented
tags: [gemini, voice, ai, nlp]
---

# Gemini Voice

Gemini Voice is the AI parsing layer behind [[Voice Logging]], integrated in Phase 5.

Responsibilities & Architecture:

- Parse Urdu, English, and Roman Urdu expense phrases.
- Extract amount, merchant, category, date, note, and payment method.
- **Gemini GenerativeModel**: Powered by `gemini-1.5-flash` (`google_generative_ai: ^0.4.7`). Configured with JSON response MIME type and financial extraction prompt tailored to Pakistani colloquial and formal expense expressions.
- **Multilingual Support**: Parses Urdu, English, and Roman Urdu phrases seamlessly.
- **Pakistani Currency Understanding**: Handles `sau`, `dhai sau` (250), `derh sau` (150), `hazar` (1000), `dhai hazar` (2500), `lakh` (100000), and `crore` (10,000,000).
- **Field Extraction**: Accurately extracts `amount`, `merchant`, `category`, `date`, `note`, `method` (Cash/Card/Transfer), and `isIncome` flag.
- **Local Fallback**: Full offline heuristic parser activates when offline or when no Gemini API key is configured.
- **Inline Editing & Confirmation**: Spoken results display immediately with full inline editing capability before committing to the database.
- **Repository & Sync Integration**: Saved transactions pass through `TransactionRepository` and sync to Cloud Firestore.

Frontend Readiness & Architecture:

- `ExpenseCaptureAdapter<VoiceCaptureInput>` is implemented by `GeminiVoiceExpenseParser`.
- `CaptureParseResult` wraps a `TransactionDraft`, confidence score, warnings, and correction workflow.
- `CaptureCorrection` updates amount, merchant, category, date, note, method, and income flag before save.



### Urdu & Pakistani Language Heuristics Engine
- **Preposition Guardrail**: Words like `ka`, `ki`, `ke`, and `kay` ("of" / "for" in Urdu/Hindi) are strictly isolated with word boundaries so that digits preceding them (e.g. `300 ka khana`) are not multiplied by `1000` (`k`).
- **Comprehensive Pakistani Denominations**:
  - `derh sau` / `dedh sau` = 150
  - `dhai sau` / `adhaai sau` = 250
  - `paune do sau` = 175
  - `sawa do sau` = 225
  - `paune sau` = 75
  - `sawa sau` = 125
  - `derh hazar` / `dedh hazar` = 1500
  - `dhai hazar` = 2500
  - `sade teen hazar` = 3500
  - `sade char hazar` = 4500
  - `sade panch hazar` = 5500
  - `paune hazar` = 750
  - `sawa lakh` = 125,000
  - `derh lakh` = 150,000
  - `dhai lakh` = 250,000
  - `sade teen lakh` = 350,000
  - `crore` / `kror` = 10,000,000
- **Noise Filter**: Strips common spoken filler words (`maine`, `meine`, `ka`, `ki`, `ke`, `pe`, `par`, `mein`, `kharch`, `diye`, `lagaye`, `bhare`, `rupay`) to cleanly preserve the merchant name (e.g., `300 ka khana` -> merchant `Food` or `Khana`).

Related:

- [[Voice Tab]]
- [[Voice Logging]]
- [[Phase 5 Gemini Voice]]
- [[Data Flow]]

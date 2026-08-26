---
type: phase
status: planned
tags: [phase, gemini, voice]
status: completed
tags: [phase, gemini, voice, ai]
---

# Phase 5 Gemini Voice

Goal: make [[Voice Logging]] real.
Goal: make [[Voice Logging]] real with Google Gemini AI and on-device speech-to-text.

Status: **Completed**

## Implemented Deliverables

1. **Gemini AI Parsing Adapter**:
   - Implemented in `kharcha/lib/services/gemini_voice_parser.dart` adhering to `ExpenseCaptureAdapter<VoiceCaptureInput>`.
   - Leverages `google_generative_ai: ^0.4.7` with model `gemini-1.5-flash` and strict JSON schema enforcement (`responseMimeType: 'application/json'`).
   - Supports `--dart-define=GEMINI_API_KEY=...` or constructor injection.

2. **Multilingual Local NLP Heuristic Fallback**:
   - Automatic graceful fallback when offline or when no API key is provided.
   - Accurately parses Roman Urdu ("Maine 300 rupay burger pe kharch kiye", "1200 uber pe lagaye"), English ("Spent 1500 at KFC on card"), and Urdu.
   - Resolves colloquial Pakistani currency denominations: `dhai sau` (250), `derh sau` (150), `hazar/hazaar` (1000), `lakh` (100000), `dhai hazar` (2500).
   - Detects categories (Food & Dining, Transportation, Bills & Utilities, Shopping, Health, Entertainment, Income), merchants, and payment methods (Cash, Card, Transfer).

3. **On-Device Speech Recognition**:
   - Implemented in `kharcha/lib/services/speech_recognition_service.dart` wrapping `speech_to_text: ^7.4.0`.
   - Uses non-deprecated `SpeechListenOptions` with real-time word streaming.

4. **Interactive UI & Repository Wiring**:
   - `_VoiceTabView` in `kharcha/lib/features/transactions/add_transaction_sheet.dart` captures real audio, animates waveform/status, parses transcript through `AppServices.voiceParser`, displays parsed draft, allows inline editing, and saves to `TransactionRepository` (which syncs to Firestore).

5. **Test Coverage**:
   - 9 dedicated tests in `kharcha/test/gemini_voice_parser_test.dart` verifying Roman Urdu, denominations, English, empty inputs, and draft immutability.
   - 64 / 64 tests passing across the entire project.

Related:

- [[Voice Tab]]
- [[Voice Logging]]
- [[Transactions]]
- [[Current Snapshot]]

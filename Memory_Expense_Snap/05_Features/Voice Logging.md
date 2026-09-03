---
type: feature
status: implemented
tags: [voice, gemini, ai, stt]
---

# Voice Logging

Voice logging is a core product differentiator implemented in Phase 5.

Capabilities:

- Tap-to-listen microphone speech recognition with real-time word streaming.
- Urdu, English, and Roman Urdu speech understanding.
- [[Gemini Voice]] AI parsing with local offline heuristic fallback.
- Support for Pakistani denominations (dhai sau, derh sau, hazar, lakh, crore).
- Full interactive card confirmation, speech-gated dynamic acoustic visualizer (ambient silence noise gate, real-time voice amplitude waves), and inline editing.
- Persisted to local repository and synchronized with Cloud Firestore.
- In-widget instant voice logging via native Android `VoiceWidgetActivity` + `VoiceTransactionParser`.

Related:

- [[Voice Tab]]
- [[Phase 5 Gemini Voice]]
- [[Transactions]]


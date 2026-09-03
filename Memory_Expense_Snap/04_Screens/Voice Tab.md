---
type: screen-section
status: implemented
tags: [voice, gemini, ai, native-widget]
---

# Voice Tab

Default Add Transaction tab and in-widget instant capture interface.

Implemented Capabilities:

- Mic activates on user tap with noise-gated real-time acoustic waveform: sits completely still at 4px calm baseline during silence and ambient room noise, and vibrates dynamically with acoustic height and amber glow only when speech is detected.
- Automated OS-level audio permission requests via `permission_handler`.
- Multilingual STT and Gemini AI parsing (`GeminiVoiceExpenseParser`) supporting English, Urdu, and Roman Urdu.
- Robust Pakistani currency heuristic fallback (`derh sau`, `dhai sau`, `hazar`, `lakh`, `crore`, preposition guardrails).
- Interactive draft confirmation card with inline field editing (amount, merchant, category, date, payment method, income/expense toggle).
- Fast pre-warmed native Android widget overlay (`VoiceWidgetActivity` + `VoiceTransactionParser`) allowing instant home-screen voice logging without full app launch.

Related:

- [[Voice Logging]]
- [[Gemini Voice]]
- [[Phase 5 Gemini Voice]]
- [[Add Transaction]]


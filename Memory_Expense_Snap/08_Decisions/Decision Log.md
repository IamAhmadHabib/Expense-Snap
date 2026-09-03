---
type: decisions
status: active
tags: [decisions, log]
---

# Decision Log

Use this note to link decisions.

## Current Decisions

- Prioritize explicit Pakistani and international brand merchant extraction (e.g. KFC, McDonald's, Cheezious, Shell, Total, PSO, Uber, Careem, InDrive, Bykea, Daraz, LESCO, SadaPay, etc.) ahead of generic category keywords in both Dart `GeminiVoiceExpenseParser` and Android Kotlin `VoiceTransactionParser` to eliminate generic fallbacks on recognizable brand names.
- Dynamically synchronize currency symbol formatting (`$currency 0`) between Flutter `AppSettingsRepository` and native Android `KharchaWidgetProvider` `RemoteViews`, ensuring home screen widgets display the user's selected currency symbol accurately without full app launches.
- Provide native Android Toast feedback upon speech recognition cancellation or silence timeout in `VoiceWidgetActivity` to avoid silent screen dismissals on the home screen wallpaper.
- Enforce strict word boundaries (`\b`) on numerical multipliers (`k\b`, `hazar\b`, `lakh\b`, `crore\b`) in both Flutter Dart and Android Kotlin voice parsers. This guarantees Urdu prepositions (`ka`, `ki`, `ke`) are never confused with the English `k` (thousands) multiplier, preventing 1000x amount inflation on colloquial spoken inputs.

- Implement in-widget voice logging using native Android `VoiceWidgetActivity` and `RecognizerIntent.ACTION_RECOGNIZE_SPEECH` to avoid opening the full Flutter app window, parsing and saving transactions directly into `FlutterSharedPreferences` and updating the widget `RemoteViews` on the home screen.

- Implement native Android Home Screen Widget via `home_widget` providing at-a-glance daily spending and one-tap deep links (`kharcha://capture/voice`, `kharcha://capture/scan`, `kharcha://capture/manual`) that open the app directly into the requested capture mode without blind background saves.

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

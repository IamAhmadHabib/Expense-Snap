---
type: code-map
status: active
tags: [code, transactions, voice, native-widget]
---

# Add Transaction Code

Sources:

- Flutter Form & Sheet: `kharcha/lib/features/transactions/add_transaction_sheet.dart`
- Fast Pre-warmed Voice Overlay: `kharcha/lib/features/transactions/widget_voice_overlay_screen.dart`
- Gemini Voice Parser Service: `kharcha/lib/services/gemini_voice_parser.dart`
- Speech Recognition Service: `kharcha/lib/services/speech_recognition_service.dart`
- Home Widget Service: `kharcha/lib/services/home_widget_service.dart`
- Native Android Widget Provider: `kharcha/android/app/src/main/kotlin/com/kharcha/kharcha/KharchaWidgetProvider.kt`
- Native Android In-Widget Voice Activity: `kharcha/android/app/src/main/kotlin/com/kharcha/kharcha/VoiceWidgetActivity.kt`
- Native Android Voice Parser: `kharcha/android/app/src/main/kotlin/com/kharcha/kharcha/VoiceTransactionParser.kt`

Behavior & Architecture:

- `_saveDraft` constructs a `TransactionDraft` and persists it to `TransactionRepository.saveDraft(...)`. If Firebase is enabled, it automatically triggers `AppSyncCoordinator.syncNow()`. `AddTransactionTab` selects the initial Manual, Scan, or Voice mode; new-entry default is Voice and edit default is Manual.
- Manual layout: the form is always vertically scrollable so its Save Expense action remains reachable across phone heights and keyboard states.
- In-Widget Instant Capture: Native `VoiceWidgetActivity` captures voice directly over home wallpaper, parses via `VoiceTransactionParser` (handling Urdu prepositions and Pakistani denominations), appends directly to `FlutterSharedPreferences`, and updates `KharchaWidgetProvider` in real time.

Related:

- [[Add Transaction]]
- [[Voice Tab]]
- [[Scan Tab]]
- [[Manual Tab]]
- [[Transactions]]
- [[Gemini Voice]]
- [[Voice Logging]]


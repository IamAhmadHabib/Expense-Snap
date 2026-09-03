---
type: decisions
status: active
tags: [decisions, log]
---

# Decision Log

Use this note to link decisions.

- Precision Budget Left Percentage: Updated the Home screen's budget hero card percentage badge from whole-number rounding to up to two decimal places precision (`_budgetLeftPercentageText`), displaying values like `84.92% left` or `84.9% left` while keeping whole integers clean (`80% left`).
- Native Android Floating Bottom Sheet Popups for Manual Add and Receipt Scan: Created `ManualWidgetActivity` and `ScanWidgetActivity` with `@style/TransparentTheme`, inheriting from `Activity` and `ComponentActivity` respectively to avoid `AppCompatActivity` theme requirement crashes. Both launch in <50ms without opening the Flutter app engine. Both feature `ViewCompat.setOnApplyWindowInsetsListener` reading `WindowInsetsCompat.Type.ime()` to automatically glide upward above the keyboard when input fields are focused.
- Modern Native Calendar Picker with Obsidian Theme: Created `ModernDatePickerDialogTheme` based on `android:Theme.DeviceDefault.Light.Dialog` with `android:datePickerMode="calendar"`, replacing dated Android 2.3 spinner columns with a clean native Material calendar grid styled in obsidian black (`#141210`) with white date typography.
- On-Device ML Kit Receipt OCR for Widget Scan: Added `com.google.android.gms:play-services-mlkit-text-recognition:19.0.1` and `ReceiptOcrParser.kt` to extract bill totals, store names, and categories in under 1 second entirely on-device, presenting a floating review card directly over the launcher.
- Multi-Size Home Screen Widget Suite (4x1, 2x2, 4x2): Expanded home screen widget offerings using `WidgetDataHelper.kt` to draw anti-aliased Canvas budget rings and weekly spending bar charts (`THIS WEEK`) with Monday-Sunday pill tracks, baseline dots, and today highlighted in amber gold. Qualified provider names in `HomeWidgetService` ensure compatibility with debug/release flavor package prefixes.
- Revamp Real-Time Insight AI on Analytics screen: Replaced static placeholder with a hybrid AI analytics engine (`AnalyticsAiService`) that dynamically evaluates the user's real transactions (category dominance, weekly velocity spikes, budget pacing, potential savings) with plain-English conversational tips. Replaced generic AI star sparkles with dignified financial trend icons (`PhosphorIcons.chartLineUp`), removed emojis from badges, and provided an interactive `InsightDetailSheet` with actionable steps and on-demand Gemini 2.5 Flash refresh.
- Activity Matrix 12-Month Scrollable Picker: Expanded the month selector from 4 static months to all 12 calendar months (Jan–Dec) inside a bounded scrollable list with persistent scrollbar thumbs and smooth physics.
- In-App Real-Time Sync from Android Widget: Added a native `BroadcastReceiver` (`com.kharcha.kharcha.TRANSACTION_ADDED`) and Flutter `MethodChannel("com.kharcha.app/sync")` paired with `TransactionRepository.reload()`. Any transaction added via the home screen widget is immediately refreshed into history, budget tally, weekly charts, and home screen without requiring manual app reloads.
- RenderFlex Overflow Prevention: Implemented `Flexible` and `Expanded` with `maxLines: 2` and `TextOverflow.ellipsis` on merchant names, transaction rows, and detail cards across `HistoryScreen` and `AddTransactionSheet` to safely handle long merchant labels on narrow screens.
- Voice Widget Touch Behavior & Pause Calibration: Configured the native voice bottom sheet to dismiss only on outside taps (`setCanceledOnTouchOutside(true)`), keeping the pop-up open when interacting inside the card or on non-field regions. Speech recognition automatically terminates on natural speaking pauses via native silence timeouts and speech debounce timers.
- STRICT DEPLOYMENT POLICY: NEVER push to GitHub automatically. ONLY push to GitHub when the user explicitly instructs to push. All code, design, and logic changes must be built, tested, and verified locally by the user first before pushing to remote.
- Implement instant native Android BottomSheetDialog for widget voice capture in `VoiceWidgetActivity`: Replace slow Google Assistant IPC with direct `SpeechRecognizer` binding, providing instant (<50ms) slide-up presentation, real-time acoustic waveform animations via `onRmsChanged`, and a Review & Confirm card with editable fields (Amount, Category, Merchant) before persisting to `FlutterSharedPreferences`.
- Tune speech pause tolerance across Flutter (`SpeechListenOptions.pauseFor = 4s`) and Android native recognizer (`EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS = 4000L`), allowing users 4 seconds of silence to think while speaking without premature speech termination.
- Overhaul category icons and container housings across the entire app: Eliminate literal cartoon icons (`hamburger`, `popcorn`, `car`, `pill`) and replace with mature, architectural metaphors (`forkKnife`, `carSimple`, `tote`, `ticket`, `firstAidKit`, `receipt`, `bookOpen`, `basket`, `airplaneTilt`, `tag`) using `PhosphorIconsStyle.fill` at 24px. Replace heavy solid black 52×52 boxes with 48×48 / 50×50 continuous-corner squircles tinted with centralized `AppColors` category pastels and matching rich foreground accents.
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

- [[ADR Note Template]]
- [[Product Decisions]]
- [[Technical Decisions]]

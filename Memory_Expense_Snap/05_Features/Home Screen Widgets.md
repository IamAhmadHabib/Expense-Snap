---
type: feature
status: implemented
tags: [widgets, native-android, quick-capture, ui-ux]
---

# Home Screen Widgets Suite

Multi-size native Android home screen widgets and zero-latency floating popups providing fast at-a-glance insight and instant expense logging.

## Components Implemented

### 1. Multi-Size Widget Providers
- **4x1 Quick Glance Widget** (`KharchaWidgetProvider.kt`):
  - Displays today's spend amount, transaction count, and currency.
  - Remaining monthly budget label and horizontal progress bar.
  - Three action shortcuts: Manual Add, Receipt Scan, Voice Capture.
- **2x2 Compact Quick-Log Widget** (`KharchaWidget2x2Provider.kt`):
  - Sized down to 82dp Canvas-drawn anti-aliased circular budget ring with today's spending amount in the center.
  - Remaining monthly budget subtitle below the ring.
  - Clean layout optimized for small launcher grid cells without clipping.
- **4x2 Executive Dashboard Widget** (`KharchaWidget4x2Provider.kt`):
  - Top row: Today's spending summary on left, remaining budget and percent spent on right.
  - Middle: Full-width horizontal budget progress bar.
  - Bottom: `THIS WEEK` spending chart with 7 rounded pill tracks (Monday–Sunday), baseline dots for 0 spend days, obsidian charcoal bars for active days, and today highlighted in amber gold.
  - Three quick-action shortcuts: Manual Add, Receipt Scan, Voice Mic.

### 2. Instant Native Floating Popups (<50ms Launch)
All widget actions open transparent floating bottom sheets without launching the full Flutter app engine:
- **Voice Capture** (`VoiceWidgetActivity.kt`):
  - Native `SpeechRecognizer` with acoustic waveform visualization and Review & Confirm card.
- **Manual Add** (`ManualWidgetActivity.kt`):
  - Hero amount input, quick-increment chips (`+100`, `+500`, `+1,000`, `+5,000`, `Clear`).
  - Category selector chips, payment method chips (*Cash, Card, EasyPaisa*).
  - Modern native Android calendar picker with obsidian black header and date indicator (`ModernDatePickerDialogTheme`).
  - Dynamic keyboard shifting: `ViewCompat.setOnApplyWindowInsetsListener` reading `WindowInsetsCompat.Type.ime()` to automatically glide the entire sheet above the soft keyboard.
- **Receipt Scan** (`ScanWidgetActivity.kt`):
  - Native camera capture.
  - On-device ML Kit OCR (`play-services-mlkit-text-recognition:19.0.1`) with `ReceiptOcrParser.kt` heuristic parser.
  - Floating review bottom sheet for confirming total and store name.

### 3. Data Synchronization & Persistence
- Directly parses and writes JSON transactions to `FlutterSharedPreferences` (`flutter.kharcha.transactions.v1`).
- Broadcasts `com.kharcha.kharcha.TRANSACTION_ADDED` to `MainActivity` so running Flutter repositories refresh immediately.
- Synchronously triggers `onUpdate()` across all 3 widget providers.

Related:
- [[Transactions]]
- [[Voice Logging]]
- [[OCR Scanning]]
- [[Decision Log]]

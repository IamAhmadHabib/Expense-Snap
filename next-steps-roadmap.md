# Kharcha (Expense Snap) - Next Steps & Implementation Roadmap

> **Task Slug**: `next-steps-roadmap`  
> **Project Type**: MOBILE (Flutter App + Android Native Kotlin Extensions)  
> **Status**: Active Plan  
> **Target Date**: 2026-09  

---

## 🎯 Overview & Context

Phases 1 through 5 of Kharcha are fully implemented and verified:
- **Phase 1-3**: Full High-Fidelity UI Shell, Local-First Data Spine (`TransactionRepository`, `AppSettingsRepository`), Profile & Budgeting.
- **Phase 4**: Firebase Authentication (Email/Password & Google OAuth), Firestore real-time/offline sync with Last-Write-Wins tombstones, and Firebase Storage attachments.
- **Phase 5**: Multilingual Gemini AI Voice Parsing (`GeminiVoiceExpenseParser`), STT (`SpeechRecognitionService`), Pakistani currency heuristic engine, and Native Android Home Screen Widget with in-widget voice capture overlay (`VoiceWidgetActivity` + `VoiceTransactionParser`).

This plan outlines the concrete next steps to advance Kharcha through **Phase 6 (OCR Scanning)**, **Phase 7 (Intelligence)**, **Phase 8 (Export Sync)**, and **Phase 9 (Launch Polish)**.

---

## 🚀 Success Criteria

1. **Phase 6 OCR**: Tapping receipt scan captures camera/gallery image, extracts total amount, merchant name, date, and items via on-device Google ML Kit, and allows inline draft editing before saving.
2. **Phase 7 Intelligence**: Analytics active-stat and insight copy display real derived multi-month trends without placeholder copy.
3. **Phase 8 Export**: Users can export expense history to formatted CSV or Google Sheets from Profile / Analytics settings.
4. **Phase 9 Release**: 100% test coverage, physical device 120 Hz performance verification, store icons, and launch readiness assets.

---

## 🛠️ Recommended Agent & Skill Routing

| Task Area | Assigned Agent | Recommended Skill |
| :--- | :--- | :--- |
| **Phase 6 OCR Scanning** | `mobile-developer` | `mobile-design`, `clean-code` |
| **Phase 7 Analytics Intelligence** | `mobile-developer` | `clean-code` |
| **Phase 8 Export & Sync** | `mobile-developer` | `clean-code` |
| **Phase 9 Launch Polish & Testing** | `mobile-developer` | `testing-patterns`, `mobile-design` |

---

## 📋 Task Breakdown

### Milestone 1: Phase 6 - Google ML Kit On-Device Receipt OCR Scanning

#### Task 1.1: Implement `MlKitOcrExpenseParser` Service
- **Agent**: `mobile-developer`
- **Skills**: `clean-code`
- **Dependencies**: `google_mlkit_text_recognition: ^0.15.0`, `image_picker: ^1.1.2`
- **INPUT**: Receipt image path (`OcrCaptureInput`)
- **OUTPUT**: Structured `CaptureParseResult` with extracted amount, merchant, date, category, and confidence score.
- **VERIFY**: Unit tests in `test/mlkit_ocr_parser_test.dart` verifying extraction heuristics on sample receipt text blocks.

#### Task 1.2: Wire Scan Tab UI (`_ScanTabView`) in `AddTransactionSheet`
- **Agent**: `mobile-developer`
- **Skills**: `mobile-design`, `clean-code`
- **Dependencies**: Task 1.1
- **INPUT**: User taps Scan tab in Add Transaction modal or Home Widget Scan shortcut (`kharcha://capture/scan`).
- **OUTPUT**: Live camera view / gallery selector, scanning loading animation, and interactive draft confirmation card with inline field editing.
- **VERIFY**: Widget tests in `test/phase_six_ocr_test.dart` verifying scan flow, draft display, and save.

---

### Milestone 2: Phase 7 - Intelligence & Predictive Analytics

#### Task 2.1: Derived Multi-Month Local Analytics Engine
- **Agent**: `mobile-developer`
- **Skills**: `clean-code`
- **Dependencies**: None
- **INPUT**: Local `TransactionRepository` history query across current and previous billing periods.
- **OUTPUT**: Real derived calculations for month-over-month velocity deltas, top category shift indicators, and daily spending velocity recommendations.
- **VERIFY**: Unit tests verifying analytics mathematical calculations across edge cases (zero spending, single transaction, multi-month trends).

---

### Milestone 3: Phase 8 - Export & Sync

#### Task 3.1: Expense CSV & Google Sheets Exporter
- **Agent**: `mobile-developer`
- **Skills**: `clean-code`
- **Dependencies**: `csv: ^6.0.0`, `share_plus: ^10.0.0`
- **INPUT**: Selected date range and filter criteria from Profile / Analytics settings.
- **OUTPUT**: Standardized CSV file generated locally and shared via native system share sheet.
- **VERIFY**: Unit tests verifying CSV header formatting, date/amount escaping, and currency column structure.

---

### Milestone 4: Phase 9 - Launch Polish & Release Verification

#### Task 4.1: Production Assets, App Icons & Release Verification
- **Agent**: `mobile-developer`
- **Skills**: `testing-patterns`, `mobile-design`
- **Dependencies**: Milestones 1-3
- **INPUT**: Final design assets and app configs.
- **OUTPUT**: High-resolution launcher icons (`flutter_launcher_icons`), FCM push notification service wiring, physical device 120Hz performance verification, and full test suite passing.
- **VERIFY**: Run `flutter test` and `.agent/scripts/verify_all.py`.

---

## 🧪 Phase X: Final Verification Checklist

- [ ] All unit and widget tests passing (`flutter test`)
- [ ] Security scan passing (`python .agent/skills/vulnerability-scanner/scripts/security_scan.py .`)
- [ ] UX audit passing (`python .agent/skills/frontend-design/scripts/ux_audit.py .`)
- [ ] Clean build verification (`flutter build apk --debug`)

---
type: feature
status: planned
tags: [ocr, scan]
---

# OCR Scanning

Planned OCR sources:

- Paper receipts.
- WhatsApp screenshots.
- Easypaisa/JazzCash screenshots.
- Bank app/payment screenshots.

Frontend readiness:

- `ExpenseCaptureAdapter<OcrCaptureInput>` exists.
- `AttachmentService` can create local attachment references and later map them to uploaded URLs.
- OCR parse results use the same `CaptureParseResult` and `TransactionDraft` save contract as voice/manual flows.
- Native Widget Receipt Scanning is now powered by on-device Google Play Services ML Kit Text Recognition (`com.google.android.gms:play-services-mlkit-text-recognition:19.0.1`) and deterministic heuristic regex parsing (`ReceiptOcrParser.kt`), extracting total amounts, merchant names, and category tagging in <1s entirely on-device without network latency.

Related:

- [[Scan Tab]]
- [[Phase 6 OCR]]
- [[Transactions]]

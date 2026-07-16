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
- Current implementation is a local simulated parser; ML Kit OCR is not connected yet.

Related:

- [[Scan Tab]]
- [[Phase 6 OCR]]
- [[Transactions]]

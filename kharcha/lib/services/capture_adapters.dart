import '../core/attachment_state.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';

abstract class ExpenseCaptureAdapter<Input> {
  Future<CaptureParseResult> parse(Input input);
}

class VoiceCaptureInput {
  final String transcript;
  final String locale;

  const VoiceCaptureInput({required this.transcript, this.locale = 'en-PK'});
}

class OcrCaptureInput {
  final AttachmentReference attachment;

  const OcrCaptureInput({required this.attachment});
}

class CaptureCorrection {
  final String? merchant;
  final String? category;
  final double? amount;
  final DateTime? date;
  final String? note;
  final String? method;
  final bool? isIncome;

  const CaptureCorrection({
    this.merchant,
    this.category,
    this.amount,
    this.date,
    this.note,
    this.method,
    this.isIncome,
  });
}

class CaptureParseResult {
  final TransactionDraft draft;
  final double confidence;
  final List<String> warnings;

  const CaptureParseResult({
    required this.draft,
    this.confidence = 0,
    this.warnings = const [],
  });

  CaptureParseResult applyCorrection(CaptureCorrection correction) {
    return CaptureParseResult(
      confidence: confidence,
      warnings: warnings,
      draft: TransactionDraft(
        merchant: correction.merchant ?? draft.merchant,
        category: correction.category ?? draft.category,
        amount: correction.amount ?? draft.amount,
        date: correction.date ?? draft.date,
        note: correction.note ?? draft.note,
        method: correction.method ?? draft.method,
        source: draft.source,
        isIncome: correction.isIncome ?? draft.isIncome,
      ),
    );
  }
}

TransactionDraft draftFromCapture({
  required String merchant,
  required String category,
  required double amount,
  required TransactionSource source,
  DateTime? date,
  String note = '',
  String method = 'Cash',
}) {
  return TransactionDraft(
    merchant: merchant,
    category: category,
    amount: amount,
    date: date ?? DateTime.now(),
    note: note,
    method: method,
    source: source,
  );
}

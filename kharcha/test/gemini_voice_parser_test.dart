import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/models/transaction_draft.dart';
import 'package:kharcha/services/capture_adapters.dart';
import 'package:kharcha/services/gemini_voice_parser.dart';

void main() {
  group('GeminiVoiceExpenseParser Local & Multilingual Heuristics', () {
    late GeminiVoiceExpenseParser parser;

    setUp(() {
      parser = GeminiVoiceExpenseParser();
    });

    test('parses Roman Urdu food expense with simple digits', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: 'Maine 300 rupay burger pe kharch kiye',
        ),
      );

      expect(result.draft.amount, 300);
      expect(result.draft.merchant, 'Burger');
      expect(result.draft.category, 'Food & Dining');
      expect(result.draft.method, 'Cash');
      expect(result.draft.isIncome, isFalse);
      expect(result.draft.source, TransactionSource.voice);
    });

    test('parses Roman Urdu ride share with Uber', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: '1200 uber pe lagaye',
        ),
      );

      expect(result.draft.amount, 1200);
      expect(result.draft.merchant, 'Uber');
      expect(result.draft.category, 'Transportation');
      expect(result.draft.isIncome, isFalse);
    });

    test('parses Pakistani colloquial denomination "dhai sau" (250) for petrol', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: 'dhai sau ka petrol dalwaya',
        ),
      );

      expect(result.draft.amount, 250);
      expect(result.draft.merchant, 'Petrol');
      expect(result.draft.category, 'Transportation');
    });

    test('parses Pakistani colloquial denomination "derh sau" (150) for chai', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: 'derh sau ki chai pi',
        ),
      );

      expect(result.draft.amount, 150);
      expect(result.draft.merchant, 'Chai');
      expect(result.draft.category, 'Food & Dining');
    });

    test('parses Pakistani colloquial denomination "hazar" and bills', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: '5 hazar bijli ka bill ada kiya',
        ),
      );

      expect(result.draft.amount, 5000);
      expect(result.draft.category, 'Bills & Utilities');
    });

    test('parses Pakistani denomination "lakh" and salary income', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: '1 lakh salary account mein aayi',
        ),
      );

      expect(result.draft.amount, 100000);
      expect(result.draft.isIncome, isTrue);
      expect(result.draft.category, 'Income');
    });

    test('parses English expense with card payment method', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(
          transcript: 'Spent 1500 at KFC paid by card',
        ),
      );

      expect(result.draft.amount, 1500);
      expect(result.draft.merchant, 'KFC');
      expect(result.draft.category, 'Food & Dining');
      expect(result.draft.method, 'Card');
    });

    test('handles empty transcript gracefully with warnings', () async {
      final result = await parser.parse(
        const VoiceCaptureInput(transcript: '   '),
      );

      expect(result.draft.amount, 0);
      expect(result.confidence, 0);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('No transcript'));
    });
  });

  group('TransactionDraft copyWith', () {
    test('correctly overrides specified fields while keeping others unchanged', () {
      final original = TransactionDraft(
        merchant: 'McDonalds',
        category: 'Food & Dining',
        amount: 850,
        date: DateTime(2026, 4, 1),
        note: 'Drive thru meal',
        method: 'Card',
        source: TransactionSource.voice,
        isIncome: false,
      );

      final updated = original.copyWith(
        amount: 950,
        note: 'Drive thru with extra fries',
      );

      expect(updated.amount, 950);
      expect(updated.note, 'Drive thru with extra fries');
      expect(updated.merchant, 'McDonalds');
      expect(updated.category, 'Food & Dining');
      expect(updated.method, 'Card');
      expect(updated.source, TransactionSource.voice);
      expect(updated.isIncome, isFalse);
      expect(updated.date, DateTime(2026, 4, 1));
    });
  });
}

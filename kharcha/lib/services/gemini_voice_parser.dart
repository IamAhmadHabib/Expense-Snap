import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import 'capture_adapters.dart';

/// Multilingual AI voice expense parser powered by Google Gemini (with local NLP fallback).
///
/// Accurately parses spoken expenses in Urdu, Roman Urdu, and English, resolving
/// Pakistani colloquial denominations (sau, dhai sau, hazar, lakh) and mapping to
/// Kharcha standard categories.
class GeminiVoiceExpenseParser
    implements ExpenseCaptureAdapter<VoiceCaptureInput> {
  final String? _apiKey;
  GenerativeModel? _model;

  GeminiVoiceExpenseParser({String? apiKey, GenerativeModel? model})
    : _apiKey = apiKey,
      _model = model;

  String get effectiveApiKey {
    final key = _apiKey;
    if (key != null && key.trim().isNotEmpty) {
      return key.trim();
    }
    return const String.fromEnvironment('GEMINI_API_KEY');
  }

  bool get hasApiKey => effectiveApiKey.isNotEmpty;

  GenerativeModel _getModel() {
    return _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: effectiveApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
      systemInstruction: Content.system(
        "You are Kharcha's multilingual financial assistant for expense tracking in Pakistan. "
        "You parse natural spoken expense inputs in Urdu, Roman Urdu, and English into structured JSON. "
        'Pakistani denominations: "sau" = 100, "dhai sau" = 250, "derh sau" = 150, "hazaar/hazar" = 1000, "lakh" = 100000. '
        'Always return a valid JSON object matching this schema exactly:\n'
        '{\n'
        '  "merchant": string (e.g. "Starbucks", "Burger", "Uber", "Petrol", "Grocery"),\n'
        '  "category": string (Must be one of: "Food & Dining", "Transportation", "Shopping", "Bills & Utilities", "Entertainment", "Health", "Income", "Other"),\n'
        '  "amount": number (positive numeric amount),\n'
        '  "method": string ("Cash", "Card", or "Transfer"),\n'
        '  "isIncome": boolean,\n'
        '  "note": string (short clean summary of what was purchased),\n'
        '  "confidence": number (between 0.0 and 1.0)\n'
        '}\n'
        'Do not include markdown or extra explanations. Output only pure JSON.',
      ),
    );
  }

  @override
  Future<CaptureParseResult> parse(VoiceCaptureInput input) async {
    final cleanTranscript = input.transcript.trim();
    if (cleanTranscript.isEmpty) {
      return CaptureParseResult(
        draft: draftFromCapture(
          merchant: 'Voice expense',
          category: 'Other',
          amount: 0,
          source: TransactionSource.voice,
        ),
        confidence: 0,
        warnings: const ['No transcript provided.'],
      );
    }

    if (hasApiKey) {
      try {
        final model = _getModel();
        final prompt = 'Parse this expense input: "$cleanTranscript"';
        final response = await model.generateContent([Content.text(prompt)]);
        final rawJson = response.text?.trim() ?? '';
        if (rawJson.isNotEmpty) {
          final parsed = jsonDecode(rawJson) as Map<String, dynamic>;
          final amount = (parsed['amount'] as num?)?.toDouble() ?? 0;
          final merchant = (parsed['merchant'] as String?)?.trim();
          final category = (parsed['category'] as String?)?.trim() ?? 'Other';
          final method = (parsed['method'] as String?)?.trim() ?? 'Cash';
          final isIncome = (parsed['isIncome'] as bool?) ?? false;
          final note = (parsed['note'] as String?)?.trim() ?? cleanTranscript;
          final confidence = (parsed['confidence'] as num?)?.toDouble() ?? 0.9;

          return CaptureParseResult(
            confidence: confidence,
            draft: TransactionDraft(
              merchant: (merchant != null && merchant.isNotEmpty)
                  ? merchant
                  : category,
              category: _normalizeCategory(category),
              amount: amount,
              date: DateTime.now(),
              note: note,
              method: method,
              source: TransactionSource.voice,
              isIncome: isIncome,
            ),
          );
        }
      } catch (error) {
        if (kDebugMode) {
          print('Gemini API parse failed ($error), using local fallback.');
        }
      }
    }

    // Graceful offline heuristic parser
    return parseLocally(cleanTranscript);
  }

  /// High-accuracy local heuristic parser for offline & fallback scenarios.
  static CaptureParseResult parseLocally(String transcript) {
    final lower = transcript.toLowerCase();

    // 1. Amount detection (Pakistani denominations + digits)
    double amount = _extractAmount(lower);

    // 2. Income vs Expense
    bool isIncome = false;
    final isExplicitExpense = lower.contains('kharch') ||
        lower.contains('lagaye') ||
        lower.contains('lagaya') ||
        lower.contains('diye') ||
        lower.contains('diya') ||
        lower.contains('spent') ||
        lower.contains('paid');
    if (!isExplicitExpense &&
        (lower.contains('salary') ||
            lower.contains('tankhwah') ||
            lower.contains('tankhah') ||
            lower.contains('cashback') ||
            lower.contains('income') ||
            lower.contains('aye') ||
            lower.contains('aaye') ||
            lower.contains('milay') ||
            lower.contains('mile') ||
            lower.contains('received'))) {
      isIncome = true;
    }

    // 3. Category & Merchant detection
    String category = 'Other';
    String merchant = 'Expense';

    if (lower.contains('uber') ||
        lower.contains('indrive') ||
        lower.contains('careem') ||
        lower.contains('petrol') ||
        lower.contains('fuel') ||
        lower.contains('rickshaw') ||
        lower.contains('taxi') ||
        lower.contains('bus') ||
        lower.contains('metro')) {
      category = 'Transportation';
      if (lower.contains('uber')) {
        merchant = 'Uber';
      } else if (lower.contains('indrive')) {
        merchant = 'InDrive';
      } else if (lower.contains('careem')) {
        merchant = 'Careem';
      } else if (lower.contains('petrol') || lower.contains('fuel')) {
        merchant = 'Petrol';
      } else {
        merchant = 'Ride';
      }
    } else if (lower.contains('burger') ||
        lower.contains('pizza') ||
        lower.contains('chai') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('starbucks') ||
        lower.contains('mcdonald') ||
        lower.contains('kfc') ||
        lower.contains('biryani') ||
        lower.contains('roti') ||
        lower.contains('khana') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('nashta')) {
      category = 'Food & Dining';
      if (lower.contains('burger')) {
        merchant = 'Burger';
      } else if (lower.contains('pizza')) {
        merchant = 'Pizza';
      } else if (lower.contains('chai') || lower.contains('tea')) {
        merchant = 'Chai';
      } else if (lower.contains('coffee') || lower.contains('starbucks')) {
        merchant = 'Starbucks';
      } else if (lower.contains('kfc')) {
        merchant = 'KFC';
      } else if (lower.contains('mcdonald')) {
        merchant = "McDonald's";
      } else {
        merchant = 'Food';
      }
    } else if (lower.contains('bijli') ||
        lower.contains('electricity') ||
        lower.contains('bill') ||
        lower.contains('gas') ||
        lower.contains('water') ||
        lower.contains('internet') ||
        lower.contains('wifi') ||
        lower.contains('recharge') ||
        lower.contains('load')) {
      category = 'Bills & Utilities';
      merchant = 'Utility Bill';
    } else if (lower.contains('daraz') ||
        lower.contains('shopping') ||
        lower.contains('kapray') ||
        lower.contains('shoes') ||
        lower.contains('grocery') ||
        lower.contains('mart') ||
        lower.contains('market')) {
      category = 'Shopping';
      merchant = lower.contains('daraz') ? 'Daraz' : 'Shopping';
    } else if (lower.contains('doctor') ||
        lower.contains('hospital') ||
        lower.contains('dawai') ||
        lower.contains('medicine') ||
        lower.contains('pharmacy')) {
      category = 'Health';
      merchant = 'Medical';
    } else if (lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('netflix') ||
        lower.contains('game')) {
      category = 'Entertainment';
      merchant = lower.contains('netflix') ? 'Netflix' : 'Entertainment';
    } else if (isIncome) {
      category = 'Income';
      merchant = 'Salary / Deposit';
    }

    // 4. Payment Method
    String method = 'Cash';
    if (lower.contains('card') ||
        lower.contains('debit') ||
        lower.contains('credit') ||
        lower.contains('visa')) {
      method = 'Card';
    } else if (lower.contains('sadapay') ||
        lower.contains('nayapay') ||
        lower.contains('bank') ||
        lower.contains('transfer') ||
        lower.contains('raast') ||
        lower.contains('easypaisa') ||
        lower.contains('jazzcash')) {
      method = 'Transfer';
    }

    return CaptureParseResult(
      confidence: 0.85,
      warnings: const ['Processed with local multilingual voice parser.'],
      draft: TransactionDraft(
        merchant: merchant,
        category: category,
        amount: amount,
        date: DateTime.now(),
        note: transcript,
        method: method,
        source: TransactionSource.voice,
        isIncome: isIncome,
      ),
    );
  }

  static double _extractAmount(String lower) {
    // Check colloquial compound words first
    if (lower.contains('dhai sau')) return 250;
    if (lower.contains('derh sau') || lower.contains('dedh sau')) return 150;
    if (lower.contains('dhai hazar') || lower.contains('dhai hazaar')) {
      return 2500;
    }
    if (lower.contains('derh hazar') || lower.contains('dedh hazaar')) {
      return 1500;
    }

    // Multiplier words: "2 hazar", "5 sau", "1 lakh"
    final multiplierMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(hazar|hazaar|k|sau|lakh)',
    ).firstMatch(lower);
    if (multiplierMatch != null) {
      final base = double.tryParse(multiplierMatch.group(1) ?? '') ?? 0;
      final unit = multiplierMatch.group(2) ?? '';
      if (unit.startsWith('hazar') ||
          unit.startsWith('hazaar') ||
          unit == 'k') {
        return base * 1000;
      }
      if (unit == 'sau') return base * 100;
      if (unit == 'lakh') return base * 100000;
    }

    // Standalone words
    if (lower.contains('ek hazar') ||
        lower.contains('hazar rupay') ||
        lower.contains('hazaar rupay')) {
      return 1000;
    }
    if (lower.contains('sau rupay') || lower.contains('ek sau')) {
      return 100;
    }
    if (lower.contains('ek lakh')) {
      return 100000;
    }

    // Standard digit match
    final digitMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    if (digitMatch != null) {
      return double.tryParse(digitMatch.group(1) ?? '') ?? 0;
    }

    return 0;
  }

  static String _normalizeCategory(String category) {
    final cleaned = category.trim();
    if (cleaned.toLowerCase().contains('food') ||
        cleaned.toLowerCase().contains('dining')) {
      return 'Food & Dining';
    }
    if (cleaned.toLowerCase().contains('transport')) {
      return 'Transportation';
    }
    if (cleaned.toLowerCase().contains('bill') ||
        cleaned.toLowerCase().contains('util')) {
      return 'Bills & Utilities';
    }
    if (cleaned.toLowerCase().contains('shop')) {
      return 'Shopping';
    }
    if (cleaned.toLowerCase().contains('health') ||
        cleaned.toLowerCase().contains('med')) {
      return 'Health';
    }
    if (cleaned.toLowerCase().contains('entertain')) {
      return 'Entertainment';
    }
    if (cleaned.toLowerCase().contains('income') ||
        cleaned.toLowerCase().contains('salary')) {
      return 'Income';
    }
    return cleaned.isNotEmpty ? cleaned : 'Other';
  }
}

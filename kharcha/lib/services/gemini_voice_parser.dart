import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/env_keys.dart';
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
    if (key != null) {
      return key.trim();
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }
    return EnvKeys.geminiApiKey;
  }

  bool get hasApiKey => effectiveApiKey.isNotEmpty;

  GenerativeModel _getModel() {
    return _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
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
        lower.contains('kharcha') ||
        lower.contains('lagaye') ||
        lower.contains('lagaya') ||
        lower.contains('diye') ||
        lower.contains('diya') ||
        lower.contains('bhare') ||
        lower.contains('bhara') ||
        lower.contains('spent') ||
        lower.contains('paid') ||
        lower.contains('ada') ||
        lower.contains('adaa') ||
        lower.contains('kharida') ||
        lower.contains('kharidi');

    if (!isExplicitExpense &&
        (lower.contains('salary') ||
            lower.contains('tankhwah') ||
            lower.contains('tankhah') ||
            lower.contains('tanha') ||
            lower.contains('wazifa') ||
            lower.contains('stipend') ||
            lower.contains('bonus') ||
            lower.contains('freelance') ||
            lower.contains('client') ||
            lower.contains('upwork') ||
            lower.contains('fiverr') ||
            lower.contains('kamayi') ||
            lower.contains('munafa') ||
            lower.contains('profit') ||
            lower.contains('cashback') ||
            lower.contains('refund') ||
            lower.contains('eidi') ||
            lower.contains('salami') ||
            lower.contains('income') ||
            lower.contains('aye') ||
            lower.contains('aaye') ||
            lower.contains('milay') ||
            lower.contains('mile') ||
            lower.contains('wasool') ||
            lower.contains('received') ||
            lower.contains('jama') ||
            lower.contains('deposit'))) {
      isIncome = true;
    }

    // 3. Category & Merchant detection
    String category = 'Other';
    String merchant = 'Expense';

    final foodKeywords = [
      'food', 'lunch', 'dinner', 'breakfast', 'burger', 'pizza', 'chai', 'tea', 'coffee',
      'starbucks', 'biryani', 'pulao', 'karahi', 'handi', 'tikka', 'boti', 'kebab', 'kabab',
      'nihari', 'haleem', 'daal', 'sabzi', 'roti', 'salan', 'naan', 'paratha', 'pratha',
      'roll', 'shawarma', 'shwarma', 'kfc', 'mcdonalds', 'mcdonald', 'subway', 'optp',
      'hardees', 'dominos', 'cheezious', 'ranchers', 'gloria jeans', 'tim hortons',
      'samosa', 'samose', 'pakora', 'pakoray', 'chaat', 'gol gappay', 'gol gappe', 'dahi bhallay',
      'jalebi', 'halwa', 'mithai', 'ice cream', 'kulfi', 'falooda', 'doodh patti', 'lassi',
      'juice', 'shake', 'nashta', 'sehri', 'iftar', 'iftari', 'snack', 'snacks', 'restaurant',
      'cafe', 'dhabba', 'dhaba', 'hotel', 'canteen', 'khana', 'khanay', 'broast'
    ];

    final transportKeywords = [
      'uber', 'careem', 'indrive', 'bykea', 'yango', 'petrol', 'fuel', 'diesel', 'cng',
      'hawa', 'puncture', 'panchar', 'mobil oil', 'servicing', 'car wash', 'rickshaw',
      'rikshaw', 'chingchi', 'chinchi', 'taxi', 'cab', 'bus', 'wagon', 'van', 'metro',
      'speedo', 'orange line', 'train', 'railway', 'ticket', 'flight', 'pia', 'fare',
      'kiraya', 'karaya', 'toll', 'm-tag', 'mtag', 'parking', 'chalan', 'challan', 'ride',
      'car', 'bike'
    ];

    final billKeywords = [
      'electricity', 'bijli', 'electric', 'lesco', 'kelectric', 'k-electric', 'iesco',
      'mepco', 'gepco', 'pesco', 'bill', 'gas', 'sui gas', 'ssgc', 'sngpl', 'cylinder',
      'water', 'pani', 'wasa', 'tanker', 'internet', 'wifi', 'ptcl', 'nayatel', 'stormfiber',
      'mobile', 'phone', 'sim', 'recharge', 'load', 'balance', 'package', 'jazz', 'telenor',
      'zong', 'ufone', 'easypaisa', 'jazzcash', 'fee', 'fees', 'tuition', 'academy',
      'rent', 'kiraya makaan', 'maintenance', 'kamiti', 'committee'
    ];

    final shoppingKeywords = [
      'grocery', 'groceries', 'sauda', 'rashan', 'ration', 'doodh', 'milk', 'dahi', 'yogurt',
      'makhan', 'butter', 'paneer', 'cheese', 'anday', 'ande', 'eggs', 'bread', 'double roti',
      'atta', 'flour', 'chawal', 'rice', 'cheeni', 'sugar', 'patti', 'oil', 'ghee', 'masalay',
      'spices', 'sabzi', 'vegetables', 'aaloo', 'pyaz', 'tamatar', 'gosht', 'meat', 'chicken',
      'beef', 'mutton', 'machli', 'fish', 'phal', 'fruits', 'sayb', 'kela', 'aam', 'supermarket',
      'mart', 'store', 'imtiaz', 'carrefour', 'alfatah', 'chase up', 'clothes', 'shirt',
      'shoes', 'pants', 'shopping', 'mall', 'daraz', 'amazon', 'kapray', 'kapre', 'jora',
      'suit', 'shalwar', 'kameez', 'kurta', 'jootay', 'joote', 'chappal', 'slippers',
      'sneakers', 'socks', 'bag', 'wallet', 'watch', 'ghari', 'makeup', 'cosmetics',
      'perfume', 'itr', 'attar', 'bazaar', 'market', 'emporium', 'packages', 'centaurus',
      'dolmen'
    ];

    final healthKeywords = [
      'medicine', 'medicines', 'doctor', 'hospital', 'pharmacy', 'panadol', 'dawa', 'dawai',
      'dawaai', 'tablet', 'syrup', 'injection', 'drip', 'disprin', 'arinac', 'brufen',
      'augmentin', 'bandage', 'checkup', 'clinic', 'dispensary', 'medical store', 'd-watson',
      'fazal din', 'shifa', 'aga khan', 'lab', 'test', 'blood test', 'x-ray', 'ultrasound',
      'dentist'
    ];

    final entertainmentKeywords = [
      'movie', 'cinema', 'film', 'cue cinema', 'cinepax', 'nueplex', 'popcorn', 'netflix',
      'spotify', 'youtube', 'game', 'gaming', 'steam', 'playstation', 'ps5', 'pubg', 'outing',
      'picnic', 'park', 'bowling', 'snooker', 'cricket', 'match', 'party', 'treat', 'concert'
    ];

    if (isIncome) {
      category = 'Income';
      merchant = 'Salary / Deposit';
    } else {
      // 3.1 Check explicit brand merchant matches first
      final explicitBrandMap = <String, Map<String, String>>{
        'kfc': {'cat': 'Food & Dining', 'merch': 'KFC'},
        'mcdonalds': {'cat': 'Food & Dining', 'merch': "McDonald's"},
        'mcdonald': {'cat': 'Food & Dining', 'merch': "McDonald's"},
        'cheezious': {'cat': 'Food & Dining', 'merch': 'Cheezious'},
        'ranchers': {'cat': 'Food & Dining', 'merch': 'Ranchers'},
        'subway': {'cat': 'Food & Dining', 'merch': 'Subway'},
        'optp': {'cat': 'Food & Dining', 'merch': 'OPTP'},
        'dominos': {'cat': 'Food & Dining', 'merch': "Domino's"},
        'hardees': {'cat': 'Food & Dining', 'merch': "Hardee's"},
        'starbucks': {'cat': 'Food & Dining', 'merch': 'Starbucks'},
        'gloria jeans': {'cat': 'Food & Dining', 'merch': "Gloria Jean's"},
        'tim hortons': {'cat': 'Food & Dining', 'merch': 'Tim Hortons'},
        'shell': {'cat': 'Transportation', 'merch': 'Shell'},
        'total': {'cat': 'Transportation', 'merch': 'Total Fuel'},
        'pso': {'cat': 'Transportation', 'merch': 'PSO'},
        'attock': {'cat': 'Transportation', 'merch': 'Attock Petroleum'},
        'uber': {'cat': 'Transportation', 'merch': 'Uber'},
        'careem': {'cat': 'Transportation', 'merch': 'Careem'},
        'indrive': {'cat': 'Transportation', 'merch': 'InDrive'},
        'bykea': {'cat': 'Transportation', 'merch': 'Bykea'},
        'yango': {'cat': 'Transportation', 'merch': 'Yango'},
        'imtiaz': {'cat': 'Shopping', 'merch': 'Imtiaz Super Market'},
        'carrefour': {'cat': 'Shopping', 'merch': 'Carrefour'},
        'alfatah': {'cat': 'Shopping', 'merch': 'Al-Fatah'},
        'chase up': {'cat': 'Shopping', 'merch': 'Chase Up'},
        'daraz': {'cat': 'Shopping', 'merch': 'Daraz'},
        'amazon': {'cat': 'Shopping', 'merch': 'Amazon'},
        'lesco': {'cat': 'Bills & Utilities', 'merch': 'LESCO'},
        'kelectric': {'cat': 'Bills & Utilities', 'merch': 'K-Electric'},
        'k-electric': {'cat': 'Bills & Utilities', 'merch': 'K-Electric'},
        'iesco': {'cat': 'Bills & Utilities', 'merch': 'IESCO'},
        'mepco': {'cat': 'Bills & Utilities', 'merch': 'MEPCO'},
        'gepco': {'cat': 'Bills & Utilities', 'merch': 'GEPCO'},
        'pesco': {'cat': 'Bills & Utilities', 'merch': 'PESCO'},
        'sui gas': {'cat': 'Bills & Utilities', 'merch': 'Sui Gas'},
        'ssgc': {'cat': 'Bills & Utilities', 'merch': 'SSGC'},
        'sngpl': {'cat': 'Bills & Utilities', 'merch': 'SNGPL'},
        'nayatel': {'cat': 'Bills & Utilities', 'merch': 'Nayatel'},
        'stormfiber': {'cat': 'Bills & Utilities', 'merch': 'StormFiber'},
        'ptcl': {'cat': 'Bills & Utilities', 'merch': 'PTCL'},
        'sadapay': {'cat': 'Bills & Utilities', 'merch': 'SadaPay'},
        'nayapay': {'cat': 'Bills & Utilities', 'merch': 'NayaPay'},
        'd-watson': {'cat': 'Health', 'merch': 'D-Watson'},
        'fazal din': {'cat': 'Health', 'merch': 'Fazal Din'},
        'shifa': {'cat': 'Health', 'merch': 'Shifa Hospital'},
        'aga khan': {'cat': 'Health', 'merch': 'Aga Khan Hospital'},
        'cinepax': {'cat': 'Entertainment', 'merch': 'Cinepax'},
        'nueplex': {'cat': 'Entertainment', 'merch': 'Nueplex'},
        'cue cinema': {'cat': 'Entertainment', 'merch': 'Cue Cinema'},
        'netflix': {'cat': 'Entertainment', 'merch': 'Netflix'},
        'spotify': {'cat': 'Entertainment', 'merch': 'Spotify'},
        'pubg': {'cat': 'Entertainment', 'merch': 'PUBG'},
      };

      String? matchedBrandCategory;
      String? matchedBrandMerchant;
      for (final entry in explicitBrandMap.entries) {
        if (lower.contains(entry.key)) {
          matchedBrandCategory = entry.value['cat'];
          matchedBrandMerchant = entry.value['merch'];
          break;
        }
      }

      if (matchedBrandCategory != null && matchedBrandMerchant != null) {
        category = matchedBrandCategory;
        merchant = matchedBrandMerchant;
      } else if (foodKeywords.any((kw) => lower.contains(kw))) {
      category = 'Food & Dining';
      if (lower.contains('burger')) {
        merchant = 'Burger';
      } else if (lower.contains('pizza')) {
        merchant = 'Pizza';
      } else if (lower.contains('chai') || lower.contains('tea')) {
        merchant = 'Chai';
      } else if (lower.contains('coffee') || lower.contains('starbucks')) {
        merchant = 'Coffee';
      } else if (lower.contains('kfc')) {
        merchant = 'KFC';
      } else if (lower.contains('mcdonald')) {
        merchant = "McDonald's";
      } else if (lower.contains('biryani')) {
        merchant = 'Biryani';
        } else {
          merchant = 'Food';
        }
      } else if (billKeywords.any((kw) => lower.contains(kw))) {
        category = 'Bills & Utilities';
        if (lower.contains('bijli') || lower.contains('electric')) {
          merchant = 'Electricity Bill';
        } else if (lower.contains('gas')) {
          merchant = 'Gas Bill';
        } else if (lower.contains('wifi') || lower.contains('internet')) {
          merchant = 'Internet Bill';
        } else {
          merchant = 'Utility Bill';
        }
      } else if (healthKeywords.any((kw) => lower.contains(kw))) {
        category = 'Health';
        merchant = 'Medical';
      } else if (entertainmentKeywords.any((kw) => lower.contains(kw))) {
        category = 'Entertainment';
        merchant = lower.contains('netflix') ? 'Netflix' : 'Entertainment';
      } else if (transportKeywords.any((kw) => lower.contains(kw))) {
        category = 'Transportation';
        if (lower.contains('uber')) {
          merchant = 'Uber';
        } else if (lower.contains('indrive')) {
          merchant = 'InDrive';
        } else if (lower.contains('careem')) {
          merchant = 'Careem';
        } else if (lower.contains('bykea')) {
          merchant = 'Bykea';
        } else if (lower.contains('petrol') || lower.contains('fuel')) {
          merchant = 'Petrol';
        } else {
          merchant = 'Ride';
        }
      } else if (shoppingKeywords.any((kw) => lower.contains(kw))) {
        category = 'Shopping';
        if (lower.contains('daraz')) {
          merchant = 'Daraz';
        } else if (lower.contains('doodh') || lower.contains('milk')) {
          merchant = 'Milk / Dairy';
        } else {
          merchant = 'Shopping';
        }
      }
    }

    // 4. Payment Method
    String method = 'Cash';
    if (lower.contains('card') ||
        lower.contains('debit') ||
        lower.contains('credit') ||
        lower.contains('visa') ||
        lower.contains('mastercard')) {
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
    // 1. Pakistani colloquial compound denominations
    if (lower.contains('derh sau') || lower.contains('dedh sau') || lower.contains('derh so') || lower.contains('dedh so')) return 150;
    if (lower.contains('dhai sau') || lower.contains('dhai so') || lower.contains('adhaai sau') || lower.contains('adhai sau')) return 250;
    if (lower.contains('paune do sau') || lower.contains('poney do sau')) return 175;
    if (lower.contains('sawa do sau')) return 225;
    if (lower.contains('paune sau') || lower.contains('poney sau')) return 75;
    if (lower.contains('sawa sau')) return 125;
    if (lower.contains('derh hazar') || lower.contains('dedh hazar') || lower.contains('derh hazaar') || lower.contains('dedh hazaar')) return 1500;
    if (lower.contains('dhai hazar') || lower.contains('dhai hazaar') || lower.contains('adhaai hazar')) return 2500;
    if (lower.contains('sade teen hazar') || lower.contains('sarhe teen hazar')) return 3500;
    if (lower.contains('sade char hazar') || lower.contains('sarhe char hazar')) return 4500;
    if (lower.contains('sade panch hazar') || lower.contains('sarhe panch hazar')) return 5500;
    if (lower.contains('paune hazar') || lower.contains('poney hazar')) return 750;
    if (lower.contains('sawa lakh')) return 125000;
    if (lower.contains('derh lakh') || lower.contains('dedh lakh')) return 150000;
    if (lower.contains('dhai lakh') || lower.contains('adhaai lakh')) return 250000;
    if (lower.contains('sade teen lakh') || lower.contains('sarhe teen lakh')) return 350000;

    // 2. Multipliers with strict word boundaries: hazar, lakh, crore, sau, k
    // Important: \b ensures Urdu prepositions "ka", "ki", "ke", "kay" NEVER match "k"
    final multiplierMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(crore\b|kror\b|cr\b|lakh\b|lac\b|lacs\b|laakh\b|hazar\b|hazaar\b|thousand\b|sau\b|so\b|k\b)',
    ).firstMatch(lower);
    if (multiplierMatch != null) {
      final base = double.tryParse(multiplierMatch.group(1) ?? '') ?? 0;
      final unit = multiplierMatch.group(2) ?? '';
      if (unit == 'crore' || unit == 'kror' || unit == 'cr') return base * 10000000;
      if (unit.startsWith('lakh') || unit.startsWith('lac') || unit == 'laakh' || unit == 'lacs') {
        return base * 100000;
      }
      if (unit.startsWith('hazar') ||
          unit.startsWith('hazaar') ||
          unit == 'thousand' ||
          unit == 'k') {
        return base * 1000;
      }
      if (unit == 'sau' || unit == 'so') return base * 100;
    }

    // 3. Standalone words
    if (lower.contains('ek crore') || lower.contains('ek kror')) return 10000000;
    if (lower.contains('ek lakh') || lower.contains('aik lakh')) return 100000;
    if (lower.contains('ek hazar') || lower.contains('aik hazar') || lower.contains('hazar rupay') || lower.contains('hazaar rupay')) {
      return 1000;
    }
    if (lower.contains('sau rupay') || lower.contains('so rupay') || lower.contains('ek sau') || lower.contains('aik sau')) {
      return 100;
    }

    // 4. Standard digit match
    final digitMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower.replaceAll(',', ''));
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

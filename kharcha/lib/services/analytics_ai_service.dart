import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import 'gemini_voice_parser.dart';

enum InsightType {
  opportunity,
  surge,
  optimal,
  pattern,
}

class FinancialInsight {
  final String title;
  final String badgeText;
  final String headline;
  final String body;
  final double potentialSavings;
  final String topCategory;
  final double topCategorySpend;
  final double topCategoryPercentage;
  final List<String> actionableTips;
  final InsightType type;
  final DateTime generatedAt;
  final bool isAiGenerated;

  const FinancialInsight({
    required this.title,
    required this.badgeText,
    required this.headline,
    required this.body,
    required this.potentialSavings,
    required this.topCategory,
    required this.topCategorySpend,
    required this.topCategoryPercentage,
    required this.actionableTips,
    required this.type,
    required this.generatedAt,
    this.isAiGenerated = false,
  });
}

/// Hybrid AI Analytics Engine that computes deterministic financial metrics
/// locally from real transactions and elevates deep dives with Gemini 2.5 Flash.
class AnalyticsAiService {
  final GeminiVoiceExpenseParser _parser;

  AnalyticsAiService({GeminiVoiceExpenseParser? parser})
      : _parser = parser ?? GeminiVoiceExpenseParser();

  FinancialInsight generateInsight({
    required List<Transaction> transactions,
    required double monthlyBudget,
    required String currency,
  }) {
    final now = DateTime.now();
    final expenseTransactions = transactions
        .where((t) => !t.isIncome && t.date.year == now.year && t.date.month == now.month)
        .toList();

    if (expenseTransactions.isEmpty) {
      return FinancialInsight(
        title: 'Clean Slate This Month',
        badgeText: 'NEW MONTH',
        headline: 'No expenses recorded this month yet',
        body: 'Start logging your daily expenses via voice, receipt scan, or widget to see helpful tips on where you can save.',
        potentialSavings: 0.0,
        topCategory: 'None',
        topCategorySpend: 0.0,
        topCategoryPercentage: 0.0,
        actionableTips: const [
          'Use the widget mic to record your expenses in just a few seconds.',
          'Decide on a weekly spending target to keep yourself on track.',
          'Check any upcoming monthly bills so you are ready for them.',
        ],
        type: InsightType.optimal,
        generatedAt: now,
      );
    }

    final totalMonthSpend = expenseTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Group by category
    final categoryMap = <String, double>{};
    for (final t in expenseTransactions) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0.0) + t.amount;
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntry = sortedCategories.first;
    final topCategory = topEntry.key;
    final topSpend = topEntry.value;
    final topPercent = totalMonthSpend > 0 ? (topSpend / totalMonthSpend) * 100 : 0.0;

    // Weekly velocity check: compare this week vs last week
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekEnd = weekStart.subtract(const Duration(milliseconds: 1));

    final thisWeekSpend = transactions
        .where((t) => !t.isIncome && t.date.isAfter(weekStart.subtract(const Duration(milliseconds: 1))))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final lastWeekSpend = transactions
        .where((t) => !t.isIncome && t.date.isAfter(prevWeekStart) && t.date.isBefore(prevWeekEnd))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final NumberFormat currencyFormat = NumberFormat('#,###');
    final formattedTopSpend = '$currency ${currencyFormat.format(topSpend.toInt())}';

    // 1. High category dominance (>= 35% of monthly spend and at least 1000 spend)
    if (topPercent >= 35.0 && topSpend >= 1000) {
      final potentialSavings = (topSpend * 0.15).roundToDouble();
      final formattedSavings = '$currency ${currencyFormat.format(potentialSavings.toInt())}';

      return FinancialInsight(
        title: 'High $topCategory Spending',
        badgeText: 'SAVINGS OPPORTUNITY',
        headline: 'You spent $formattedTopSpend on $topCategory (${topPercent.toStringAsFixed(0)}% of your expenses)',
        body: '$topCategory is where most of your money went this month. Cutting back just a little bit can easily put $formattedSavings back in your pocket.',
        potentialSavings: potentialSavings,
        topCategory: topCategory,
        topCategorySpend: topSpend,
        topCategoryPercentage: topPercent,
        actionableTips: [
          'Try to spend less than $currency ${currencyFormat.format((topSpend * 0.85 / 4).round())} a week on $topCategory.',
          'Swap 2 expensive $topCategory orders or purchases with simpler, cheaper choices.',
          'Keep an eye on $topCategory so it does not take over the rest of your monthly budget.',
        ],
        type: InsightType.opportunity,
        generatedAt: now,
      );
    }

    // 2. Spending spike: this week vs last week
    if (lastWeekSpend > 0 && thisWeekSpend > lastWeekSpend * 1.3) {
      final excess = thisWeekSpend - lastWeekSpend;
      final formattedExcess = '$currency ${currencyFormat.format(excess.toInt())}';

      return FinancialInsight(
        title: 'Higher Spending This Week',
        badgeText: 'SPENDING SPIKE',
        headline: 'You spent $formattedExcess more this week than last week',
        body: 'Money went out faster than usual this week, mostly on $topCategory. Taking a small break from extra shopping for a couple of days will help balance things out.',
        potentialSavings: (excess * 0.5).roundToDouble(),
        topCategory: topCategory,
        topCategorySpend: topSpend,
        topCategoryPercentage: topPercent,
        actionableTips: [
          'Take a 2-day break from buying non-essential items.',
          'Look over weekend outings or food deliveries to see where you can cut back.',
          'Try to keep your daily spending under $currency ${currencyFormat.format(((monthlyBudget - totalMonthSpend) / (30 - now.day).clamp(1, 30)).round())} for the rest of the month.',
        ],
        type: InsightType.surge,
        generatedAt: now,
      );
    }

    // 3. Optimal budget trajectory
    if (monthlyBudget > 0 && totalMonthSpend < (monthlyBudget * (now.day / 31))) {
      final buffer = (monthlyBudget * (now.day / 31)) - totalMonthSpend;
      final formattedBuffer = '$currency ${currencyFormat.format(buffer.toInt())}';

      return FinancialInsight(
        title: 'Great Budget Control',
        badgeText: 'ON TRACK',
        headline: 'You are $formattedBuffer under your planned spending',
        body: 'You are doing a great job keeping expenses low this month, which leaves extra cash in your pocket.',
        potentialSavings: buffer.roundToDouble(),
        topCategory: topCategory,
        topCategorySpend: topSpend,
        topCategoryPercentage: topPercent,
        actionableTips: [
          'Put your extra saved money straight into savings so you do not spend it.',
          'Keep sticking to your usual daily limit of $currency ${currencyFormat.format((totalMonthSpend / now.day).round())}.',
          'Watch out for sudden end-of-month splurges so you keep what you saved.',
        ],
        type: InsightType.optimal,
        generatedAt: now,
      );
    }

    // 4. Default Balanced Insight
    final potentialSavings = (totalMonthSpend * 0.10).roundToDouble();
    final formattedSavings = '$currency ${currencyFormat.format(potentialSavings.toInt())}';
    return FinancialInsight(
      title: 'Even Spending Spread',
      badgeText: 'SPENDING OVERVIEW',
      headline: 'You spent $formattedTopSpend across ${sortedCategories.length} different categories',
      body: 'Your spending is spread across different categories, with $topCategory at the top. Cutting down on small daily habits can save you about $formattedSavings.',
      potentialSavings: potentialSavings,
      topCategory: topCategory,
      topCategorySpend: topSpend,
      topCategoryPercentage: topPercent,
      actionableTips: [
        'Watch out for small everyday purchases under $currency 500—they add up fast.',
        'Record your cash expenses right away so you do not lose track of any.',
        'Take a quick look at your weekly spending chart to make sure you stay on track.',
      ],
      type: InsightType.pattern,
      generatedAt: now,
    );
  }

  Future<FinancialInsight> generateGeminiDeepDive({
    required FinancialInsight baseInsight,
    required List<Transaction> transactions,
    required double monthlyBudget,
    required String currency,
  }) async {
    if (!_parser.hasApiKey) {
      return baseInsight;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _parser.effectiveApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.2,
        ),
      );

      final now = DateTime.now();
      final recent = transactions
          .where((t) => !t.isIncome && t.date.year == now.year && t.date.month == now.month)
          .take(15)
          .map((t) => '${t.category}: ${t.amount} (${t.merchant})')
          .join(', ');

      final prompt = '''
You are Kharcha, a friendly and practical personal finance assistant.
Analyze these user transactions for this month:
Recent transactions: $recent
Top category: ${baseInsight.topCategory} (${baseInsight.topCategorySpend} $currency, ${baseInsight.topCategoryPercentage.toStringAsFixed(1)}% of expenses)
Monthly Budget: $monthlyBudget $currency

IMPORTANT: Use simple, plain, friendly language that a normal person can easily understand. Do NOT use technical financial terms or business jargon. Do NOT include any emoji in badgeText.

Provide a structured JSON response with:
{
  "title": "Short friendly title (3-5 simple words)",
  "badgeText": "STATUS BADGE (2-3 words, ALL CAPS, NO EMOJI)",
  "headline": "One clear sentence explaining spending in plain English",
  "body": "2 short simple sentences explaining what happened and how to save money easily",
  "potentialSavings": numeric_saving_amount,
  "actionableTips": [
    "Simple, practical tip 1",
    "Simple, practical tip 2",
    "Simple, practical tip 3"
  ]
}
Return ONLY valid JSON.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text != null && text.trim().isNotEmpty) {
        final data = jsonDecode(text) as Map<String, dynamic>;
        final tips = (data['actionableTips'] as List?)
                ?.map((e) => e.toString())
                .take(3)
                .toList() ??
            baseInsight.actionableTips;

        return FinancialInsight(
          title: data['title']?.toString() ?? baseInsight.title,
          badgeText: data['badgeText']?.toString().replaceAll(RegExp(r'[^\w\s]'), '').trim() ?? baseInsight.badgeText,
          headline: data['headline']?.toString() ?? baseInsight.headline,
          body: data['body']?.toString() ?? baseInsight.body,
          potentialSavings: (data['potentialSavings'] as num?)?.toDouble() ??
              baseInsight.potentialSavings,
          topCategory: baseInsight.topCategory,
          topCategorySpend: baseInsight.topCategorySpend,
          topCategoryPercentage: baseInsight.topCategoryPercentage,
          actionableTips: tips,
          type: baseInsight.type,
          generatedAt: DateTime.now(),
          isAiGenerated: true,
        );
      }
    } catch (e) {
      debugPrint('Gemini deep dive fallback to heuristic insight: $e');
    }

    return baseInsight;
  }
}

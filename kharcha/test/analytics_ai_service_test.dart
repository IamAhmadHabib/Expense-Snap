import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/services/analytics_ai_service.dart';

void main() {
  group('AnalyticsAiService Tests', () {
    late AnalyticsAiService service;

    setUp(() {
      service = AnalyticsAiService();
    });

    test('returns clean slate insight when no transactions exist', () {
      final insight = service.generateInsight(
        transactions: [],
        monthlyBudget: 50000,
        currency: 'Rs.',
      );

      expect(insight.title, 'Clean Slate This Month');
      expect(insight.potentialSavings, 0.0);
      expect(insight.actionableTips.length, 3);
    });

    test('detects high category dominance and calculates 15% savings', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          id: '1',
          amount: 6000,
          category: 'Food',
          merchant: 'KFC',
          date: now,
          isIncome: false,
        ),
        Transaction(
          id: '2',
          amount: 2000,
          category: 'Transport',
          merchant: 'Uber',
          date: now,
          isIncome: false,
        ),
      ];

      final insight = service.generateInsight(
        transactions: transactions,
        monthlyBudget: 50000,
        currency: 'Rs.',
      );

      expect(insight.topCategory, 'Food');
      expect(insight.badgeText, 'SAVINGS OPPORTUNITY');
      expect(insight.potentialSavings, 900.0); // 15% of 6000
      expect(insight.actionableTips.length, 3);
      expect(insight.actionableTips.first, contains('Food'));
    });

    test('detects disciplined capital flow when pacing under budget', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          id: '1',
          amount: 150,
          category: 'Bills',
          merchant: 'Utility',
          date: now,
          isIncome: false,
        ),
      ];

      final insight = service.generateInsight(
        transactions: transactions,
        monthlyBudget: 100000,
        currency: 'Rs.',
      );

      expect(insight.badgeText, 'ON TRACK');
      expect(insight.type, InsightType.optimal);
      expect(insight.potentialSavings, greaterThan(0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/models/app_settings.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/services/home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HomeWidgetService updateWidgetData completes gracefully', () async {
    final transactions = [
      Transaction(
        id: 'tx-1',
        merchant: 'Lunch',
        amount: 450,
        category: 'Food & Dining',
        date: DateTime.now(),
        isIncome: false,
        source: TransactionSource.manual,
      ),
      Transaction(
        id: 'tx-2',
        merchant: 'Salary',
        amount: 50000,
        category: 'Income',
        date: DateTime.now(),
        isIncome: true,
        source: TransactionSource.manual,
      ),
    ];

    const settings = AppSettings(
      currencySymbol: 'Rs.',
    );

    await expectLater(
      HomeWidgetService.updateWidgetData(
        transactions: transactions,
        settings: settings,
      ),
      completes,
    );
  });

  test('HomeWidgetService registerClickCallback completes without throwing', () {
    final sub = HomeWidgetService.registerClickCallback((_) {});
    sub?.cancel();
  });

  test('HomeWidgetService declares all 3 widget provider constants', () {
    expect(HomeWidgetService.androidWidgetProvider, 'KharchaWidgetProvider');
    expect(HomeWidgetService.androidWidget2x2Provider, 'KharchaWidget2x2Provider');
    expect(HomeWidgetService.androidWidget4x2Provider, 'KharchaWidget4x2Provider');
  });
}

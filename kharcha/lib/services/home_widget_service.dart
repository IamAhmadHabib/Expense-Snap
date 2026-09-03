import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/transaction.dart';

class HomeWidgetService {
  static const String androidWidgetProvider = 'KharchaWidgetProvider';
  static const String androidWidget2x2Provider = 'KharchaWidget2x2Provider';
  static const String androidWidget4x2Provider = 'KharchaWidget4x2Provider';

  const HomeWidgetService._();

  /// Updates the native home screen widget with current day metrics.
  static Future<void> updateWidgetData({
    required List<Transaction> transactions,
    required AppSettings settings,
  }) async {
    if (kIsWeb) return;

    try {
      final now = DateTime.now();
      final todayTransactions = transactions.where((tx) {
        return !tx.isIncome &&
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day;
      }).toList();

      final totalToday = todayTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );

      final count = todayTransactions.length;
      final currency = settings.currencySymbol.isNotEmpty
          ? settings.currencySymbol
          : 'Rs.';
      final amountFormatted = NumberFormat.currency(
        symbol: '$currency ',
        decimalDigits: 0,
      ).format(totalToday);

      final countFormatted = count == 1 ? '1 expense today' : '$count expenses today';

      await HomeWidget.saveWidgetData<String>('today_spent', amountFormatted);
      await HomeWidget.saveWidgetData<String>('today_count', countFormatted);
      await HomeWidget.saveWidgetData<String>('currency', currency);

      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        qualifiedAndroidName: 'com.kharcha.kharcha.$androidWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: androidWidget2x2Provider,
        qualifiedAndroidName: 'com.kharcha.kharcha.$androidWidget2x2Provider',
      );
      await HomeWidget.updateWidget(
        name: androidWidget4x2Provider,
        qualifiedAndroidName: 'com.kharcha.kharcha.$androidWidget4x2Provider',
      );
    } catch (e) {
      debugPrint('HomeWidgetService.updateWidgetData error: $e');
    }
  }

  /// Sets up listeners for widget deep-link interactions.
  static StreamSubscription<Uri?>? registerClickCallback(
    void Function(Uri? uri) onUriClicked,
  ) {
    if (kIsWeb) return null;

    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null) {
          onUriClicked(uri);
        }
      }).catchError((e) {
        debugPrint('HomeWidget.initiallyLaunchedFromHomeWidget error: $e');
      });

      return HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) {
          onUriClicked(uri);
        }
      });
    } catch (e) {
      debugPrint('HomeWidgetService.registerClickCallback error: $e');
      return null;
    }
  }
}

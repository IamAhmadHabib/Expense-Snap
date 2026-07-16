import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/repositories/app_settings_repository.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/main.dart';
import 'package:kharcha/services/app_services.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      KharchaApp(
        transactions: TransactionRepository.inMemory(),
        settings: AppSettingsRepository.inMemory(),
        services: AppServices.local(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

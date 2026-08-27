import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/app_session.dart';
import 'package:kharcha/features/transactions/widget_voice_overlay_screen.dart';
import 'package:kharcha/main.dart';
import 'package:kharcha/repositories/app_settings_repository.dart';
import 'package:kharcha/repositories/repository_scope.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/services/app_services.dart';

void main() {
  testWidgets('KharchaApp routes to WidgetVoiceOverlayScreen when initialRoute is /widget-voice', (
    tester,
  ) async {
    await tester.pumpWidget(
      KharchaApp(
        transactions: TransactionRepository.inMemory(),
        settings: AppSettingsRepository.inMemory(),
        services: AppServices.local(),
        startDestination: AppStartDestination.dashboard,
        initialRoute: '/widget-voice',
      ),
  group('Widget Voice Overlay Routing & UI Tests', () {
    testWidgets(
      'KharchaApp routes to WidgetVoiceOverlayScreen when initialRoute is /widget-voice without error',
      (tester) async {
        final transactions = TransactionRepository.inMemory();
        final settings = AppSettingsRepository.inMemory();
        final services = AppServices.local();

        await tester.pumpWidget(
          KharchaApp(
            transactions: transactions,
            settings: settings,
            services: services,
            startDestination: AppStartDestination.dashboard,
            initialRoute: '/widget-voice',
          ),
        );

        expect(find.byType(WidgetVoiceOverlayScreen), findsOneWidget);
        expect(find.text('Listening...'), findsOneWidget);
        expect(find.text('Done Speaking'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // Verify WidgetVoiceOverlayScreen is present
    expect(find.byType(WidgetVoiceOverlayScreen), findsOneWidget);
    expect(find.text('Listening...'), findsOneWidget);
    expect(find.text('Done Speaking'), findsOneWidget);
    testWidgets(
      'Voice overlay transitions to confirmation with clean Cash and Card text (no emojis)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.resetPhysicalSize);

        final transactions = TransactionRepository.inMemory();
        final settings = AppSettingsRepository.inMemory();
        final services = AppServices.local();

        await tester.pumpWidget(
          RepositoryScope(
            transactions: transactions,
            settings: settings,
            services: services,
            child: const MaterialApp(
              home: WidgetVoiceOverlayScreen(
                initialTranscript: 'Lunch 450',
              ),
            ),
          ),
        );

        // Let entrance animation complete
        await tester.pump(const Duration(milliseconds: 300));

        // Initial state shows transcript
        expect(find.text('"Lunch 450"'), findsOneWidget);

        // Tap "Done Speaking" to simulate speech finish
        await tester.tap(find.text('Done Speaking'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Should be on Confirm Expense screen
        expect(find.text('Confirm Expense'), findsOneWidget);
        expect(find.text('Method'), findsOneWidget);

        // Cash and Card buttons must NOT have emojis
        expect(find.text('Cash'), findsOneWidget);
        expect(find.text('Card'), findsOneWidget);
        expect(find.text('💵 Cash'), findsNothing);
        expect(find.text('💳 Card'), findsNothing);

        // Merchant field should NOT contain the literal word "Expense"
        final merchantField = find.byType(TextField).last;
        final textFieldWidget = tester.widget<TextField>(merchantField);
        expect(textFieldWidget.controller?.text.toLowerCase() == 'expense', isFalse);

        // Merchant hint text must be 'Merchant / Note'
        expect(textFieldWidget.decoration?.hintText, equals('Merchant / Note'));

        // Toggle Card payment method
        await tester.tap(find.text('Card'));
        await tester.pump(const Duration(milliseconds: 200));

        // Toggle Cash payment method
        await tester.tap(find.text('Cash'));
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Save Expense
        expect(find.text('Save Expense'), findsOneWidget);
        await tester.tap(find.text('Save Expense'));
        await tester.pump(const Duration(milliseconds: 800));
      },
    );

    testWidgets(
      'Voice overlay backdrop and close button are interactive',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.resetPhysicalSize);

        final transactions = TransactionRepository.inMemory();
        final settings = AppSettingsRepository.inMemory();
        final services = AppServices.local();

        await tester.pumpWidget(
          RepositoryScope(
            transactions: transactions,
            settings: settings,
            services: services,
            child: const MaterialApp(
              home: WidgetVoiceOverlayScreen(),
            ),
          ),
        );

        // Close icon exists and can be tapped
        final closeBtn = find.byIcon(Icons.close_rounded);
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}

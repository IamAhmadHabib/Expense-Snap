import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/app_session.dart';
import 'package:kharcha/features/transactions/widget_voice_overlay_screen.dart';
import 'package:kharcha/main.dart';
import 'package:kharcha/repositories/app_settings_repository.dart';
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
    );

    // Verify WidgetVoiceOverlayScreen is present
    expect(find.byType(WidgetVoiceOverlayScreen), findsOneWidget);
    expect(find.text('Listening...'), findsOneWidget);
    expect(find.text('Done Speaking'), findsOneWidget);
  });
}

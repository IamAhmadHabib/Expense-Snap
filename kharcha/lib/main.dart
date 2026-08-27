import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bootstrap/app_bootstrap.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'core/app_session.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'repositories/app_settings_repository.dart';
import 'repositories/repository_scope.dart';
import 'repositories/transaction_repository.dart';
import 'services/app_services.dart';
import 'services/app_sync_coordinator.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebase = await FirebaseBootstrap.initialize();
  final bootstrap = await KharchaBootstrap.local(
    useFirebaseServices: firebase.isInitialized,
  );

  // Set status bar style for the warm cream background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    KharchaApp(
      transactions: bootstrap.transactions,
      settings: bootstrap.settings,
      services: bootstrap.services,
      sync: bootstrap.sync,
      startDestination: bootstrap.destination,
    ),
  );
}

class KharchaApp extends StatelessWidget {
  final TransactionRepository transactions;
  final AppSettingsRepository settings;
  final AppServices services;
  final AppSyncCoordinator? sync;
  final AppStartDestination startDestination;
  final String? initialRoute;

  const KharchaApp({
    super.key,
    required this.transactions,
    required this.settings,
    required this.services,
    this.sync,
    this.startDestination = AppStartDestination.onboarding,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRoute = initialRoute ??
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final isWidgetVoice = effectiveRoute == '/widget-voice';

    return RepositoryScope(
      transactions: transactions,
      settings: settings,
      services: services,
      sync: sync,
      child: MaterialApp(
        title: 'Kharcha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: isWidgetVoice
            ? WidgetVoiceOverlayScreen()
            : (startDestination == AppStartDestination.dashboard
                ? const DashboardScreen()
                : const OnboardingScreen()),
      ),
    );
  }
}

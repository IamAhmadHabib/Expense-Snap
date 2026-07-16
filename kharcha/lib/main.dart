import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bootstrap/app_bootstrap.dart';
import 'core/app_session.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'repositories/app_settings_repository.dart';
import 'repositories/repository_scope.dart';
import 'repositories/transaction_repository.dart';
import 'services/app_services.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await KharchaBootstrap.local();

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
      startDestination: bootstrap.destination,
    ),
  );
}

class KharchaApp extends StatelessWidget {
  final TransactionRepository transactions;
  final AppSettingsRepository settings;
  final AppServices services;
  final AppStartDestination startDestination;

  const KharchaApp({
    super.key,
    required this.transactions,
    required this.settings,
    required this.services,
    this.startDestination = AppStartDestination.onboarding,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      transactions: transactions,
      settings: settings,
      services: services,
      child: MaterialApp(
        title: 'Kharcha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: startDestination == AppStartDestination.dashboard
            ? const DashboardScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}

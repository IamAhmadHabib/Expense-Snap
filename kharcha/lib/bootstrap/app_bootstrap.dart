import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_session.dart';
import '../data/local_key_value_store.dart';
import '../repositories/app_settings_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/app_services.dart';

class KharchaBootstrapResult {
  final TransactionRepository transactions;
  final AppSettingsRepository settings;
  final AppServices services;
  final AppSession session;
  final AppStartDestination destination;

  const KharchaBootstrapResult({
    required this.transactions,
    required this.settings,
    required this.services,
    required this.session,
    required this.destination,
  });
}

class KharchaBootstrap {
  const KharchaBootstrap._();

  static Future<KharchaBootstrapResult> local() async {
    final preferences = await SharedPreferences.getInstance();
    return _fromStore(SharedPreferencesLocalStore(preferences));
  }

  static Future<KharchaBootstrapResult> localForTest({
    required LocalKeyValueStore store,
  }) {
    return _fromStore(store);
  }

  static Future<KharchaBootstrapResult> _fromStore(
    LocalKeyValueStore store,
  ) async {
    final transactions = TransactionRepository(store: store);
    final settings = AppSettingsRepository(store: store);
    final services = AppServices.local();
    final session = await services.auth.restoreSession();

    await Future.wait([transactions.load(), settings.load()]);

    return KharchaBootstrapResult(
      transactions: transactions,
      settings: settings,
      services: services,
      session: session,
      destination: session.isAuthenticated
          ? AppStartDestination.dashboard
          : AppStartDestination.onboarding,
    );
  }
}

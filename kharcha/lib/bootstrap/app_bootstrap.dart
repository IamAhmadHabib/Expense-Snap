import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_session.dart';
import '../data/local_key_value_store.dart';
import '../repositories/app_settings_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/app_services.dart';
import '../services/firebase_backend_services.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/app_sync_coordinator.dart';

class KharchaBootstrapResult {
  final TransactionRepository transactions;
  final AppSettingsRepository settings;
  final AppServices services;
  final AppSyncCoordinator sync;
  final AppSession session;
  final AppStartDestination destination;

  const KharchaBootstrapResult({
    required this.transactions,
    required this.settings,
    required this.services,
    required this.sync,
    required this.session,
    required this.destination,
  });
}

class KharchaBootstrap {
  const KharchaBootstrap._();

  static Future<KharchaBootstrapResult> local({
    bool useFirebaseServices = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    return _fromStore(
      SharedPreferencesLocalStore(preferences),
      useFirebaseServices: useFirebaseServices,
    );
  }

  static Future<KharchaBootstrapResult> localForTest({
    required LocalKeyValueStore store,
    bool useFirebaseServices = false,
  }) {
    return _fromStore(store, useFirebaseServices: useFirebaseServices);
  }

  static Future<KharchaBootstrapResult> _fromStore(
    LocalKeyValueStore store, {
    required bool useFirebaseServices,
  }) async {
    final transactions = TransactionRepository(store: store);
    final settings = AppSettingsRepository(store: store);
    final services = useFirebaseServices
        ? AppServices.withAuth(
            FirebaseAuthService(),
            attachments: FirebaseStorageAttachmentService(),
            sync: FirestoreTransactionSyncService(),
          )
        : AppServices.local();
    final session = await services.auth.restoreSession();

    await Future.wait([transactions.load(), settings.load()]);
    final sync = AppSyncCoordinator(
      transactions: transactions,
      settings: settings,
      service: services.sync,
    );
    if (session.isAuthenticated && useFirebaseServices) {
      unawaited(_syncSignedInProfile(sync, settings, session));
    }

    return KharchaBootstrapResult(
      transactions: transactions,
      settings: settings,
      services: services,
      sync: sync,
      session: session,
      destination: session.isAuthenticated
          ? AppStartDestination.dashboard
          : AppStartDestination.onboarding,
    );
  }

  static Future<void> _syncSignedInProfile(
    AppSyncCoordinator sync,
    AppSettingsRepository settings,
    AppSession session,
  ) async {
    // Pull existing cloud settings first so a fresh install never overwrites
    // another device's personalization just to fill Auth-owned identity data.
    await sync.syncNow();
    final email = session.email?.trim();
    final displayName = session.displayName?.trim();
    final shouldSetEmail =
        email != null &&
        email.isNotEmpty &&
        settings.settings.profileEmail != email;
    final shouldSetDisplayName =
        displayName != null &&
        displayName.isNotEmpty &&
        settings.settings.userName == 'Ahmad';
    if (!shouldSetEmail && !shouldSetDisplayName) return;
    await settings.update(
      settings.settings.copyWith(
        profileEmail: shouldSetEmail ? email : null,
        userName: shouldSetDisplayName ? displayName : null,
      ),
    );
    await sync.syncNow(settingsChanged: true);
  }
}

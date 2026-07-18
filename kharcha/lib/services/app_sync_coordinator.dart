import '../core/app_failure.dart';
import '../repositories/app_settings_repository.dart';
import '../repositories/transaction_repository.dart';
import 'app_services.dart';

/// Keeps the app local-first: UI writes locally, then this coordinator mirrors
/// those writes to the signed-in user's Firestore namespace in the background.
class AppSyncCoordinator {
  final TransactionRepositoryContract transactions;
  final AppSettingsRepository settings;
  final TransactionSyncService service;
  Future<SyncReport>? _activeSync;
  bool _resyncRequested = false;
  bool _settingsSyncRequested = false;

  AppSyncCoordinator({
    required this.transactions,
    required this.settings,
    required this.service,
  });

  Future<SyncReport> syncNow({bool settingsChanged = false}) {
    _settingsSyncRequested = _settingsSyncRequested || settingsChanged;
    if (_activeSync != null) {
      _resyncRequested = true;
      return _activeSync!;
    }
    return _activeSync = _syncUntilIdle();
  }

  Future<SyncReport> _syncUntilIdle() async {
    late SyncReport report;
    try {
      do {
        _resyncRequested = false;
        final settingsChanged = _settingsSyncRequested;
        _settingsSyncRequested = false;
        report = await _syncOnce(settingsChanged: settingsChanged);
      } while (_resyncRequested);
      return report;
    } finally {
      _activeSync = null;
    }
  }

  Future<SyncReport> _syncOnce({required bool settingsChanged}) async {
    try {
      final report = await service.pushPending(transactions.pendingSync);
      for (final entry in report.remoteIds.entries) {
        await transactions.mapRemoteId(
          localId: entry.key,
          remoteId: entry.value,
        );
      }
      for (final localId in report.deletedLocalIds) {
        await transactions.completeRemoteDelete(localId);
      }
      for (final entry in report.failuresByLocalId.entries) {
        await transactions.markSyncFailed(
          localId: entry.key,
          failure: entry.value,
        );
      }
      final remoteTransactions = await service.pullTransactions();
      for (final transaction in remoteTransactions) {
        await transactions.mergeRemote(transaction);
      }
      if (settingsChanged) {
        await service.pushSettings(settings.settings);
      } else {
        final remoteSettings = await service.pullSettings();
        if (remoteSettings == null) {
          await service.pushSettings(settings.settings);
        } else {
          await settings.update(remoteSettings);
        }
      }
      return report;
    } catch (error) {
      return SyncReport(
        attempted: transactions.pendingSync.length,
        succeeded: 0,
        failures: [
          AppFailure(
            code: 'sync-unavailable',
            message: error.toString(),
            isRetryable: true,
          ),
        ],
      );
    }
  }
}

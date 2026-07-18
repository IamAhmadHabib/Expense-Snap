import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/sync_state.dart';
import 'package:kharcha/data/local_key_value_store.dart';
import 'package:kharcha/models/app_settings.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/models/transaction_draft.dart';
import 'package:kharcha/repositories/app_settings_repository.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/services/app_services.dart';
import 'package:kharcha/services/app_sync_coordinator.dart';

class _MemoryStore implements LocalKeyValueStore {
  final Map<String, String> _values = {};

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}

class _FakeSyncService implements TransactionSyncService {
  List<Transaction> pulled = const [];
  AppSettings? remoteSettings;
  AppSettings? pushedSettings;

  @override
  Future<SyncReport> pushPending(Iterable<Transaction> transactions) async {
    final ids = {
      for (final transaction in transactions)
        transaction.id: 'remote-${transaction.id}',
    };
    return SyncReport(
      attempted: ids.length,
      succeeded: ids.length,
      remoteIds: ids,
    );
  }

  @override
  Future<List<Transaction>> pullTransactions() async => pulled;

  @override
  Future<AppSettings?> pullSettings() async => remoteSettings;

  @override
  Future<void> pushSettings(AppSettings settings) async {
    pushedSettings = settings;
  }
}

class _BlockingDeleteSyncService extends _FakeSyncService {
  final firstPushStarted = Completer<void>();
  final allowFirstPush = Completer<void>();
  final batches = <List<Transaction>>[];

  @override
  Future<SyncReport> pushPending(Iterable<Transaction> transactions) async {
    final batch = transactions.toList(growable: false);
    batches.add(batch);
    if (batches.length == 1) {
      firstPushStarted.complete();
      await allowFirstPush.future;
    }
    final remoteIds = <String, String>{};
    final deletedLocalIds = <String>[];
    for (final transaction in batch) {
      if (transaction.syncState == SyncState.pendingDelete) {
        deletedLocalIds.add(transaction.id);
      } else {
        remoteIds[transaction.id] = transaction.remoteId ?? transaction.id;
      }
    }
    return SyncReport(
      attempted: batch.length,
      succeeded: batch.length,
      remoteIds: remoteIds,
      deletedLocalIds: deletedLocalIds,
    );
  }
}

void main() {
  test(
    'sync coordinator confirms local writes and imports cloud records',
    () async {
      final store = _MemoryStore();
      final transactions = TransactionRepository(
        store: store,
        idGenerator: () => 'local-1',
      );
      final settings = AppSettingsRepository(store: store);
      final remote = Transaction(
        id: 'remote-local-2',
        remoteId: 'remote-local-2',
        merchant: 'Pharmacy',
        category: 'Health',
        amount: 1200,
        date: DateTime(2026, 7, 18),
        syncState: SyncState.synced,
      );
      final service = _FakeSyncService()..pulled = [remote];
      final coordinator = AppSyncCoordinator(
        transactions: transactions,
        settings: settings,
        service: service,
      );

      await transactions.saveDraft(
        TransactionDraft(
          merchant: 'Lunch',
          category: 'Dining',
          amount: 450,
          date: DateTime(2026, 7, 18),
        ),
      );

      final report = await coordinator.syncNow();

      expect(report.succeeded, 1);
      expect(transactions.transactions, hasLength(2));
      expect(
        transactions.transactions
            .firstWhere((item) => item.id == 'local-1')
            .syncState,
        SyncState.synced,
      );
      expect(service.pushedSettings, settings.settings);
    },
  );

  test(
    'undo queued during a remote delete is synced after the delete',
    () async {
      final transactions = TransactionRepository(
        store: _MemoryStore(),
        idGenerator: () => 'local-1',
      );
      final settings = AppSettingsRepository(store: _MemoryStore());
      final service = _BlockingDeleteSyncService();
      final coordinator = AppSyncCoordinator(
        transactions: transactions,
        settings: settings,
        service: service,
      );

      final created = await transactions.saveDraft(
        TransactionDraft(
          merchant: 'Lunch',
          category: 'Dining',
          amount: 450,
          date: DateTime(2026, 7, 18),
        ),
      );
      await transactions.mapRemoteId(localId: created.id, remoteId: created.id);
      await transactions.delete(created.id);

      final firstSync = coordinator.syncNow();
      await service.firstPushStarted.future;
      expect(await transactions.undoDelete(), isTrue);
      final queuedSync = coordinator.syncNow();
      service.allowFirstPush.complete();
      await Future.wait([firstSync, queuedSync]);

      expect(service.batches, hasLength(2));
      expect(service.batches.first.single.syncState, SyncState.pendingDelete);
      expect(service.batches.last.single.syncState, SyncState.pendingUpdate);
      expect(transactions.transactions, hasLength(1));
      expect(transactions.transactions.single.syncState, SyncState.synced);
    },
  );
}

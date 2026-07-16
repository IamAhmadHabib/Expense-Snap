import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/app_failure.dart';
import '../core/sync_state.dart';
import '../data/local_key_value_store.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../utils/category_utils.dart';

abstract class TransactionRepositoryContract implements Listenable {
  UnmodifiableListView<Transaction> get transactions;
  UnmodifiableListView<Transaction> get pendingSync;
  double get totalExpenses;
  double get totalIncome;
  double get currentMonthExpenses;
  Map<String, double> get categoryTotals;

  Future<void> load();
  Future<Transaction> saveDraft(
    TransactionDraft draft, {
    String? transactionId,
  });
  Future<void> delete(String id);
  Future<bool> undoDelete();
  Future<void> mapRemoteId({
    required String localId,
    required String remoteId,
    DateTime? syncedAt,
  });
  Future<void> markSyncFailed({
    required String localId,
    required AppFailure failure,
  });
}

class TransactionRepository extends ChangeNotifier
    implements TransactionRepositoryContract {
  static const _storageKey = 'kharcha.transactions.v1';
  final LocalKeyValueStore store;
  final String Function() _idGenerator;
  final List<Transaction> _transactions = [];
  _DeletedTransaction? _lastDeleted;

  TransactionRepository({required this.store, String Function()? idGenerator})
    : _idGenerator =
          idGenerator ??
          (() => DateTime.now().microsecondsSinceEpoch.toString());

  factory TransactionRepository.inMemory() {
    return TransactionRepository(store: MemoryLocalStore());
  }

  @override
  UnmodifiableListView<Transaction> get transactions =>
      UnmodifiableListView(_transactions);

  @override
  UnmodifiableListView<Transaction> get pendingSync =>
      UnmodifiableListView(_transactions.where((item) => item.needsSync));

  @override
  double get totalExpenses => _transactions
      .where((transaction) => !transaction.isIncome)
      .fold(0, (total, transaction) => total + transaction.amount);

  @override
  double get totalIncome => _transactions
      .where((transaction) => transaction.isIncome)
      .fold(0, (total, transaction) => total + transaction.amount);

  @override
  double get currentMonthExpenses {
    final now = DateTime.now();
    return _transactions
        .where(
          (transaction) =>
              !transaction.isIncome &&
              transaction.date.year == now.year &&
              transaction.date.month == now.month,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  @override
  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final transaction in _transactions.where((item) => !item.isIncome)) {
      final category = CategoryUtils.group(transaction.category);
      totals.update(
        category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  @override
  Future<void> load() async {
    _transactions.clear();
    final raw = store.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final values = jsonDecode(raw) as List<dynamic>;
      _transactions.addAll(
        values.map(
          (value) => Transaction.fromJson(value as Map<String, dynamic>),
        ),
      );
      _sort();
    }
    notifyListeners();
  }

  @override
  Future<Transaction> saveDraft(
    TransactionDraft draft, {
    String? transactionId,
  }) async {
    final existingIndex = transactionId == null
        ? -1
        : _transactions.indexWhere((item) => item.id == transactionId);
    final existing = existingIndex == -1 ? null : _transactions[existingIndex];
    final transaction = draft.toTransaction(
      transactionId ?? _idGenerator(),
      remoteId: existing?.remoteId,
      syncState: existing == null
          ? SyncState.pendingCreate
          : (existing.remoteId == null
                ? SyncState.pendingCreate
                : SyncState.pendingUpdate),
      lastSyncedAt: existing?.lastSyncedAt,
    );
    if (existingIndex == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[existingIndex] = transaction;
    }
    _sort();
    await _persist();
    notifyListeners();
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _lastDeleted = _DeletedTransaction(_transactions[index], index);
    final transaction = _transactions[index];
    if (transaction.remoteId == null) {
      _transactions.removeAt(index);
    } else {
      _transactions[index] = transaction.copyWith(
        syncState: SyncState.pendingDelete,
        clearSyncFailure: true,
      );
    }
    await _persist();
    notifyListeners();
  }

  @override
  Future<bool> undoDelete() async {
    final deleted = _lastDeleted;
    if (deleted == null) return false;
    _transactions.insert(
      deleted.index.clamp(0, _transactions.length),
      deleted.transaction,
    );
    _lastDeleted = null;
    _sort();
    await _persist();
    notifyListeners();
    return true;
  }

  @override
  Future<void> mapRemoteId({
    required String localId,
    required String remoteId,
    DateTime? syncedAt,
  }) async {
    final index = _transactions.indexWhere((item) => item.id == localId);
    if (index == -1) return;
    _transactions[index] = _transactions[index].copyWith(
      remoteId: remoteId,
      syncState: SyncState.synced,
      lastSyncedAt: syncedAt ?? DateTime.now(),
      clearSyncFailure: true,
    );
    await _persist();
    notifyListeners();
  }

  @override
  Future<void> markSyncFailed({
    required String localId,
    required AppFailure failure,
  }) async {
    final index = _transactions.indexWhere((item) => item.id == localId);
    if (index == -1) return;
    _transactions[index] = _transactions[index].copyWith(
      syncState: SyncState.failed,
      syncFailure: failure,
    );
    await _persist();
    notifyListeners();
  }

  void _sort() => _transactions.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _persist() {
    return store.setString(
      _storageKey,
      jsonEncode(
        _transactions.map((transaction) => transaction.toJson()).toList(),
      ),
    );
  }
}

class _DeletedTransaction {
  final Transaction transaction;
  final int index;
  const _DeletedTransaction(this.transaction, this.index);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/data/local_key_value_store.dart';
import 'package:kharcha/models/app_settings.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/models/transaction_draft.dart';
import 'package:kharcha/repositories/app_settings_repository.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/utils/category_utils.dart';

class _MemoryStore implements LocalKeyValueStore {
  final Map<String, String> values = {};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

TransactionDraft _draft({
  double amount = 850,
  String merchant = 'Uber',
  String category = 'Transport',
}) {
  return TransactionDraft(
    merchant: merchant,
    category: category,
    amount: amount,
    date: DateTime(2026, 7, 15, 14, 30),
    note: 'Office to home',
    method: 'Cash',
    source: TransactionSource.manual,
  );
}

void main() {
  test(
    'draft create and edit persist through one transaction repository',
    () async {
      final store = _MemoryStore();
      final repository = TransactionRepository(
        store: store,
        idGenerator: () => 'tx-1',
      );
      await repository.load();

      final created = await repository.saveDraft(_draft());
      await repository.saveDraft(
        _draft(amount: 1200, merchant: 'Careem'),
        transactionId: created.id,
      );

      final reloaded = TransactionRepository(store: store);
      await reloaded.load();

      expect(reloaded.transactions, hasLength(1));
      expect(reloaded.transactions.single.id, 'tx-1');
      expect(reloaded.transactions.single.merchant, 'Careem');
      expect(reloaded.transactions.single.amount, 1200);
      expect(reloaded.totalExpenses, 1200);
      expect(reloaded.categoryTotals, {'Transport': 1200});
    },
  );

  test('delete and undo restore the same transaction and ordering', () async {
    final store = _MemoryStore();
    var nextId = 0;
    final repository = TransactionRepository(
      store: store,
      idGenerator: () => 'tx-${++nextId}',
    );
    await repository.load();
    await repository.saveDraft(_draft(merchant: 'First'));
    await repository.saveDraft(_draft(merchant: 'Second'));
    final originalOrder = repository.transactions.map((tx) => tx.id).toList();

    await repository.delete('tx-2');
    expect(repository.transactions.map((tx) => tx.id), ['tx-1']);

    expect(await repository.undoDelete(), isTrue);
    expect(repository.transactions.map((tx) => tx.id), originalOrder);

    final reloaded = TransactionRepository(store: store);
    await reloaded.load();
    expect(reloaded.transactions.map((tx) => tx.id), originalOrder);
  });

  test('dining transactions roll up into the food category group', () async {
    final store = _MemoryStore();
    var nextId = 0;
    final repository = TransactionRepository(
      store: store,
      idGenerator: () => 'tx-${++nextId}',
    );
    await repository.load();

    await repository.saveDraft(
      _draft(amount: 300, merchant: 'Burger', category: 'Dining'),
    );
    await repository.saveDraft(
      _draft(amount: 2000, merchant: 'Medicine', category: 'Health'),
    );

    expect(CategoryUtils.matchesFilter('Dining', 'Food'), isTrue);
    expect(repository.categoryTotals, {'Health': 2000, 'Food': 300});
  });

  test('basic personalization and profile settings persist locally', () async {
    final store = _MemoryStore();
    final repository = AppSettingsRepository(store: store);
    await repository.load();

    await repository.update(
      repository.settings.copyWith(
        userName: 'Ahmad',
        monthlyBudget: 50000,
        currencySymbol: 'Rs.',
        selectedCategories: ['Dining', 'Transport', 'Shopping'],
        notificationsEnabled: false,
        darkMode: true,
      ),
    );

    final reloaded = AppSettingsRepository(store: store);
    await reloaded.load();

    expect(
      reloaded.settings,
      const AppSettings(
        userName: 'Ahmad',
        monthlyBudget: 50000,
        currencySymbol: 'Rs.',
        selectedCategories: ['Dining', 'Transport', 'Shopping'],
        notificationsEnabled: false,
        darkMode: true,
      ),
    );
  });
}

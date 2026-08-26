import '../core/sync_state.dart';
import 'transaction.dart';

class TransactionDraft {
  final String merchant;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String method;
  final TransactionSource source;
  final bool isIncome;
  final List<String> attachmentIds;

  const TransactionDraft({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.method = 'Cash',
    this.source = TransactionSource.manual,
    this.isIncome = false,
    this.attachmentIds = const [],
  });

  factory TransactionDraft.fromTransaction(Transaction transaction) {
    return TransactionDraft(
      merchant: transaction.merchant,
      category: transaction.category,
      amount: transaction.amount,
      date: transaction.date,
      note: transaction.note,
      method: transaction.method,
      source: transaction.source,
      isIncome: transaction.isIncome,
      attachmentIds: transaction.attachmentIds,
    );
  }

  TransactionDraft copyWith({
    String? merchant,
    String? category,
    double? amount,
    DateTime? date,
    String? note,
    String? method,
    TransactionSource? source,
    bool? isIncome,
    List<String>? attachmentIds,
  }) {
    return TransactionDraft(
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      method: method ?? this.method,
      source: source ?? this.source,
      isIncome: isIncome ?? this.isIncome,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  Transaction toTransaction(
    String id, {
    String? remoteId,
    SyncState syncState = SyncState.pendingCreate,
    DateTime? lastSyncedAt,
    DateTime? updatedAt,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be greater than zero');
    }
    return Transaction(
      id: id,
      remoteId: remoteId,
      merchant: merchant.trim().isEmpty ? category : merchant.trim(),
      category: category,
      amount: amount,
      date: date,
      note: note.trim(),
      method: method,
      source: source,
      isIncome: isIncome,
      syncState: syncState,
      attachmentIds: attachmentIds,
      lastSyncedAt: lastSyncedAt,
      updatedAt: updatedAt,
    );
  }
}

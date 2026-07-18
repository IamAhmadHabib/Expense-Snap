import '../core/app_failure.dart';
import '../core/sync_state.dart';

enum TransactionSource { voice, scan, manual }

class Transaction {
  final String id;
  final String? remoteId;
  final String merchant;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String method;
  final TransactionSource source;
  final bool isIncome;
  final SyncState syncState;
  final AppFailure? syncFailure;
  final List<String> attachmentIds;
  final DateTime? lastSyncedAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Transaction({
    required this.id,
    this.remoteId,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.method = 'Cash',
    this.source = TransactionSource.manual,
    this.isIncome = false,
    this.syncState = SyncState.localOnly,
    this.syncFailure,
    this.attachmentIds = const [],
    this.lastSyncedAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get needsSync => syncState.needsSync;

  Transaction copyWith({
    String? id,
    String? remoteId,
    String? merchant,
    String? category,
    double? amount,
    DateTime? date,
    String? note,
    String? method,
    TransactionSource? source,
    bool? isIncome,
    SyncState? syncState,
    AppFailure? syncFailure,
    List<String>? attachmentIds,
    DateTime? lastSyncedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearRemoteId = false,
    bool clearSyncFailure = false,
    bool clearLastSyncedAt = false,
    bool clearDeletedAt = false,
  }) {
    return Transaction(
      id: id ?? this.id,
      remoteId: clearRemoteId ? null : remoteId ?? this.remoteId,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      method: method ?? this.method,
      source: source ?? this.source,
      isIncome: isIncome ?? this.isIncome,
      syncState: syncState ?? this.syncState,
      syncFailure: clearSyncFailure ? null : syncFailure ?? this.syncFailure,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'remoteId': remoteId,
    'merchant': merchant,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'method': method,
    'source': source.name,
    'isIncome': isIncome,
    'syncState': syncState.name,
    'syncFailure': syncFailure?.toJson(),
    'attachmentIds': attachmentIds,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      merchant: json['merchant'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      method: json['method'] as String? ?? 'Cash',
      source: TransactionSource.values.firstWhere(
        (source) => source.name == json['source'],
        orElse: () => TransactionSource.manual,
      ),
      isIncome: json['isIncome'] as bool? ?? false,
      syncState: SyncState.values.firstWhere(
        (state) => state.name == json['syncState'],
        orElse: () => SyncState.localOnly,
      ),
      syncFailure: json['syncFailure'] == null
          ? null
          : AppFailure.fromJson(json['syncFailure'] as Map<String, dynamic>),
      attachmentIds:
          (json['attachmentIds'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const [],
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }
}

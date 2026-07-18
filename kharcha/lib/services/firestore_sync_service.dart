import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../core/app_failure.dart';
import '../core/sync_state.dart';
import '../models/app_settings.dart';
import '../models/transaction.dart';
import 'app_services.dart';

/// Firestore adapter for the per-user Kharcha data namespace.
///
/// Documents are addressed by the stable local transaction ID, so retries are
/// idempotent and do not create duplicate expenses.
class FirestoreTransactionSyncService implements TransactionSyncService {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  FirestoreTransactionSyncService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _transactions {
    return _userDocument.collection('transactions');
  }

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('A signed-in Firebase user is required.');
    return _firestore.collection('users').doc(uid);
  }

  @override
  Future<SyncReport> pushPending(Iterable<Transaction> transactions) async {
    var attempted = 0;
    var succeeded = 0;
    final remoteIds = <String, String>{};
    final deletedLocalIds = <String>[];
    final failuresByLocalId = <String, AppFailure>{};

    for (final transaction in transactions) {
      attempted++;
      try {
        final document = _transactions.doc(
          transaction.remoteId ?? transaction.id,
        );
        if (transaction.syncState == SyncState.pendingDelete) {
          await _writeDeleteTombstone(document, transaction);
          deletedLocalIds.add(transaction.id);
        } else {
          await _writeTransaction(document, transaction);
          remoteIds[transaction.id] = document.id;
        }
        succeeded++;
      } catch (error) {
        failuresByLocalId[transaction.id] = AppFailure(
          code: 'firestore-write-failed',
          message: error.toString(),
          isRetryable: true,
        );
      }
    }

    return SyncReport(
      attempted: attempted,
      succeeded: succeeded,
      remoteIds: remoteIds,
      deletedLocalIds: deletedLocalIds,
      failuresByLocalId: failuresByLocalId,
      failures: failuresByLocalId.values.toList(growable: false),
    );
  }

  @override
  Future<List<Transaction>> pullTransactions() async {
    final snapshot = await _transactions.get();
    return snapshot.docs.map(_transactionFromDocument).toList(growable: false);
  }

  @override
  Future<void> pushSettings(AppSettings settings) {
    return _userDocument.set({
      'settings': settings.toJson(),
      'settingsUpdatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    }, SetOptions(merge: true));
  }

  @override
  Future<AppSettings?> pullSettings() async {
    final snapshot = await _userDocument.get();
    final settings = snapshot.data()?['settings'];
    if (settings is! Map<String, dynamic>) return null;
    return AppSettings.fromJson(settings);
  }

  Map<String, dynamic> _transactionData(Transaction transaction) => {
    'localId': transaction.id,
    'merchant': transaction.merchant,
    'category': transaction.category,
    'amount': transaction.amount,
    'date': Timestamp.fromDate(transaction.date),
    'note': transaction.note,
    'method': transaction.method,
    'source': transaction.source.name,
    'isIncome': transaction.isIncome,
    'attachmentIds': transaction.attachmentIds,
    'updatedAt': Timestamp.fromDate(
      transaction.updatedAt ?? DateTime.now().toUtc(),
    ),
    'deletedAt': FieldValue.delete(),
    'schemaVersion': 1,
  };

  Future<void> _writeTransaction(
    DocumentReference<Map<String, dynamic>> document,
    Transaction transaction,
  ) {
    final updatedAt = transaction.updatedAt ?? DateTime.now().toUtc();
    return _firestore.runTransaction((firestoreTransaction) async {
      final existing = await firestoreTransaction.get(document);
      final deletedAt = _dateFromValue(existing.data()?['deletedAt']);
      final existingUpdatedAt = _dateFromValue(existing.data()?['updatedAt']);
      if ((deletedAt != null && !updatedAt.isAfter(deletedAt)) ||
          (existingUpdatedAt != null &&
              updatedAt.isBefore(existingUpdatedAt))) {
        return;
      }
      firestoreTransaction.set(
        document,
        _transactionData(transaction),
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _writeDeleteTombstone(
    DocumentReference<Map<String, dynamic>> document,
    Transaction transaction,
  ) {
    final deletedAt = transaction.deletedAt ?? DateTime.now().toUtc();
    return _firestore.runTransaction((firestoreTransaction) async {
      final existing = await firestoreTransaction.get(document);
      final existingUpdatedAt = _dateFromValue(existing.data()?['updatedAt']);
      if (existingUpdatedAt != null && existingUpdatedAt.isAfter(deletedAt)) {
        return;
      }
      firestoreTransaction.set(document, {
        'localId': transaction.id,
        'deletedAt': Timestamp.fromDate(deletedAt),
        'updatedAt': Timestamp.fromDate(deletedAt),
        'schemaVersion': 1,
      }, SetOptions(merge: true));
    });
  }

  Transaction _transactionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final date = data['date'];
    final updatedAt = _dateFromValue(data['updatedAt']);
    final deletedAt = _dateFromValue(data['deletedAt']);
    return Transaction(
      id: data['localId'] as String? ?? document.id,
      remoteId: document.id,
      merchant: data['merchant'] as String? ?? 'Expense',
      category: data['category'] as String? ?? 'Other',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: date is Timestamp ? date.toDate() : DateTime.now(),
      note: data['note'] as String? ?? '',
      method: data['method'] as String? ?? 'Cash',
      source: TransactionSource.values.firstWhere(
        (item) => item.name == data['source'],
        orElse: () => TransactionSource.manual,
      ),
      isIncome: data['isIncome'] as bool? ?? false,
      syncState: SyncState.synced,
      attachmentIds: (data['attachmentIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      lastSyncedAt: DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }
}

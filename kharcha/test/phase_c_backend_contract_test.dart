import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/app_failure.dart';
import 'package:kharcha/core/app_session.dart';
import 'package:kharcha/core/attachment_state.dart';
import 'package:kharcha/core/permission_state.dart';
import 'package:kharcha/core/sync_state.dart';
import 'package:kharcha/data/local_key_value_store.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/models/transaction_draft.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/services/app_services.dart';
import 'package:kharcha/services/capture_adapters.dart';
import 'package:kharcha/bootstrap/app_bootstrap.dart';

class _MemoryStore implements LocalKeyValueStore {
  final Map<String, String> values = {};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> reload() async {}
}

TransactionDraft _draft() {
  return TransactionDraft(
    merchant: 'Burger',
    category: 'Dining',
    amount: 300,
    date: DateTime.utc(2026, 7, 15, 12),
    method: 'Cash',
    source: TransactionSource.manual,
  );
}

void main() {
  test('transaction json preserves remote mapping and sync state', () {
    final syncedAt = DateTime.utc(2026, 7, 15, 12, 30);
    final transaction = Transaction(
      id: 'local-1',
      remoteId: 'remote-1',
      merchant: 'Clinic',
      category: 'Health',
      amount: 2000,
      date: DateTime.utc(2026, 7, 15, 12),
      syncState: SyncState.synced,
      syncFailure: const AppFailure(
        code: 'previous-warning',
        message: 'Recovered',
        isRetryable: true,
      ),
      attachmentIds: const ['receipt-local-1'],
      lastSyncedAt: syncedAt,
    );

    final roundTrip = Transaction.fromJson(transaction.toJson());

    expect(roundTrip.remoteId, 'remote-1');
    expect(roundTrip.syncState, SyncState.synced);
    expect(roundTrip.syncFailure?.code, 'previous-warning');
    expect(roundTrip.attachmentIds, ['receipt-local-1']);
    expect(roundTrip.lastSyncedAt, syncedAt);
  });

  test('repository can map local transactions to remote records', () async {
    final repository = TransactionRepository(
      store: _MemoryStore(),
      idGenerator: () => 'local-1',
    );
    await repository.load();

    final created = await repository.saveDraft(_draft());
    await repository.mapRemoteId(
      localId: created.id,
      remoteId: 'firestore-transaction-1',
      syncedAt: DateTime.utc(2026, 7, 15, 13),
    );

    expect(repository.transactions.single.remoteId, 'firestore-transaction-1');
    expect(repository.transactions.single.syncState, SyncState.synced);
    expect(repository.pendingSync, isEmpty);
  });

  test(
    'local backend services expose auth permission attachment and adapters',
    () async {
      final services = AppServices.local();

      expect(await services.auth.restoreSession(), AppSession.signedOut());
      expect(
        await services.permissions.check(PermissionTarget.microphone),
        const PermissionSnapshot(
          target: PermissionTarget.microphone,
          status: PermissionStatus.notDetermined,
        ),
      );

      final attachment = await services.attachments.prepareLocalAttachment(
        const AttachmentInput(
          localPath: '/tmp/receipt.jpg',
          kind: AttachmentKind.receiptImage,
        ),
      );

      expect(attachment.state, AttachmentState.localOnly);
      expect(attachment.remoteUrl, isNull);

      final voiceDraft = await services.voiceParser.parse(
        const VoiceCaptureInput(transcript: 'burger 300 cash'),
      );
      final corrected = voiceDraft.applyCorrection(
        const CaptureCorrection(amount: 350, category: 'Food'),
      );

      expect(corrected.draft.amount, 350);
      expect(corrected.draft.category, 'Food');

      final scanDraft = await services.ocrParser.parse(
        OcrCaptureInput(attachment: attachment),
      );
      expect(scanDraft.draft.source, TransactionSource.scan);
    },
  );

  test('bootstrap restores repositories and chooses session route', () async {
    final bootstrap = await KharchaBootstrap.localForTest(
      store: _MemoryStore(),
    );

    expect(bootstrap.destination, AppStartDestination.onboarding);
    expect(bootstrap.services.auth.currentSession, AppSession.signedOut());
    expect(bootstrap.transactions.transactions, isEmpty);
    expect(bootstrap.settings.settings.currencySymbol, 'Rs.');
  });
}

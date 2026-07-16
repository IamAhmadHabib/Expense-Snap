import '../core/app_session.dart';
import '../core/attachment_state.dart';
import '../core/permission_state.dart';
import '../models/transaction.dart';
import 'app_services.dart';
import 'capture_adapters.dart';

class LocalAuthService implements AuthService {
  AppSession _session = const AppSession.signedOut();

  @override
  AppSession get currentSession => _session;

  @override
  Future<AppSession> restoreSession() async {
    return _session;
  }

  @override
  Future<AppSession> signOut() async {
    _session = const AppSession.signedOut();
    return _session;
  }
}

class LocalPermissionService implements PermissionService {
  final Map<PermissionTarget, PermissionSnapshot> _snapshots = {};

  @override
  Future<PermissionSnapshot> check(PermissionTarget target) async {
    return _snapshots[target] ??
        PermissionSnapshot(
          target: target,
          status: PermissionStatus.notDetermined,
        );
  }

  @override
  Future<PermissionSnapshot> request(PermissionTarget target) async {
    final snapshot = PermissionSnapshot(
      target: target,
      status: PermissionStatus.granted,
    );
    _snapshots[target] = snapshot;
    return snapshot;
  }
}

class LocalAttachmentService implements AttachmentService {
  int _nextId = 0;
  final Map<String, AttachmentReference> _attachments = {};

  @override
  Future<AttachmentReference> prepareLocalAttachment(
    AttachmentInput input,
  ) async {
    final attachment = AttachmentReference(
      id: 'local-attachment-${++_nextId}',
      localPath: input.localPath,
      kind: input.kind,
      state: AttachmentState.localOnly,
    );
    _attachments[attachment.id] = attachment;
    return attachment;
  }

  @override
  Future<AttachmentReference> markUploaded({
    required String id,
    required String remoteUrl,
  }) async {
    final existing = _attachments[id];
    if (existing == null) {
      throw StateError('Attachment $id does not exist.');
    }
    final uploaded = existing.copyWith(
      state: AttachmentState.uploaded,
      remoteUrl: remoteUrl,
    );
    _attachments[id] = uploaded;
    return uploaded;
  }
}

class SimulatedVoiceExpenseParser
    implements ExpenseCaptureAdapter<VoiceCaptureInput> {
  @override
  Future<CaptureParseResult> parse(VoiceCaptureInput input) async {
    final amount = RegExp(
      r'(\d+(?:\.\d+)?)',
    ).firstMatch(input.transcript)?.group(1);
    return CaptureParseResult(
      confidence: 0.7,
      warnings: const ['Simulated voice parser; Gemini not connected yet.'],
      draft: draftFromCapture(
        merchant: input.transcript.trim().isEmpty ? 'Voice expense' : 'Burger',
        category: 'Dining',
        amount: double.tryParse(amount ?? '') ?? 0,
        method: input.transcript.toLowerCase().contains('card')
            ? 'Card'
            : 'Cash',
        source: TransactionSource.voice,
      ),
    );
  }
}

class SimulatedOcrExpenseParser
    implements ExpenseCaptureAdapter<OcrCaptureInput> {
  @override
  Future<CaptureParseResult> parse(OcrCaptureInput input) async {
    return CaptureParseResult(
      confidence: 0.55,
      warnings: const ['Simulated OCR parser; ML Kit not connected yet.'],
      draft: draftFromCapture(
        merchant: 'Scanned receipt',
        category: 'Dining',
        amount: 0,
        method: 'Cash',
        source: TransactionSource.scan,
        note: input.attachment.localPath,
      ),
    );
  }
}

class LocalNoopSyncService implements TransactionSyncService {
  @override
  Future<SyncReport> pushPending(Iterable<Transaction> transactions) async {
    final pending = transactions.where((transaction) => transaction.needsSync);
    return SyncReport(attempted: pending.length, succeeded: 0);
  }
}

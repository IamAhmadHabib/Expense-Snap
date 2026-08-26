import '../core/app_session.dart';
import '../core/attachment_state.dart';
import '../core/permission_state.dart';
import '../models/transaction.dart';
import '../models/app_settings.dart';
import 'app_services.dart';
import 'capture_adapters.dart';

class LocalAuthService implements AuthService {
  AppSession _session = const AppSession.signedOut();
  int _nextAnonymousId = 0;

  @override
  AppSession get currentSession => _session;

  @override
  Future<AppSession> restoreSession() async {
    return _session;
  }

  @override
  Future<AppSession> signInAnonymously() async {
    _session = AppSession.anonymous('local-anonymous-${++_nextAnonymousId}');
    return _session;
  }

  @override
  Future<AppSession> signInWithGoogle() async {
    _session = AppSession.signedIn(
      userId: 'local-google-user',
      email: 'google-user@local.kharcha',
      displayName: 'Google User',
    );
    return _session;
  }

  @override
  Future<AppSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _session = AppSession.signedIn(
      userId: 'local-email-${email.trim().toLowerCase()}',
      email: email.trim(),
      displayName: email.trim().split('@').first,
    );
    return _session;
  }

  @override
  Future<AppSession> createAccountWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _session = AppSession.signedIn(
      userId: 'local-email-${email.trim().toLowerCase()}',
      email: email.trim(),
      displayName: displayName?.trim().isEmpty ?? true
          ? email.trim().split('@').first
          : displayName!.trim(),
    );
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
      fileName: input.effectiveFileName,
      contentType: input.effectiveContentType,
    );
    _attachments[attachment.id] = attachment;
    return attachment;
  }

  @override
  Future<AttachmentReference> uploadAttachment({
    required AttachmentReference attachment,
    List<int>? bytes,
    String? userId,
  }) async {
    final uid = userId ?? 'local-user';
    final fileName = attachment.fileName ?? 'attachment';
    final remoteUrl =
        'https://local.storage.kharcha/users/$uid/attachments/${attachment.id}/$fileName';
    final uploaded = attachment.copyWith(
      state: AttachmentState.uploaded,
      remoteUrl: remoteUrl,
      clearFailure: true,
    );
    _attachments[attachment.id] = uploaded;
    return uploaded;
  }

  @override
  Future<String?> getDownloadUrl({
    required String attachmentId,
    String? userId,
    String? fileName,
  }) async {
    return _attachments[attachmentId]?.remoteUrl;
  }

  @override
  Future<void> deleteAttachment({
    required String attachmentId,
    String? userId,
    String? fileName,
  }) async {
    _attachments.remove(attachmentId);
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
      clearFailure: true,
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

  @override
  Future<List<Transaction>> pullTransactions() async => const [];

  @override
  Future<void> pushSettings(AppSettings settings) async {}

  @override
  Future<AppSettings?> pullSettings() async => null;
}

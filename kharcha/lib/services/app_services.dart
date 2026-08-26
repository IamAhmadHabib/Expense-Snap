import '../core/app_failure.dart';
import '../core/app_session.dart';
import '../core/attachment_state.dart';
import '../core/permission_state.dart';
import '../models/app_settings.dart';
import '../models/transaction.dart';
import 'capture_adapters.dart';
import 'local_backend_services.dart';

abstract class AuthService {
  AppSession get currentSession;
  Future<AppSession> restoreSession();
  Future<AppSession> signInAnonymously();
  Future<AppSession> signInWithGoogle();
  Future<AppSession> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AppSession> createAccountWithEmail({
    required String email,
    required String password,
    String? displayName,
  });
  Future<AppSession> signOut();
}

abstract class PermissionService {
  Future<PermissionSnapshot> check(PermissionTarget target);
  Future<PermissionSnapshot> request(PermissionTarget target);
}

abstract class AttachmentService {
  Future<AttachmentReference> prepareLocalAttachment(AttachmentInput input);
  Future<AttachmentReference> uploadAttachment({
    required AttachmentReference attachment,
    List<int>? bytes,
    String? userId,
  });
  Future<String?> getDownloadUrl({
    required String attachmentId,
    String? userId,
    String? fileName,
  });
  Future<void> deleteAttachment({
    required String attachmentId,
    String? userId,
    String? fileName,
  });
  Future<AttachmentReference> markUploaded({
    required String id,
    required String remoteUrl,
  });
}

class SyncReport {
  final int attempted;
  final int succeeded;
  final List<AppFailure> failures;
  final Map<String, String> remoteIds;
  final List<String> deletedLocalIds;
  final Map<String, AppFailure> failuresByLocalId;

  const SyncReport({
    required this.attempted,
    required this.succeeded,
    this.failures = const [],
    this.remoteIds = const {},
    this.deletedLocalIds = const [],
    this.failuresByLocalId = const {},
  });

  bool get hasFailures => failures.isNotEmpty;
}

abstract class TransactionSyncService {
  Future<SyncReport> pushPending(Iterable<Transaction> transactions);
  Future<List<Transaction>> pullTransactions();
  Future<void> pushSettings(AppSettings settings);
  Future<AppSettings?> pullSettings();
}

class AppServices {
  final AuthService auth;
  final PermissionService permissions;
  final AttachmentService attachments;
  final ExpenseCaptureAdapter<VoiceCaptureInput> voiceParser;
  final ExpenseCaptureAdapter<OcrCaptureInput> ocrParser;
  final TransactionSyncService sync;

  const AppServices({
    required this.auth,
    required this.permissions,
    required this.attachments,
    required this.voiceParser,
    required this.ocrParser,
    required this.sync,
  });

  factory AppServices.local() {
    return AppServices(
      auth: LocalAuthService(),
      permissions: LocalPermissionService(),
      attachments: LocalAttachmentService(),
      voiceParser: SimulatedVoiceExpenseParser(),
      ocrParser: SimulatedOcrExpenseParser(),
      sync: LocalNoopSyncService(),
    );
  }

  factory AppServices.withAuth(
    AuthService auth, {
    AttachmentService? attachments,
    TransactionSyncService? sync,
  }) {
    return AppServices(
      auth: auth,
      permissions: LocalPermissionService(),
      attachments: attachments ?? LocalAttachmentService(),
      voiceParser: SimulatedVoiceExpenseParser(),
      ocrParser: SimulatedOcrExpenseParser(),
      sync: sync ?? LocalNoopSyncService(),
    );
  }
}

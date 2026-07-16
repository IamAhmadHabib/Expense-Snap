import '../core/app_failure.dart';
import '../core/app_session.dart';
import '../core/attachment_state.dart';
import '../core/permission_state.dart';
import '../models/transaction.dart';
import 'capture_adapters.dart';
import 'local_backend_services.dart';

abstract class AuthService {
  AppSession get currentSession;
  Future<AppSession> restoreSession();
  Future<AppSession> signOut();
}

abstract class PermissionService {
  Future<PermissionSnapshot> check(PermissionTarget target);
  Future<PermissionSnapshot> request(PermissionTarget target);
}

abstract class AttachmentService {
  Future<AttachmentReference> prepareLocalAttachment(AttachmentInput input);
  Future<AttachmentReference> markUploaded({
    required String id,
    required String remoteUrl,
  });
}

class SyncReport {
  final int attempted;
  final int succeeded;
  final List<AppFailure> failures;

  const SyncReport({
    required this.attempted,
    required this.succeeded,
    this.failures = const [],
  });

  bool get hasFailures => failures.isNotEmpty;
}

abstract class TransactionSyncService {
  Future<SyncReport> pushPending(Iterable<Transaction> transactions);
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
}

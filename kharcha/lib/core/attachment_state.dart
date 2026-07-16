import 'app_failure.dart';

enum AttachmentKind { receiptImage, screenshot, voiceClip, document }

enum AttachmentState { localOnly, pendingUpload, uploaded, failed }

class AttachmentInput {
  final String localPath;
  final AttachmentKind kind;
  final String? contentType;

  const AttachmentInput({
    required this.localPath,
    required this.kind,
    this.contentType,
  });
}

class AttachmentReference {
  final String id;
  final String localPath;
  final AttachmentKind kind;
  final AttachmentState state;
  final String? remoteUrl;
  final AppFailure? failure;

  const AttachmentReference({
    required this.id,
    required this.localPath,
    required this.kind,
    required this.state,
    this.remoteUrl,
    this.failure,
  });

  AttachmentReference copyWith({
    AttachmentState? state,
    String? remoteUrl,
    AppFailure? failure,
  }) {
    return AttachmentReference(
      id: id,
      localPath: localPath,
      kind: kind,
      state: state ?? this.state,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      failure: failure,
    );
  }
}

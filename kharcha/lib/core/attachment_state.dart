import 'app_failure.dart';

enum AttachmentKind { receiptImage, screenshot, voiceClip, document }

enum AttachmentState { localOnly, pendingUpload, uploaded, failed }

class AttachmentInput {
  final String localPath;
  final AttachmentKind kind;
  final String? contentType;
  final String? fileName;
  final List<int>? bytes;

  const AttachmentInput({
    required this.localPath,
    required this.kind,
    this.contentType,
    this.fileName,
    this.bytes,
  });

  String get effectiveFileName {
    if (fileName != null && fileName!.trim().isNotEmpty) {
      return fileName!.trim();
    }
    if (localPath.trim().isNotEmpty) {
      final name = localPath.split(RegExp(r'[/\\]')).last.trim();
      if (name.isNotEmpty) return name;
    }
    switch (kind) {
      case AttachmentKind.receiptImage:
        return 'receipt.jpg';
      case AttachmentKind.screenshot:
        return 'screenshot.png';
      case AttachmentKind.voiceClip:
        return 'voice_clip.m4a';
      case AttachmentKind.document:
        return 'attachment.pdf';
    }
  }

  String get effectiveContentType {
    if (contentType != null && contentType!.trim().isNotEmpty) {
      return contentType!.trim();
    }
    switch (kind) {
      case AttachmentKind.receiptImage:
        return 'image/jpeg';
      case AttachmentKind.screenshot:
        return 'image/png';
      case AttachmentKind.voiceClip:
        return 'audio/mp4';
      case AttachmentKind.document:
        return 'application/pdf';
    }
  }
}

class AttachmentReference {
  final String id;
  final String localPath;
  final AttachmentKind kind;
  final AttachmentState state;
  final String? fileName;
  final String? contentType;
  final String? remoteUrl;
  final AppFailure? failure;

  const AttachmentReference({
    required this.id,
    required this.localPath,
    required this.kind,
    required this.state,
    this.fileName,
    this.contentType,
    this.remoteUrl,
    this.failure,
  });

  AttachmentReference copyWith({
    String? localPath,
    AttachmentState? state,
    String? fileName,
    String? contentType,
    String? remoteUrl,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return AttachmentReference(
      id: id,
      localPath: localPath ?? this.localPath,
      kind: kind,
      state: state ?? this.state,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'localPath': localPath,
    'kind': kind.name,
    'state': state.name,
    if (fileName != null) 'fileName': fileName,
    if (contentType != null) 'contentType': contentType,
    if (remoteUrl != null) 'remoteUrl': remoteUrl,
    if (failure != null) 'failure': failure!.toJson(),
  };

  factory AttachmentReference.fromJson(Map<String, dynamic> json) {
    return AttachmentReference(
      id: json['id'] as String,
      localPath: json['localPath'] as String? ?? '',
      kind: AttachmentKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => AttachmentKind.receiptImage,
      ),
      state: AttachmentState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => AttachmentState.localOnly,
      ),
      fileName: json['fileName'] as String?,
      contentType: json['contentType'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      failure: json['failure'] == null
          ? null
          : AppFailure.fromJson(json['failure'] as Map<String, dynamic>),
    );
  }
}

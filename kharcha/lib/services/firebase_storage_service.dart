import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../core/app_failure.dart';
import '../core/attachment_state.dart';
import 'app_services.dart';

/// Production Firebase Storage adapter for uploading receipts, screenshots,
/// and voice clips scoped under users/{userId}/attachments/{attachmentId}/{fileName}.
class FirebaseStorageAttachmentService implements AttachmentService {
  firebase_storage.FirebaseStorage? _storage;
  firebase_auth.FirebaseAuth? _auth;
  int _localSequence = 0;
  final Map<String, AttachmentReference> _cache = {};

  FirebaseStorageAttachmentService({
    firebase_storage.FirebaseStorage? storage,
    firebase_auth.FirebaseAuth? auth,
  }) : _storage = storage,
       _auth = auth;

  firebase_storage.FirebaseStorage get storage =>
      _storage ??= firebase_storage.FirebaseStorage.instance;

  firebase_auth.FirebaseAuth get auth =>
      _auth ??= firebase_auth.FirebaseAuth.instance;

  String _requireUserId(String? userId) {
    if (userId != null && userId.trim().isNotEmpty) return userId.trim();
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw StateError(
          'A signed-in Firebase user is required for cloud attachments.',
        );
      }
      return uid;
    } catch (e) {
      if (e is StateError) rethrow;
      throw StateError(
        'A signed-in Firebase user is required for cloud attachments.',
      );
    }
  }

  firebase_storage.Reference _attachmentReference({
    required String userId,
    required String attachmentId,
    required String fileName,
  }) {
    return storage
        .ref()
        .child('users')
        .child(userId)
        .child('attachments')
        .child(attachmentId)
        .child(fileName);
  }

  @override
  Future<AttachmentReference> prepareLocalAttachment(AttachmentInput input) async {
    final id = 'att-${DateTime.now().millisecondsSinceEpoch}-${++_localSequence}';
    final ref = AttachmentReference(
      id: id,
      localPath: input.localPath,
      kind: input.kind,
      state: AttachmentState.localOnly,
      fileName: input.effectiveFileName,
      contentType: input.effectiveContentType,
    );
    _cache[id] = ref;
    return ref;
  }

  @override
  Future<AttachmentReference> uploadAttachment({
    required AttachmentReference attachment,
    List<int>? bytes,
    String? userId,
  }) async {
    try {
      final uid = _requireUserId(userId);
      final fileName = attachment.fileName ?? 'attachment';
      final storageRef = _attachmentReference(
        userId: uid,
        attachmentId: attachment.id,
        fileName: fileName,
      );

      final metadata = firebase_storage.SettableMetadata(
        contentType: attachment.contentType ?? 'application/octet-stream',
        customMetadata: {
          'attachmentId': attachment.id,
          'kind': attachment.kind.name,
          'uploadedBy': uid,
        },
      );

      if (bytes != null && bytes.isNotEmpty) {
        await storageRef.putData(Uint8List.fromList(bytes), metadata);
      } else if (!kIsWeb && attachment.localPath.isNotEmpty) {
        final file = File(attachment.localPath);
        if (!await file.exists()) {
          throw StateError('Local file does not exist at ${attachment.localPath}');
        }
        await storageRef.putFile(file, metadata);
      } else {
        throw ArgumentError('Either bytes or a valid localPath must be provided.');
      }

      final downloadUrl = await storageRef.getDownloadURL();
      final uploaded = attachment.copyWith(
        state: AttachmentState.uploaded,
        remoteUrl: downloadUrl,
        clearFailure: true,
      );
      _cache[attachment.id] = uploaded;
      return uploaded;
    } catch (e) {
      final failed = attachment.copyWith(
        state: AttachmentState.failed,
        failure: AppFailure(
          code: 'storage-upload-failed',
          message: e.toString(),
          isRetryable: true,
        ),
      );
      _cache[attachment.id] = failed;
      return failed;
    }
  }

  @override
  Future<String?> getDownloadUrl({
    required String attachmentId,
    String? userId,
    String? fileName,
  }) async {
    try {
      final cached = _cache[attachmentId]?.remoteUrl;
      if (cached != null) return cached;
      final uid = _requireUserId(userId);
      final name = fileName ?? _cache[attachmentId]?.fileName ?? 'attachment';
      final storageRef = _attachmentReference(
        userId: uid,
        attachmentId: attachmentId,
        fileName: name,
      );
      final url = await storageRef.getDownloadURL();
      if (_cache.containsKey(attachmentId)) {
        _cache[attachmentId] = _cache[attachmentId]!.copyWith(remoteUrl: url);
      }
      return url;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteAttachment({
    required String attachmentId,
    String? userId,
    String? fileName,
  }) async {
    try {
      final uid = _requireUserId(userId);
      final name = fileName ?? _cache[attachmentId]?.fileName ?? 'attachment';
      final storageRef = _attachmentReference(
        userId: uid,
        attachmentId: attachmentId,
        fileName: name,
      );
      await storageRef.delete();
      _cache.remove(attachmentId);
    } catch (_) {
      _cache.remove(attachmentId);
    }
  }

  @override
  Future<AttachmentReference> markUploaded({
    required String id,
    required String remoteUrl,
  }) async {
    final existing = _cache[id];
    final updated = (existing ??
        AttachmentReference(
          id: id,
          localPath: '',
          kind: AttachmentKind.receiptImage,
          state: AttachmentState.uploaded,
        )).copyWith(
      state: AttachmentState.uploaded,
      remoteUrl: remoteUrl,
      clearFailure: true,
    );
    _cache[id] = updated;
    return updated;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/attachment_state.dart';
import 'package:kharcha/services/local_backend_services.dart';
import 'package:kharcha/services/firebase_storage_service.dart';

void main() {
  group('AttachmentState & AttachmentInput', () {
    test('resolves effective file names and content types by kind', () {
      const receipt = AttachmentInput(
        localPath: '/tmp/capture.jpg',
        kind: AttachmentKind.receiptImage,
      );
      expect(receipt.effectiveFileName, 'capture.jpg');
      expect(receipt.effectiveContentType, 'image/jpeg');

      const screenshot = AttachmentInput(
        localPath: '',
        kind: AttachmentKind.screenshot,
      );
      expect(screenshot.effectiveFileName, 'screenshot.png');
      expect(screenshot.effectiveContentType, 'image/png');

      const voice = AttachmentInput(
        localPath: '',
        kind: AttachmentKind.voiceClip,
      );
      expect(voice.effectiveFileName, 'voice_clip.m4a');
      expect(voice.effectiveContentType, 'audio/mp4');

      const doc = AttachmentInput(
        localPath: '',
        kind: AttachmentKind.document,
        fileName: 'custom_bill.pdf',
        contentType: 'application/pdf',
      );
      expect(doc.effectiveFileName, 'custom_bill.pdf');
      expect(doc.effectiveContentType, 'application/pdf');
    });

    test('AttachmentReference serialization roundtrips correctly', () {
      final original = AttachmentReference(
        id: 'att-123',
        localPath: '/data/user/0/receipt.jpg',
        kind: AttachmentKind.receiptImage,
        state: AttachmentState.uploaded,
        fileName: 'receipt.jpg',
        contentType: 'image/jpeg',
        remoteUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/o/receipt.jpg',
      );

      final json = original.toJson();
      final restored = AttachmentReference.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.localPath, original.localPath);
      expect(restored.kind, original.kind);
      expect(restored.state, original.state);
      expect(restored.fileName, original.fileName);
      expect(restored.contentType, original.contentType);
      expect(restored.remoteUrl, original.remoteUrl);
      expect(restored.failure, isNull);
    });
  });

  group('LocalAttachmentService', () {
    test('manages attachment lifecycle locally', () async {
      final service = LocalAttachmentService();

      final prepared = await service.prepareLocalAttachment(
        const AttachmentInput(
          localPath: '/storage/emulated/0/Download/receipt.png',
          kind: AttachmentKind.receiptImage,
        ),
      );

      expect(prepared.id, startsWith('local-attachment-'));
      expect(prepared.state, AttachmentState.localOnly);
      expect(prepared.fileName, 'receipt.png');
      expect(prepared.contentType, 'image/jpeg');

      final uploaded = await service.uploadAttachment(
        attachment: prepared,
        userId: 'user-abc',
      );

      expect(uploaded.state, AttachmentState.uploaded);
      expect(uploaded.remoteUrl, contains('user-abc'));
      expect(uploaded.remoteUrl, contains(prepared.id));

      final fetchedUrl = await service.getDownloadUrl(
        attachmentId: prepared.id,
        userId: 'user-abc',
      );
      expect(fetchedUrl, uploaded.remoteUrl);

      await service.deleteAttachment(
        attachmentId: prepared.id,
        userId: 'user-abc',
      );
      final afterDeleteUrl = await service.getDownloadUrl(
        attachmentId: prepared.id,
        userId: 'user-abc',
      );
      expect(afterDeleteUrl, isNull);
    });

    test('markUploaded overrides URL and clears failure', () async {
      final service = LocalAttachmentService();
      final prepared = await service.prepareLocalAttachment(
        const AttachmentInput(
          localPath: '/tmp/voice.m4a',
          kind: AttachmentKind.voiceClip,
        ),
      );

      final marked = await service.markUploaded(
        id: prepared.id,
        remoteUrl: 'https://example.com/voice.m4a',
      );

      expect(marked.state, AttachmentState.uploaded);
      expect(marked.remoteUrl, 'https://example.com/voice.m4a');
    });
  });

  group('FirebaseStorageAttachmentService contract checks', () {
    test('prepareLocalAttachment works immediately without network', () async {
      final service = FirebaseStorageAttachmentService();

      final ref = await service.prepareLocalAttachment(
        const AttachmentInput(
          localPath: '/tmp/receipt.png',
          kind: AttachmentKind.receiptImage,
        ),
      );

      expect(ref.id, startsWith('att-'));
      expect(ref.state, AttachmentState.localOnly);
      expect(ref.fileName, 'receipt.png');
    });

    test('uploadAttachment requires signed-in user or explicit userId', () async {
      final service = FirebaseStorageAttachmentService();

      final ref = await service.prepareLocalAttachment(
        const AttachmentInput(
          localPath: '/tmp/receipt.png',
          kind: AttachmentKind.receiptImage,
        ),
      );

      // Attempt upload without auth or userId
      final result = await service.uploadAttachment(attachment: ref);
      expect(result.state, AttachmentState.failed);
      expect(result.failure?.code, 'storage-upload-failed');
      expect(result.failure?.isRetryable, isTrue);
    });

    test('markUploaded stores in local cache', () async {
      final service = FirebaseStorageAttachmentService();

      final marked = await service.markUploaded(
        id: 'att-remote-99',
        remoteUrl: 'https://firebasestorage.googleapis.com/test.jpg',
      );

      expect(marked.id, 'att-remote-99');
      expect(marked.state, AttachmentState.uploaded);
      expect(marked.remoteUrl, 'https://firebasestorage.googleapis.com/test.jpg');
    });
  });
}

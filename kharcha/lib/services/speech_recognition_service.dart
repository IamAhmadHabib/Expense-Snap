import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Manages on-device microphone speech capture via SpeechToText.
class SpeechRecognitionService {
  final stt.SpeechToText _speech;
  bool _isInitialized = false;

  SpeechRecognitionService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized && _speech.isAvailable;
  Future<bool> hasPermission() => _speech.hasPermission;

  Future<bool> initialize({
    ValueChanged<String>? onError,
    ValueChanged<String>? onStatus,
  }) async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('Speech recognition error: ');
          }
          onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          if (kDebugMode) {
            print('Speech recognition status: ');
          }
          onStatus?.call(status);
        },
      );
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('Speech recognition initialize exception: ');
      }
      _isInitialized = false;
      return false;
    }
  }

  Future<bool> startListening({
    required ValueChanged<String> onResult,
    ValueChanged<double>? onSoundLevelChange,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          localeId: localeId,
        ),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Speech listen error: $e');
      }
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}

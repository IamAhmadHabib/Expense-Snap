import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

enum FirebaseBootstrapState {
  disabled,
  initialized,
  missingConfiguration,
  failed,
}

class FirebaseBootstrapResult {
  final FirebaseBootstrapState state;
  final Object? error;

  const FirebaseBootstrapResult._(this.state, [this.error]);

  const FirebaseBootstrapResult.disabled()
    : this._(FirebaseBootstrapState.disabled);

  const FirebaseBootstrapResult.initialized()
    : this._(FirebaseBootstrapState.initialized);

  const FirebaseBootstrapResult.missingConfiguration(Object error)
    : this._(FirebaseBootstrapState.missingConfiguration, error);

  const FirebaseBootstrapResult.failed(Object error)
    : this._(FirebaseBootstrapState.failed, error);

  bool get isInitialized => state == FirebaseBootstrapState.initialized;
}

class FirebaseBootstrap {
  static bool get enabled {
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST')) {
          return const bool.fromEnvironment(
            'KHARCHA_FIREBASE_ENABLED',
            defaultValue: false,
          );
        }
      } catch (_) {}
    }
    return const bool.fromEnvironment(
      'KHARCHA_FIREBASE_ENABLED',
      defaultValue: true,
    );
  }

  const FirebaseBootstrap._();

  static Future<FirebaseBootstrapResult> initialize() async {
    if (!enabled) {
      return const FirebaseBootstrapResult.disabled();
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const FirebaseBootstrapResult.initialized();
    } on UnsupportedError catch (error) {
      debugPrint('Firebase is enabled but not configured: $error');
      return FirebaseBootstrapResult.missingConfiguration(error);
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
      return FirebaseBootstrapResult.failed(error);
    }
  }
}

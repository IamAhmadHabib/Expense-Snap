// File generated from Firebase app configuration for Kharcha.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return macos;
      default:
        return windows;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCav9ILH-TFGGuTiFMPq4U4ecp4TC68rsI',
    appId: '1:292863323201:android:9546dd978bf00251c0eac0',
    messagingSenderId: '292863323201',
    projectId: 'kharcha-expense-snap',
    storageBucket: 'kharcha-expense-snap.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCfeoYF4O9CnzKV11-v0j69CZ9VhC9ozZ0',
    appId: '1:292863323201:ios:14650d3f513e114ec0eac0',
    messagingSenderId: '292863323201',
    projectId: 'kharcha-expense-snap',
    storageBucket: 'kharcha-expense-snap.firebasestorage.app',
    androidClientId: '292863323201-0nnonanps134agp4fugboiaemcha8in7.apps.googleusercontent.com',
    iosClientId: '292863323201-ent1f8njsf7v8t0c47icuiie3cn65tok.apps.googleusercontent.com',
    iosBundleId: 'com.kharcha.kharcha',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATHQYIHyRIBg9FTwdrouv8Dvi1NQyK1sg',
    appId: '1:292863323201:web:620308e60c334d30c0eac0',
    messagingSenderId: '292863323201',
    projectId: 'kharcha-expense-snap',
    authDomain: 'kharcha-expense-snap.firebaseapp.com',
    storageBucket: 'kharcha-expense-snap.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCfeoYF4O9CnzKV11-v0j69CZ9VhC9ozZ0',
    appId: '1:292863323201:ios:14650d3f513e114ec0eac0',
    messagingSenderId: '292863323201',
    projectId: 'kharcha-expense-snap',
    storageBucket: 'kharcha-expense-snap.firebasestorage.app',
    androidClientId: '292863323201-0nnonanps134agp4fugboiaemcha8in7.apps.googleusercontent.com',
    iosClientId: '292863323201-ent1f8njsf7v8t0c47icuiie3cn65tok.apps.googleusercontent.com',
    iosBundleId: 'com.kharcha.kharcha',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyATHQYIHyRIBg9FTwdrouv8Dvi1NQyK1sg',
    appId: '1:292863323201:web:7ce07e99bb596c8bc0eac0',
    messagingSenderId: '292863323201',
    projectId: 'kharcha-expense-snap',
    authDomain: 'kharcha-expense-snap.firebaseapp.com',
    storageBucket: 'kharcha-expense-snap.firebasestorage.app',
  );
}

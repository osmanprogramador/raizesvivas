import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAfMFFLyhbvIkwKjYyHuoqWs2hoFVtbDv4',
    appId: '1:636705497006:web:15d199b79515122ceb723f',
    messagingSenderId: '636705497006',
    projectId: 'appatv',
    authDomain: 'appatv.firebaseapp.com',
    storageBucket: 'appatv.firebasestorage.app',
    measurementId: 'G-V0H7KHEWBC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQwLb1tBiU-dsasmgJahEgqzgq7u99hG8',
    appId: '1:636705497006:android:8973b5094ff2a989eb723f',
    messagingSenderId: '636705497006',
    projectId: 'appatv',
    storageBucket: 'appatv.firebasestorage.app',
  );
}

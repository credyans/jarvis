import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase projects.
///
/// Run `flutterfire configure` to automatically regenerate this file with the
/// correct configuration options, or update these placeholders with your credentials.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholder-WebApiKeyHere',
    appId: '1:1234567890:web:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'jarvis-lifeos',
    authDomain: 'jarvis-lifeos.firebaseapp.com',
    storageBucket: 'jarvis-lifeos.appspot.com',
    measurementId: 'G-Placeholder',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholder-AndroidApiKeyHere',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'jarvis-lifeos',
    storageBucket: 'jarvis-lifeos.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyPlaceholder-IosApiKeyHere',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'jarvis-lifeos',
    storageBucket: 'jarvis-lifeos.appspot.com',
    iosBundleId: 'com.jarvisapp.jarvis',
  );
}

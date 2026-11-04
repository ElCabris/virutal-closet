import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPBMtlfOsIeMccUpO76r6vJ-PJaMRRFrM',
    appId: '1:7573812804:android:0c897d466a81a3d8346e11',
    messagingSenderId: '7573812804',
    projectId: 'lookify-closet',
    storageBucket: 'lookify-closet.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCeVIV99V75NqDhsSC93xY7l2ilnvr-ZTU',
    appId: '1:7573812804:web:520d76d1bd434378346e11',
    messagingSenderId: '7573812804',
    projectId: 'lookify-closet',
    authDomain: 'lookify-closet.firebaseapp.com',
    storageBucket: 'lookify-closet.firebasestorage.app',
  );
}

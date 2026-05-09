import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError('Firebase not yet configured for Android.');
      case TargetPlatform.iOS:
        throw UnsupportedError('Firebase not yet configured for iOS.');
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyC96HsmMSTUJ5_hrfKjWCG5ybvifHpfUqA',
    appId:             '1:205471187393:web:e339dd3d7253ee3aa4ef40',
    messagingSenderId: '205471187393',
    projectId:         'axiom-324e3',
    authDomain:        'axiom-324e3.firebaseapp.com',
    storageBucket:     'axiom-324e3.firebasestorage.app',
    measurementId:     'G-Y4SJKGV4NK',
  );
}

// TEMPORARY placeholder — not a real Firebase project.
// Replace this file by running `flutterfire configure` once you have
// internet access, so real login/signup works.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDPLACEHOLDER1234567890abcdefghi',
    appId: '1:123456789012:web:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'kellyedge-placeholder',
    authDomain: 'kellyedge-placeholder.firebaseapp.com',
    storageBucket: 'kellyedge-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPLACEHOLDER1234567890abcdefghi',
    appId: '1:123456789012:android:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'kellyedge-placeholder',
    storageBucket: 'kellyedge-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDPLACEHOLDER1234567890abcdefghi',
    appId: '1:123456789012:ios:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'kellyedge-placeholder',
    storageBucket: 'kellyedge-placeholder.appspot.com',
    iosBundleId: 'com.example.kellyedge',
  );
}
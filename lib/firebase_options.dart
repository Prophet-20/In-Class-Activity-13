// Android platform options registered with Firebase Management API.
// Regenerate for your own project with flutterfire configure.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      return android;
    throw UnsupportedError('Configure Firebase for this platform first.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOF7vXvPrzPedCx9j4MBrZpB-pA2fkK1c',
    appId: '1:413669284130:android:d385abb0841d6062fded7b',
    messagingSenderId: '413669284130',
    projectId: 'ica13-campus-access-blake',
    storageBucket: 'ica13-campus-access-blake.firebasestorage.app',
  );
}

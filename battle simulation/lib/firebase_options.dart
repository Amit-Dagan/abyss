import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for ${defaultTargetPlatform.name}.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBun8IsBt_LDdGci_QNCpcrxCkYuIp4Elo',
    appId: '1:467841961849:web:5516d5af5382c0a6ec29a8',
    messagingSenderId: '467841961849',
    projectId: 'abyss-f0953',
    authDomain: 'abyss-f0953.firebaseapp.com',
    storageBucket: 'abyss-f0953.firebasestorage.app',
    measurementId: 'G-K12CGS2L5L',
  );
}

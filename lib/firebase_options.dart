import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQMM8PTNEiIXkgGSQ_Vl-xpF3b75r2WU8',
    appId: '1:539607016004:web:31bd59508b9ebb9535d211',
    messagingSenderId: '539607016004',
    projectId: 'iiitrhackthon',
    authDomain: 'iiitrhackthon.firebaseapp.com',
    databaseURL: 'https://iiitrhackthon-default-rtdb.firebaseio.com',
    storageBucket: 'iiitrhackthon.firebasestorage.app',
    measurementId: 'G-Z8GHZ2YK4D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQMM8PTNEiIXkgGSQ_Vl-xpF3b75r2WU8',
    appId: '1:539607016004:android:31bd59508b9ebb9535d211',
    messagingSenderId: '539607016004',
    projectId: 'iiitrhackthon',
    databaseURL: 'https://iiitrhackthon-default-rtdb.firebaseio.com',
    storageBucket: 'iiitrhackthon.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDQMM8PTNEiIXkgGSQ_Vl-xpF3b75r2WU8',
    appId: '1:539607016004:ios:31bd59508b9ebb9535d211',
    messagingSenderId: '539607016004',
    projectId: 'iiitrhackthon',
    databaseURL: 'https://iiitrhackthon-default-rtdb.firebaseio.com',
    storageBucket: 'iiitrhackthon.firebasestorage.app',
  );
}

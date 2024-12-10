// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAprGOBRR0TexMY671TpRnPC7peXuLzCJo',
    appId: '1:247859388587:android:d9d891e92d39e6b15057ee',
    messagingSenderId: '247859388587',
    projectId: 'smart-parking-1130e',
    storageBucket: 'smart-parking-1130e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDiJ5HPIFAdXDpvAazum8T_gsA-qZSzQ-0',
    appId: '1:247859388587:ios:fb6eabe30e811ee55057ee',
    messagingSenderId: '247859388587',
    projectId: 'smart-parking-1130e',
    storageBucket: 'smart-parking-1130e.firebasestorage.app',
    iosBundleId: 'com.example.iotbasedparking',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDiJ5HPIFAdXDpvAazum8T_gsA-qZSzQ-0',
    appId: '1:247859388587:ios:fb6eabe30e811ee55057ee',
    messagingSenderId: '247859388587',
    projectId: 'smart-parking-1130e',
    storageBucket: 'smart-parking-1130e.firebasestorage.app',
    iosBundleId: 'com.example.iotbasedparking',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAGnXvKWz4h3JS8Od67jczyAQRaHxYS8wg',
    appId: '1:247859388587:web:13268d771a2532195057ee',
    messagingSenderId: '247859388587',
    projectId: 'smart-parking-1130e',
    authDomain: 'smart-parking-1130e.firebaseapp.com',
    storageBucket: 'smart-parking-1130e.firebasestorage.app',
    measurementId: 'G-X0ZZYW3G24',
  );
}

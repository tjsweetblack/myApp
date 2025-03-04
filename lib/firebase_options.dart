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
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBY2BAhoZCL7oKI8HaQ7vvuV708mhSR1vE',
    appId: '1:519771029544:web:cc64fcbd509bda9ad6f51d',
    messagingSenderId: '519771029544',
    projectId: 'my-first-app-7ea2c',
    authDomain: 'my-first-app-7ea2c.firebaseapp.com',
    storageBucket: 'my-first-app-7ea2c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCB2k_gM8N9YxgkFTd1dAdZTULsl-UVrcg',
    appId: '1:519771029544:android:925d7551d86c6057d6f51d',
    messagingSenderId: '519771029544',
    projectId: 'my-first-app-7ea2c',
    storageBucket: 'my-first-app-7ea2c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcET2eia2ytY0zFhO5nDxeLcxaRCNs4QY',
    appId: '1:519771029544:ios:7231660c6f4f81ffd6f51d',
    messagingSenderId: '519771029544',
    projectId: 'my-first-app-7ea2c',
    storageBucket: 'my-first-app-7ea2c.firebasestorage.app',
    iosBundleId: 'com.example.authBloc',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBcET2eia2ytY0zFhO5nDxeLcxaRCNs4QY',
    appId: '1:519771029544:ios:7231660c6f4f81ffd6f51d',
    messagingSenderId: '519771029544',
    projectId: 'my-first-app-7ea2c',
    storageBucket: 'my-first-app-7ea2c.firebasestorage.app',
    iosBundleId: 'com.example.authBloc',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAJzZi5xn99IBKDZExyTpB6hW-qJEFBpYg',
    appId: '1:519771029544:web:ee5b0b35330b0659d6f51d',
    messagingSenderId: '519771029544',
    projectId: 'my-first-app-7ea2c',
    authDomain: 'my-first-app-7ea2c.firebaseapp.com',
    storageBucket: 'my-first-app-7ea2c.firebasestorage.app',
  );
}

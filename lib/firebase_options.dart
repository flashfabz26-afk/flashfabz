
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
    apiKey: 'AIzaSyCWLa5Tc9hoPATtRkUfYKU7SJ3eL-KywUg',
    appId: '1:787525097249:web:ace441a05ff994917c1060',
    messagingSenderId: '787525097249',
    projectId: 'hrpcb-b3ab4',
    authDomain: 'hrpcb-b3ab4.firebaseapp.com',
    storageBucket: 'hrpcb-b3ab4.firebasestorage.app',
    measurementId: 'G-SKM0WL1MGW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOYWQzII9en6ZIsdumdu6qSB8oEk8kl80',
    appId: '1:787525097249:android:d8e56e6f038b98f57c1060',
    messagingSenderId: '787525097249',
    projectId: 'hrpcb-b3ab4',
    storageBucket: 'hrpcb-b3ab4.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCWLa5Tc9hoPATtRkUfYKU7SJ3eL-KywUg',
    appId: '1:787525097249:web:2a00c8f7c567cee97c1060',
    messagingSenderId: '787525097249',
    projectId: 'hrpcb-b3ab4',
    authDomain: 'hrpcb-b3ab4.firebaseapp.com',
    storageBucket: 'hrpcb-b3ab4.firebasestorage.app',
    measurementId: 'G-WDN8HVHLFG',
  );
}

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDD1xBc1WRkKfvEWahM0fmGGj7zDkhrll0',
    appId: '1:437910509347:web:286181696fa3bdaf519e96',
    messagingSenderId: '437910509347',
    projectId: 'resturant-app-b444c',
    authDomain: 'resturant-app-b444c.firebaseapp.com',
    storageBucket: 'resturant-app-b444c.firebasestorage.app',
    measurementId: 'G-TMY95R35S1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDD1xBc1WRkKfvEWahM0fmGGj7zDkhrll0',
    appId: '1:437910509347:android:286181696fa3bdaf519e96',
    messagingSenderId: '437910509347',
    projectId: 'resturant-app-b444c',
    storageBucket: 'resturant-app-b444c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDD1xBc1WRkKfvEWahM0fmGGj7zDkhrll0',
    appId: '1:437910509347:ios:286181696fa3bdaf519e96',
    messagingSenderId: '437910509347',
    projectId: 'resturant-app-b444c',
    storageBucket: 'resturant-app-b444c.firebasestorage.app',
    iosBundleId: 'com.monojog.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDD1xBc1WRkKfvEWahM0fmGGj7zDkhrll0',
    appId: '1:437910509347:ios:286181696fa3bdaf519e96',
    messagingSenderId: '437910509347',
    projectId: 'resturant-app-b444c',
    storageBucket: 'resturant-app-b444c.firebasestorage.app',
    iosBundleId: 'com.monojog.app',
  );
}

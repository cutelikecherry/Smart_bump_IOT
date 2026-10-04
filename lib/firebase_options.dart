
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
    apiKey: 'AIzaSyA3rd8nIdHDZ_69pZ8TtXLYnN9-hSPEmCs',
    appId: '1:272936586203:web:ddaf46a93a7878911bb5fe',
    messagingSenderId: '272936586203',
    projectId: 'smart-bump-iot-3e764',
    authDomain: 'smart-bump-iot-3e764.firebaseapp.com',
    databaseURL: 'https://smart-bump-iot-3e764-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-bump-iot-3e764.firebasestorage.app',
    measurementId: 'G-GBQL3EV2G1',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVseytV_ZEw_d6eNh7KhqthpGVGe6Hbb4',
    appId: '1:272936586203:ios:f3662e1c58d883621bb5fe',
    messagingSenderId: '272936586203',
    projectId: 'smart-bump-iot-3e764',
    databaseURL: 'https://smart-bump-iot-3e764-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-bump-iot-3e764.firebasestorage.app',
    iosBundleId: 'com.example.smartBump',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAVseytV_ZEw_d6eNh7KhqthpGVGe6Hbb4',
    appId: '1:272936586203:ios:f3662e1c58d883621bb5fe',
    messagingSenderId: '272936586203',
    projectId: 'smart-bump-iot-3e764',
    databaseURL: 'https://smart-bump-iot-3e764-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-bump-iot-3e764.firebasestorage.app',
    iosBundleId: 'com.example.smartBump',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA3rd8nIdHDZ_69pZ8TtXLYnN9-hSPEmCs',
    appId: '1:272936586203:web:5c762ed0bcf6d1531bb5fe',
    messagingSenderId: '272936586203',
    projectId: 'smart-bump-iot-3e764',
    authDomain: 'smart-bump-iot-3e764.firebaseapp.com',
    databaseURL: 'https://smart-bump-iot-3e764-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-bump-iot-3e764.firebasestorage.app',
    measurementId: 'G-CVK6BR4HZW',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4rJ7BGHpul5dC3LSvbypsQwf9QKz8qmw',
    appId: '1:272936586203:android:aec09b243cd388781bb5fe',
    messagingSenderId: '272936586203',
    projectId: 'smart-bump-iot-3e764',
    databaseURL: 'https://smart-bump-iot-3e764-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-bump-iot-3e764.firebasestorage.app',
  );
}

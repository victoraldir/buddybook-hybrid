import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import flutter/foundation for platform detection

import 'core/constants/env_constants.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: EnvConstants.firebaseApiKey,
        appId: '1:491981440588:android:05b6af274e32f2894a96e9',
        messagingSenderId: '491981440588',
        projectId: 'buddybookflutter-ccac6',
        databaseURL:
            'https://buddybookflutter-ccac6-default-rtdb.europe-west1.firebasedatabase.app',
        storageBucket: 'buddybookflutter-ccac6.firebasestorage.app',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: EnvConstants.firebaseApiKey,
        appId: '1:491981440588:ios:your-ios-app-id',
        messagingSenderId: '491981440588',
        projectId: 'buddybookflutter-ccac6',
        databaseURL:
            'https://buddybookflutter-ccac6-default-rtdb.europe-west1.firebasedatabase.app',
        storageBucket: 'buddybookflutter-ccac6.firebasestorage.app',
        iosBundleId: 'com.quartzodev.buddybook',
      );

  // TODO: Add your Firebase Web configuration keys here
  // You can get these from Firebase Console -> Project Settings -> General -> Web Apps
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: EnvConstants.firebaseApiKey,
        appId: '1:491981440588:web:YOUR_WEB_APP_ID',
        messagingSenderId: '491981440588',
        projectId: 'buddybookflutter-ccac6',
        authDomain: 'buddybookflutter-ccac6.firebaseapp.com',
        databaseURL:
            'https://buddybookflutter-ccac6-default-rtdb.europe-west1.firebasedatabase.app',
        storageBucket: 'buddybookflutter-ccac6.firebasestorage.app',
        measurementId: 'G-YOUR_MEASUREMENT_ID',
      );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return android;
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String productionBackendUrl = 'https://velocity.linkitapp.in';

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDQ4bqkqaJmwJ7GtEW8IFMHg1-6J0rjd44',
  );
  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:828589273527:web:89afddf2cc42d99b5b3832',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '828589273527',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'velocity-transit-7f723',
  );
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'velocity-transit-7f723.firebaseapp.com',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'velocity-transit-7f723.firebasestorage.app',
  );

  static FirebaseOptions get firebaseOptions => const FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    authDomain: firebaseAuthDomain,
    storageBucket: firebaseStorageBucket,
  );

  static String get backendBaseUrl {
    const override = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return productionBackendUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      default:
        return productionBackendUrl;
    }
  }
}

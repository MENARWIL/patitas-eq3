import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _webAppId = String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _projectId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      (kIsWeb ? _webAppId.isNotEmpty : _androidAppId.isNotEmpty);

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError('Faltan opciones de Firebase. Revisa README.md.');
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: kIsWeb ? _webAppId : _androidAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: kIsWeb
          ? const String.fromEnvironment(
                  'FIREBASE_AUTH_DOMAIN',
                  defaultValue: '',
                ).isEmpty
                ? '$_projectId.firebaseapp.com'
                : const String.fromEnvironment('FIREBASE_AUTH_DOMAIN')
          : null,
      storageBucket:
          const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: '',
          ).isEmpty
          ? null
          : const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    );
  }
}

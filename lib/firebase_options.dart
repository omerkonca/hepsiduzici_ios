import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase yapılandırması — anahtarlar repoda tutulmaz.
///
/// iOS: `ios/Runner/GoogleService-Info.plist` (Codemagic secret / yerel dosya)
/// Android: `android/app/google-services.json`
/// Yedek: `--dart-define=FIREBASE_*` (Codemagic environment)
class DefaultFirebaseOptions {
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String _androidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '');
  static const String _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');
  static const String _iosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: '');
  static const String _iosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '');

  static bool get isConfigured {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidApiKey.isNotEmpty && _androidAppId.isNotEmpty;
      case TargetPlatform.iOS:
        return _iosApiKey.isNotEmpty && _iosAppId.isNotEmpty;
      default:
        return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase push web desteklenmiyor.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('$defaultTargetPlatform desteklenmiyor.');
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _androidApiKey,
        appId: _androidAppId,
        messagingSenderId: _senderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isNotEmpty
            ? _storageBucket
            : '$_projectId.appspot.com',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _iosApiKey,
        appId: _iosAppId,
        messagingSenderId: _senderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isNotEmpty
            ? _storageBucket
            : '$_projectId.appspot.com',
        iosBundleId: 'net.hepsiduzici.hepsiDuzici',
      );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase istemci yapılandırması (public config).
class DefaultFirebaseOptions {
  static const String projectId = 'hepsiduzici-84436';
  static const String messagingSenderId = '967533721193';
  static const String storageBucket = 'hepsiduzici-84436.firebasestorage.app';

  static const String androidApiKey = 'AIzaSyDVGJJUcvfyFRI2c6b_Z43szoSPK1TsOeA';
  static const String androidAppId =
      '1:967533721193:android:21d0f3fe2ff04c5737d4f8';

  static const String iosApiKey = 'AIzaSyCAbRMtb_vByT8MkRWFXYZBaunK5EiPW_c';
  static const String iosAppId = '1:967533721193:ios:73b9135346c7b2cf37d4f8';

  static bool get isConfigured {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidApiKey.isNotEmpty && androidAppId.isNotEmpty;
      case TargetPlatform.iOS:
        return iosApiKey.isNotEmpty && iosAppId.isNotEmpty;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: androidApiKey,
    appId: androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: iosApiKey,
    appId: iosAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'net.hepsiduzici.hepsiDuzici',
  );
}

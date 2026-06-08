import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Firebase'i başlatır: önce native config (google-services.json / plist),
/// olmazsa dart-define / flutterfire options dener.
class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    if (kIsWeb) return false;

    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return true;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
      if (kDebugMode) debugPrint('[Firebase] Native config ile başlatıldı.');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] Native init: $e');
    }

    if (DefaultFirebaseOptions.isConfigured) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _initialized = true;
        if (kDebugMode) debugPrint('[Firebase] dart-define ile başlatıldı.');
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('[Firebase] Options init: $e');
      }
    }

    return false;
  }
}

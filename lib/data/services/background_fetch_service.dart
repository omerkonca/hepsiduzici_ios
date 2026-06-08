import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';

import 'news_background_checker.dart';

class BackgroundFetchService {
  BackgroundFetchService._();

  static const String newsFetchTask = 'com.hepsiduzici.news_fetch_task';
  static const String _uniqueTaskName = 'news_fetch_periodic';

  // Tanı anahtarları (NewsBackgroundChecker ile paylaşılır)
  static const String lastRunAtKey = NewsBackgroundChecker.lastRunAtKey;
  static const String lastStatusKey = NewsBackgroundChecker.lastStatusKey;
  static const String lastErrorKey = NewsBackgroundChecker.lastErrorKey;

  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicTask() async {
    // workmanager 0.5.2: periyodik kayıt yalnızca Android; iOS Background Fetch kullanır.
    if (!kIsWeb && Platform.isIOS) return;

    await Workmanager().registerPeriodicTask(
      _uniqueTaskName,
      newsFetchTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 2),
      existingWorkPolicy: ExistingWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case Workmanager.iOSBackgroundTask:
      case BackgroundFetchService.newsFetchTask:
        await NewsBackgroundChecker.run();
        break;
      default:
        await NewsBackgroundChecker.run();
    }
    return true;
  });
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';
import 'core/config/app_defaults.dart';
import 'data/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/scanner_service.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  await Hive.initFlutter();

  final storage = LocalStorageService();
  await storage.init();

  final notifications = NotificationService();
  await notifications.init();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'scanner_service',
      channelName: 'Scanner',
      channelDescription: 'Background scan notification',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(AppDefaults.scanIntervalSeconds * 1000),
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: buildAppProviders(
        storage: storage,
        notifications: notifications,
        scannerServiceFactory: (deps) => ScannerService(
          marketRepository: deps.marketRepository,
          recommendationRepository: deps.recommendationRepository,
          settingsRepository: deps.settingsRepository,
          notificationService: notifications,
        ),
      ),
      child: const App(),
    ),
  );
}

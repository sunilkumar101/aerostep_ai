import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/aero_database.dart';
import '../widgets/home_widget_bridge.dart';
import 'step_engine.dart';
import 'streak.dart';

/// Android foreground service that keeps the [StepEngine] alive when the
/// screen is locked (Android 14/15 kill background work otherwise). Uses the
/// `health` foreground-service type, which has no 6-hour daily cap.
abstract final class StepService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aerostep_tracking',
        channelName: 'Step tracking',
        channelDescription: 'Keeps AeroStep counting steps while your screen is off. No GPS is used.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60 * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: false, // hardware step counter wakes us; no wake lock needed
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> start() async {
    if (!Platform.isAndroid) return false;
    if (await FlutterForegroundTask.isRunningService) return true;
    final r = await FlutterForegroundTask.startService(
      serviceId: 4242,
      serviceTypes: const [ForegroundServiceTypes.health],
      notificationTitle: 'AeroStep is counting',
      notificationText: 'Zero GPS • Anti-Shake active',
      callback: startStepServiceCallback,
    );
    if (r is ServiceRequestFailure) debugPrint('StepService start failed: ${r.error}');
    return r is ServiceRequestSuccess;
  }

  static Future<void> stop() => FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
void startStepServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_StepTaskHandler());
}

class _StepTaskHandler extends TaskHandler {
  StepEngine? _engine;
  AeroDatabase? _db;
  final _fmt = NumberFormat.decimalPattern();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    final db = _db = AeroDatabase();
    final engine = _engine = StepEngine(
      db: db,
      prefs: prefs,
      autoPauseVehicles: prefs.getBool('auto_pause_vehicles') ?? true,
      onChanged: (s) {
        FlutterForegroundTask.sendDataToMain(s.toJson());
        unawaited(_updateNotification());
      },
    );
    await engine.start();
    await _updateNotification();
  }

  Future<void> _updateNotification() async {
    final db = _db;
    if (db == null) return;
    final now = DateTime.now();
    final entries = await db.entriesSince(now.toUtc().subtract(const Duration(days: 2)));
    final steps = dailyTotals(entries)[dayKey(now)] ?? 0;
    final vehicle = _engine?.gate.vehicleDetected ?? false;
    // Keep home-screen widgets live even while the app UI is closed.
    try {
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.updateWidget(qualifiedAndroidName: HomeWidgetBridge.androidSmall);
      await HomeWidget.updateWidget(qualifiedAndroidName: HomeWidgetBridge.androidBento);
    } catch (_) {}
    await FlutterForegroundTask.updateService(
      notificationTitle: '${_fmt.format(steps)} steps today',
      notificationText: vehicle ? 'Vehicle detected • counting paused' : 'Zero GPS • Anti-Shake active',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_updateNotification());
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['autoPause'] is bool) {
      _engine?.autoPauseVehicles = data['autoPause'] as bool;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _engine?.stop();
    await _db?.close();
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp('/');
}

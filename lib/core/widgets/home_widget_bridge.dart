import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/activity_state.dart';

/// Pushes live numbers to the native home-screen widgets (Android RemoteViews
/// providers + iOS WidgetKit extension) and handles the interactive +250 ml tap.
abstract final class HomeWidgetBridge {
  /// Shared App Group so the WidgetKit extension can read the values.
  static const appGroupId = 'group.com.sunilkhatri.aerostep';
  static const iOSSmall = 'AeroStepSmallWidget';
  static const iOSBento = 'AeroStepBentoWidget';
  static const androidSmall = 'com.sunilkhatri.aerostep.AeroStepSmallWidgetProvider';
  static const androidBento = 'com.sunilkhatri.aerostep.AeroStepBentoWidgetProvider';

  static Future<void> init() async {
    try {
      if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.registerInteractivityCallback(homeWidgetInteraction);
    } catch (e) {
      debugPrint('HomeWidgetBridge.init: $e');
    }
  }

  static int? _lastSteps;
  static int? _lastMl;

  static Future<void> push(ActivitySnapshot a, int hydrationMl) async {
    if (a.steps == _lastSteps && hydrationMl == _lastMl) return;
    _lastSteps = a.steps;
    _lastMl = hydrationMl;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>('steps', a.steps),
        HomeWidget.saveWidgetData<int>('goal', a.goal),
        HomeWidget.saveWidgetData<int>('kcal', a.kcal),
        HomeWidget.saveWidgetData<int>('cadence', a.cadenceSpm),
        HomeWidget.saveWidgetData<int>('hydration_ml', hydrationMl),
      ]);
      await _refresh();
    } catch (e) {
      debugPrint('HomeWidgetBridge.push: $e');
    }
  }

  static Future<void> _refresh() async {
    await HomeWidget.updateWidget(qualifiedAndroidName: androidSmall, iOSName: iOSSmall);
    await HomeWidget.updateWidget(qualifiedAndroidName: androidBento, iOSName: iOSBento);
  }
}

/// Runs in a background isolate when the widget's +250ml button is tapped.
@pragma('vm:entry-point')
Future<void> homeWidgetInteraction(Uri? uri) async {
  if (uri?.host != 'water') return;
  WidgetsFlutterBinding.ensureInitialized();
  final ml = int.tryParse(uri?.queryParameters['ml'] ?? '') ?? 250;
  final prefs = await SharedPreferences.getInstance();
  final n = DateTime.now();
  final today = '${n.year}-${n.month}-${n.day}';
  final current = prefs.getString('hydration_day') == today ? (prefs.getInt('hydration_ml') ?? 0) : 0;
  final next = current + ml;
  await prefs.setString('hydration_day', today);
  await prefs.setInt('hydration_ml', next);
  await HomeWidget.saveWidgetData<int>('hydration_ml', next);
  await HomeWidget.updateWidget(
    qualifiedAndroidName: HomeWidgetBridge.androidBento,
    iOSName: HomeWidgetBridge.iOSBento,
  );
}

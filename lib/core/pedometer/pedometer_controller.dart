import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/aero_database.dart';
import '../data/database_provider.dart';
import '../state/activity_state.dart';
import '../state/app_settings.dart';
import 'snapshot_builder.dart';
import 'step_engine.dart';

/// Main-isolate coordinator: runs the [StepEngine] while the app is alive and
/// republishes the ledger into [activityProvider] whenever it changes.
///
/// No foreground service: the hardware step counter keeps counting on its
/// own while the app is closed, and the engine credits that backlog (spread
/// over the elapsed time) the next time the app starts or resumes.
class PedometerController with WidgetsBindingObserver {
  PedometerController(this.ref);
  final Ref ref;

  StepEngine? _localEngine;
  EngineStatus _status = const EngineStatus(cadenceSpm: 0, vehicle: false, walking: false);
  Timer? _refreshTimer;
  bool _started = false;
  bool _refreshing = false;

  AeroDatabase get _db => ref.read(databaseProvider);

  Future<void> start() async {
    if (_started || kAeroDemoMode) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }

    final engine = _localEngine = StepEngine(
      db: _db,
      prefs: ref.read(sharedPrefsProvider),
      autoPauseVehicles: ref.read(userProfileProvider).autoPauseVehicles,
      onChanged: (s) {
        _status = s;
        unawaited(refresh());
      },
    );
    await engine.start();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    await refresh();
  }

  void setAutoPause(bool v) {
    _localEngine?.autoPauseVehicles = v;
  }

  Future<bool> requestHealthAccess() async {
    final engine = _localEngine ?? StepEngine(db: _db, prefs: ref.read(sharedPrefsProvider), onChanged: (_) {});
    final ok = await engine.health.requestPermission();
    if (ok) {
      await engine.health.sync(lookback: const Duration(days: 7));
      await refresh();
    }
    return ok;
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final profile = ref.read(userProfileProvider);
      final snap = await SnapshotBuilder(_db).build(
        goal: profile.stepGoal,
        strideM: profile.strideLengthM,
        weightKg: profile.weightKg,
        cadenceSpm: _status.cadenceSpm,
        vehicle: _status.vehicle,
        shieldsAvailable: ref.read(streakShieldProvider),
        onShieldsUsed: (n) {
          for (var i = 0; i < n; i++) {
            ref.read(streakShieldProvider.notifier).consume();
          }
        },
      );
      ref.read(activityProvider.notifier).publish(snap);
    } catch (e) {
      debugPrint('PedometerController.refresh: $e');
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The home-screen widget may have logged water from a background isolate.
      unawaited(_syncWidgetHydration());
      unawaited(refresh());
      unawaited(_localEngine?.syncHealth());
    }
  }

  /// Water logged from a home-screen widget (Android background isolate or the
  /// iOS App Intent) lands outside this isolate; fold it back in on resume.
  Future<void> _syncWidgetHydration() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.reload();
    if (Platform.isIOS) {
      final fromWidget = await HomeWidget.getWidgetData<int>('hydration_ml');
      if (fromWidget != null && fromWidget > (prefs.getInt('hydration_ml') ?? 0)) {
        await prefs.setInt('hydration_ml', fromWidget);
      }
    }
    ref.invalidate(hydrationProvider);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    unawaited(_localEngine?.stop());
  }
}

final pedometerControllerProvider = Provider<PedometerController>((ref) {
  final c = PedometerController(ref);
  ref.onDispose(c.dispose);
  return c;
});

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/aero_database.dart';
import 'accel_cadence.dart';
import 'cadence_gate.dart';
import 'health_sync.dart';

/// Live status published after every ledger change.
class EngineStatus {
  const EngineStatus({required this.cadenceSpm, required this.vehicle, required this.walking});
  final int cadenceSpm;
  final bool vehicle;
  final bool walking;

  Map<String, Object> toJson() => {'cadence': cadenceSpm, 'vehicle': vehicle, 'walking': walking};

  static EngineStatus fromJson(Map data) => EngineStatus(
        cadenceSpm: (data['cadence'] as num?)?.toInt() ?? 0,
        vehicle: data['vehicle'] == true,
        walking: data['walking'] == true,
      );
}

/// Zero-GPS step engine.
///
/// * Hardware step counter (`TYPE_STEP_COUNTER` / `CMPedometer`) is the only
///   always-on sensor, so idle battery cost is negligible.
/// * Raw deltas pass through the [CadenceGate] (60–220 SPM for > 6 s).
/// * The accelerometer (~120 Hz) is switched on only while a new bout is being
///   validated, as a shake veto, and switched off again once walking is proven.
/// * Activity recognition (`IN_VEHICLE`, `ON_BICYCLE`) pauses counting.
/// * Health Connect / HealthKit are merged every 15 minutes.
class StepEngine {
  StepEngine({
    required this.db,
    required this.prefs,
    required this.onChanged,
    this.autoPauseVehicles = true,
  });

  final AeroDatabase db;
  final SharedPreferences prefs;
  final void Function(EngineStatus status) onChanged;
  bool autoPauseVehicles;

  final CadenceGate gate = CadenceGate();
  final AccelCadenceEstimator _accel = AccelCadenceEstimator();
  late final HealthSync health = HealthSync(db);

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<Activity>? _activitySub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _tick;
  Timer? _healthTimer;
  DateTime? _walkingSince;
  bool _running = false;

  static const _lastRawKey = 'engine_last_raw_steps';

  bool get running => _running;

  EngineStatus get status => EngineStatus(
        cadenceSpm: gate.cadenceSpm.round(),
        vehicle: gate.vehicleDetected,
        walking: gate.isWalking,
      );

  Future<void> start() async {
    if (_running) return;
    _running = true;

    _stepSub = Pedometer.stepCountStream.listen(
      (e) => _onRawCount(e.steps, e.timeStamp),
      onError: (Object e) => debugPrint('StepEngine step stream error: $e'),
      cancelOnError: false,
    );

    try {
      final ar = FlutterActivityRecognition.instance;
      var perm = await ar.checkPermission();
      if (perm != ActivityPermission.GRANTED) perm = await ar.requestPermission();
      if (perm == ActivityPermission.GRANTED) {
        _activitySub = ar.activityStream.listen(_onActivity, onError: (Object e) => debugPrint('activity: $e'));
      }
    } catch (e) {
      debugPrint('StepEngine activity recognition unavailable: $e');
    }

    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _healthTimer = Timer.periodic(const Duration(minutes: 15), (_) => syncHealth());
    unawaited(syncHealth());
  }

  Future<void> stop() async {
    _running = false;
    await _stepSub?.cancel();
    await _activitySub?.cancel();
    await _stopAccel();
    _tick?.cancel();
    _healthTimer?.cancel();
  }

  Future<void> syncHealth() async {
    final n = await health.sync();
    if (n > 0) onChanged(status);
  }

  /// Visible for tests: process a cumulative hardware counter reading.
  Future<void> _onRawCount(int raw, DateTime at) async {
    final last = prefs.getInt(_lastRawKey);
    await prefs.setInt(_lastRawKey, raw);
    if (last == null) return; // first reading establishes the baseline
    // Counter resets to 0 on reboot.
    final delta = raw >= last ? raw - last : raw;
    if (delta <= 0) return;

    if (!gate.isWalking) _startAccel();
    final d = gate.addSteps(delta, at);
    if (gate.isWalking) {
      _walkingSince ??= at;
      // Rhythm proven for 30 s: drop the accelerometer to save battery.
      if (at.difference(_walkingSince!) > const Duration(seconds: 30)) unawaited(_stopAccel());
    } else {
      _walkingSince = null;
    }
    if (d.committed > 0) {
      await db.addPhoneSteps(at, d.committed);
      onChanged(status);
    }
  }

  void _onActivity(Activity a) {
    final ctx = switch (a.type) {
      ActivityType.IN_VEHICLE => MotionContext.vehicle,
      ActivityType.ON_BICYCLE => MotionContext.bicycle,
      ActivityType.WALKING => MotionContext.walking,
      ActivityType.RUNNING => MotionContext.running,
      ActivityType.STILL => MotionContext.still,
      _ => MotionContext.unknown,
    };
    if (!autoPauseVehicles && (ctx == MotionContext.vehicle || ctx == MotionContext.bicycle)) {
      gate.updateContext(MotionContext.unknown);
    } else {
      gate.updateContext(ctx);
    }
    onChanged(status);
  }

  void _onTick() {
    final d = gate.tick(DateTime.now());
    if (d.rejected > 0 || (!gate.isWalking && _accelSub != null && gate.pendingSteps == 0)) {
      unawaited(_stopAccel());
      _walkingSince = null;
    }
  }

  void _startAccel() {
    if (_accelSub != null) return;
    _accel.reset();
    try {
      _accelSub = accelerometerEventStream(samplingPeriod: const Duration(microseconds: 8333)).listen(
        (e) {
          _accel.add(e.timestamp, e.x, e.y, e.z);
          gate.updateAccelCadence(_accel.cadence);
        },
        onError: (Object e) => debugPrint('accelerometer: $e'),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('StepEngine accelerometer unavailable: $e');
    }
  }

  Future<void> _stopAccel() async {
    await _accelSub?.cancel();
    _accelSub = null;
    gate.updateAccelCadence(null);
  }
}

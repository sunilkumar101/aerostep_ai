import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
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

/// Zero-GPS step engine (runs while the app is alive; no foreground service).
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
  static const _lastRawAtKey = 'engine_last_raw_at_ms';
  final _rawQueue = <(int, DateTime)>[];
  Timer? _flushTimer;

  /// Accelerometer RMS (m/s²) above which motion is treated as shaking.
  static const violentRms = 8.0;

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
      // The plugin's permission calls need an Activity, which the background
      // service isolate doesn't have; its event stream only needs a Context.
      // The main isolate requests the permission, so here we only check it.
      if (await Permission.activityRecognition.isGranted) {
        _activitySub = FlutterActivityRecognition.instance.activityStream
            .listen(_onActivity, onError: (Object e) => debugPrint('activity: $e'));
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
    _flushTimer?.cancel();
  }

  Future<void> syncHealth() async {
    final n = await health.sync();
    if (n > 0) onChanged(status);
  }

  /// Raw counter readings are coalesced briefly: when the screen is off the
  /// OS queues step events and later delivers them in one burst, all stamped
  /// with the delivery time.
  void _onRawCount(int raw, DateTime at) {
    _rawQueue.add((raw, at));
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 350), () => unawaited(_flushRaw()));
  }

  Future<void> _flushRaw() async {
    if (_rawQueue.isEmpty) return;
    final batch = List.of(_rawQueue);
    _rawQueue.clear();
    final (raw, at) = batch.last;
    final last = prefs.getInt(_lastRawKey);
    final lastAtMs = prefs.getInt(_lastRawAtKey);
    await prefs.setInt(_lastRawKey, raw);
    await prefs.setInt(_lastRawAtKey, at.millisecondsSinceEpoch);
    if (last == null) return; // first reading establishes the baseline
    // Counter resets to 0 on reboot.
    final delta = raw >= last ? raw - last : raw;
    if (delta <= 0) return;

    final since = lastAtMs == null ? Duration.zero : at.difference(DateTime.fromMillisecondsSinceEpoch(lastAtMs));
    final burst = batch.length >= 3 || delta >= 4;
    final backlog = burst && since >= gate.validationWindow;
    final GateDecision d;
    if (backlog) {
      // Backlog flush: judge by the whole interval, not by delivery times.
      final ok = gate.acceptBacklog(delta, since);
      d = GateDecision(ok, delta - ok);
      _walkingSince = null;
    } else {
      if (!gate.isWalking) _startAccel();
      d = gate.addSteps(delta, at);
      if (gate.isWalking) {
        _walkingSince ??= at;
        // Rhythm proven for 30 s: drop the accelerometer to save battery.
        if (at.difference(_walkingSince!) > const Duration(seconds: 30)) unawaited(_stopAccel());
      } else {
        _walkingSince = null;
      }
    }

    if (kDebugMode) {
      debugPrint('AERO_GATE d=$delta n=${batch.length} since=${since.inSeconds}s backlog=$backlog '
          '+${d.committed} -${d.rejected} walking=${gate.isWalking} cad=${gate.cadenceSpm.toStringAsFixed(0)} '
          'accelCad=${_accel.cadence?.toStringAsFixed(0)} rms=${_accel.rms?.toStringAsFixed(2)} ctx=${gate.context.name}');
    }
    if (d.committed > 0) {
      if (backlog && lastAtMs != null) {
        // Steps counted while the app was closed: spread them over the gap.
        for (final (t, n) in spreadBacklog(d.committed, DateTime.fromMillisecondsSinceEpoch(lastAtMs), at)) {
          await db.addPhoneSteps(t, n);
        }
      } else {
        await db.addPhoneSteps(at, d.committed);
      }
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
          // Veto only on violent motion (hand shaking). The accelerometer's
          // zero-crossing cadence counts ~2 peaks per real step (heel strike +
          // push-off), so it must not be compared against the step band.
          // Field data (Oppo CPH1937): walking RMS 1.4–3.6 m/s².
          final violent = (_accel.rms ?? 0) > violentRms;
          gate.updateAccelCadence(violent ? 999 : null);
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

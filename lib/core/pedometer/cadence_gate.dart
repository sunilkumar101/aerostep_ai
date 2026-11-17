/// Anti-shake and vehicle filter for raw hardware step events.
///
/// Steps reported by the OS step counter are held in a pending buffer until a
/// valid walking rhythm is proven: cadence 60–220 SPM sustained for more than
/// [validationWindow] (6 s). Bursts that never reach that bar (hand shakes,
/// bumps, picking the phone up) are discarded. While the activity recogniser
/// reports `IN_VEHICLE` / `ON_BICYCLE`, or the accelerometer shows a shake
/// frequency far above human walking, nothing is committed.
library;

enum MotionContext { unknown, still, walking, running, vehicle, bicycle }

class GateDecision {
  const GateDecision(this.committed, this.rejected);

  /// Steps accepted into the ledger by this event.
  final int committed;

  /// Steps thrown away by this event.
  final int rejected;

  static const none = GateDecision(0, 0);
}

class _Pending {
  _Pending(this.at, this.steps);
  final DateTime at;
  final int steps;
}

class CadenceGate {
  CadenceGate({
    this.minSpm = 60,
    this.maxSpm = 220,
    this.validationWindow = const Duration(seconds: 6),
    this.maxGap = const Duration(seconds: 3),
    this.shakeSpm = 260,
  });

  final double minSpm;
  final double maxSpm;
  final Duration validationWindow;

  /// A pause longer than this ends the current walking bout.
  final Duration maxGap;

  /// Accelerometer cadence above this is treated as shaking, not walking.
  final double shakeSpm;

  final List<_Pending> _pending = [];
  final List<_Pending> _recent = [];
  bool _walking = false;
  DateTime? _lastEvent;
  MotionContext _context = MotionContext.unknown;
  double? _accelSpm;

  bool get isWalking => _walking;
  MotionContext get context => _context;
  int get pendingSteps => _pending.fold(0, (a, p) => a + p.steps);
  bool get vehicleDetected => _context == MotionContext.vehicle || _context == MotionContext.bicycle;

  /// Current rolling cadence (steps per minute) over the last window, or 0.
  double get cadenceSpm => _spm(_recent.isNotEmpty ? _recent : _pending);

  /// Update the activity-recognition context. Entering a vehicle drops any
  /// unverified steps and ends the current walking bout.
  GateDecision updateContext(MotionContext c) {
    _context = c;
    if (vehicleDetected) {
      final dropped = pendingSteps;
      _pending.clear();
      _recent.clear();
      _walking = false;
      return GateDecision(0, dropped);
    }
    return GateDecision.none;
  }

  /// Latest accelerometer-derived cadence estimate (see [AccelCadenceEstimator]).
  void updateAccelCadence(double? spm) => _accelSpm = spm;

  /// Feed a step-counter delta observed at [at]. Returns what was committed.
  GateDecision addSteps(int delta, DateTime at) {
    if (delta <= 0) return GateDecision.none;

    if (vehicleDetected) {
      _lastEvent = at;
      return GateDecision(0, delta);
    }

    var rejected = 0;
    final last = _lastEvent;
    if (last != null && at.difference(last) > maxGap) {
      // Bout ended: anything still unverified was not real walking.
      rejected += pendingSteps;
      _pending.clear();
      _recent.clear();
      _walking = false;
    }
    _lastEvent = at;

    final shaking = (_accelSpm ?? 0) > shakeSpm;

    if (_walking) {
      _recent.add(_Pending(at, delta));
      _trim(_recent, at);
      final spm = _spm(_recent);
      final windowFull = _span(_recent) >= validationWindow * 0.5;
      if (shaking || (windowFull && (spm < minSpm || spm > maxSpm))) {
        // Rhythm broke (e.g. phone started being shaken). Re-validate.
        _walking = false;
        _recent.clear();
        _pending.add(_Pending(at, delta));
        return GateDecision(0, rejected);
      }
      return GateDecision(delta, rejected);
    }

    _pending.add(_Pending(at, delta));
    if (shaking) {
      rejected += pendingSteps;
      _pending.clear();
      return GateDecision(0, rejected);
    }

    if (_span(_pending) > validationWindow) {
      final spm = _spm(_pending);
      if (spm >= minSpm && spm <= maxSpm) {
        final accepted = pendingSteps;
        _recent
          ..clear()
          ..addAll(_pending);
        _pending.clear();
        _walking = true;
        return GateDecision(accepted, rejected);
      }
      // Too fast / too slow: slide the window forward, dropping the oldest.
      while (_pending.length > 1 && _span(_pending) > validationWindow) {
        rejected += _pending.removeAt(0).steps;
      }
    }
    return GateDecision(0, rejected);
  }

  /// Call periodically (e.g. every second). Expires a stale pending buffer.
  GateDecision tick(DateTime now) {
    final last = _lastEvent;
    if (last == null || now.difference(last) <= maxGap) return GateDecision.none;
    final dropped = pendingSteps;
    _pending.clear();
    _recent.clear();
    _walking = false;
    return GateDecision(0, dropped);
  }

  void _trim(List<_Pending> list, DateTime now) {
    while (list.length > 2 && now.difference(list.first.at) > validationWindow) {
      list.removeAt(0);
    }
  }

  static Duration _span(List<_Pending> l) => l.length < 2 ? Duration.zero : l.last.at.difference(l.first.at);

  /// Steps per minute across the buffer. The first event's steps happened
  /// before the window started, so they are excluded from the rate.
  static double _spm(List<_Pending> l) {
    if (l.length < 2) return 0;
    final secs = _span(l).inMilliseconds / 1000;
    if (secs <= 0) return 0;
    final steps = l.skip(1).fold<int>(0, (a, p) => a + p.steps);
    return steps / secs * 60;
  }
}

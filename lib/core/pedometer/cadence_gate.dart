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

  /// Steps the OS delivers as a batched backlog (non-wakeup step counters
  /// hold events while the screen is off and flush them all at once). Their
  /// arrival times are meaningless, so judge them by the whole interval since
  /// the previous reading: credit them when that interval is long enough and
  /// the implied cadence is humanly possible, and the user wasn't in a vehicle.
  /// Returns the number of steps to commit.
  int acceptBacklog(int delta, Duration sinceLastReading) {
    if (delta <= 0) return 0;
    if (vehicleDetected) return 0;
    if (sinceLastReading < validationWindow) return 0;
    final spm = delta / (sinceLastReading.inMilliseconds / 60000);
    if (spm > maxSpm) return 0;
    // A backlog ends any in-progress live bout; the next live steps re-validate.
    _pending.clear();
    _recent.clear();
    _walking = false;
    return delta;
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

/// Splits [steps] credited from a backlog evenly over the time between two
/// counter readings, in [bucket]-sized slices aligned to the UTC epoch.
///
/// Without a foreground service the hardware counter is read only when the
/// app runs, so a backlog can span hours or midnight. Spreading it keeps
/// daily and hourly totals close to when the walking actually happened,
/// instead of piling everything onto the moment the app was reopened.
/// Returns (time inside slice, steps) pairs whose steps sum to [steps].
List<(DateTime, int)> spreadBacklog(
  int steps,
  DateTime from,
  DateTime to, {
  Duration bucket = const Duration(minutes: 15),
}) {
  if (steps <= 0) return const [];
  final startMs = from.toUtc().millisecondsSinceEpoch;
  final endMs = to.toUtc().millisecondsSinceEpoch;
  final total = endMs - startMs;
  if (total <= bucket.inMilliseconds) return [(to, steps)];
  final b = bucket.inMilliseconds;
  final out = <(DateTime, int)>[];
  var given = 0;
  var cursor = startMs;
  while (cursor < endMs) {
    final sliceEnd = ((cursor ~/ b) + 1) * b;
    final end = sliceEnd < endMs ? sliceEnd : endMs;
    // Cumulative rounding keeps the sum exact.
    final share = ((end - startMs) * steps / total).round() - given;
    if (share > 0) {
      out.add((DateTime.fromMillisecondsSinceEpoch(cursor + (end - cursor) ~/ 2, isUtc: true), share));
      given += share;
    }
    cursor = end;
  }
  return out;
}

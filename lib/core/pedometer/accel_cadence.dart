import 'dart:collection';
import 'dart:math' as math;

/// Estimates step cadence (cycles per minute) from raw accelerometer samples
/// by counting upward crossings of the de-meaned acceleration magnitude with
/// hysteresis. Used as a veto: human walking/running sits at 60–220 SPM while
/// hand shaking oscillates far faster (4–8 Hz ≈ 240–480 cycles/min).
class AccelCadenceEstimator {
  AccelCadenceEstimator({
    this.window = const Duration(seconds: 3),
    this.hysteresis = 0.6,
    this.minEnergy = 0.35,
  });

  final Duration window;

  /// m/s² band around the mean that must be crossed to count a cycle.
  final double hysteresis;

  /// Below this RMS (m/s²) the device is considered still.
  final double minEnergy;

  final Queue<(DateTime, double)> _samples = Queue();

  void add(DateTime at, double x, double y, double z) {
    _samples.add((at, math.sqrt(x * x + y * y + z * z)));
    while (_samples.isNotEmpty && at.difference(_samples.first.$1) > window) {
      _samples.removeFirst();
    }
  }

  void reset() => _samples.clear();

  /// Cadence in cycles/minute, or null when there is too little data or motion.
  double? get cadence {
    if (_samples.length < 20) return null;
    final span = _samples.last.$1.difference(_samples.first.$1).inMilliseconds / 1000;
    if (span < 1) return null;
    final mean = _samples.fold<double>(0, (a, s) => a + s.$2) / _samples.length;
    final rms = math.sqrt(_samples.fold<double>(0, (a, s) => a + math.pow(s.$2 - mean, 2)) / _samples.length);
    if (rms < minEnergy) return 0;
    var crossings = 0;
    var below = true;
    for (final s in _samples) {
      final v = s.$2 - mean;
      if (below && v > hysteresis) {
        crossings++;
        below = false;
      } else if (!below && v < -hysteresis) {
        below = true;
      }
    }
    return crossings / span * 60;
  }
}

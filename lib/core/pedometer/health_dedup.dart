/// Zero-variance health sync: phone sensor steps and Health Connect /
/// HealthKit steps (which may include a smartwatch, or even this phone via
/// another app) are folded into 15-minute UTC buckets. Per bucket we keep the
/// larger of the two sources instead of adding them, so the same walk is never
/// counted twice while steps only one device saw are still credited.
library;

const bucketMinutes = 15;
const _bucketMs = bucketMinutes * 60 * 1000;

/// Start (UTC epoch ms) of the 15-minute bucket containing [t].
int bucketStartMs(DateTime t) {
  final ms = t.toUtc().millisecondsSinceEpoch;
  return ms - (ms % _bucketMs);
}

DateTime bucketStart(DateTime t) => DateTime.fromMillisecondsSinceEpoch(bucketStartMs(t), isUtc: true);

/// A health-store sample spanning [from]..[to] with [steps] steps.
class StepSample {
  const StepSample(this.from, this.to, this.steps);
  final DateTime from;
  final DateTime to;
  final int steps;
}

/// Spread samples across the 15-minute buckets they overlap, proportionally
/// to time overlap. Returns bucketStartMs -> steps.
Map<int, int> bucketize(Iterable<StepSample> samples) {
  final out = <int, double>{};
  for (final s in samples) {
    final from = s.from.toUtc().millisecondsSinceEpoch;
    final to = s.to.toUtc().millisecondsSinceEpoch;
    if (to <= from) {
      final b = bucketStartMs(s.from);
      out[b] = (out[b] ?? 0) + s.steps;
      continue;
    }
    final total = (to - from).toDouble();
    var b = from - (from % _bucketMs);
    while (b < to) {
      final overlap = (to < b + _bucketMs ? to : b + _bucketMs) - (from > b ? from : b);
      if (overlap > 0) out[b] = (out[b] ?? 0) + s.steps * overlap / total;
      b += _bucketMs;
    }
  }
  return out.map((k, v) => MapEntry(k, v.round()));
}

/// Merge per-bucket phone and health counts by taking the max of each bucket.
Map<int, int> mergeDedup(Map<int, int> phone, Map<int, int> health) {
  final keys = {...phone.keys, ...health.keys};
  return {
    for (final k in keys) k: _max(phone[k] ?? 0, health[k] ?? 0),
  };
}

int _max(int a, int b) => a > b ? a : b;

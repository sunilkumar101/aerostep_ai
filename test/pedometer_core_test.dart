import 'dart:math' as math;

import 'package:aerostep_ai/core/pedometer/accel_cadence.dart';
import 'package:aerostep_ai/core/pedometer/cadence_gate.dart';
import 'package:aerostep_ai/core/pedometer/health_dedup.dart';
import 'package:aerostep_ai/core/pedometer/streak.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feeds [count] single-step events spaced for [spm] into [gate]; returns committed total.
int walk(CadenceGate gate, DateTime start, {required double spm, required int count}) {
  final gapMs = (60000 / spm).round();
  var committed = 0;
  for (var i = 0; i < count; i++) {
    committed += gate.addSteps(1, start.add(Duration(milliseconds: gapMs * i))).committed;
  }
  return committed;
}

void main() {
  final t0 = DateTime.utc(2026, 11, 17, 8);

  group('Anti-shake cadence gate', () {
    test('real 50-step walk at 110 SPM is fully counted once validated', () {
      final gate = CadenceGate();
      final committed = walk(gate, t0, spm: 110, count: 50);
      expect(committed, 50);
      expect(gate.isWalking, isTrue);
      expect(gate.cadenceSpm, closeTo(110, 3));
    });

    test('short burst under 6 s (picking phone up) is never committed', () {
      final gate = CadenceGate();
      final committed = walk(gate, t0, spm: 120, count: 8); // ~3.5 s
      expect(committed, 0);
      final d = gate.tick(t0.add(const Duration(seconds: 10)));
      expect(d.rejected, 8);
      expect(gate.pendingSteps, 0);
    });

    test('15 s rapid hand shake (~360 SPM) is rejected', () {
      final gate = CadenceGate();
      final committed = walk(gate, t0, spm: 360, count: 90);
      expect(committed, 0);
    });

    test('shake detected by accelerometer veto even at plausible step rate', () {
      final gate = CadenceGate()..updateAccelCadence(400);
      expect(walk(gate, t0, spm: 120, count: 30), 0);
    });

    test('vehicle context drops pending and blocks steps', () {
      final gate = CadenceGate();
      walk(gate, t0, spm: 100, count: 5);
      final d = gate.updateContext(MotionContext.vehicle);
      expect(d.rejected, 5);
      expect(walk(gate, t0.add(const Duration(seconds: 5)), spm: 100, count: 40), 0);
      gate.updateContext(MotionContext.walking);
      expect(walk(gate, t0.add(const Duration(minutes: 2)), spm: 100, count: 40), 40);
    });

    test('too-slow bumps (30 SPM) never validate', () {
      final gate = CadenceGate(maxGap: const Duration(seconds: 5));
      expect(walk(gate, t0, spm: 30, count: 20), 0);
    });

    test('walking bout ends after a long pause and must re-validate', () {
      final gate = CadenceGate();
      expect(walk(gate, t0, spm: 110, count: 30), 30);
      final later = t0.add(const Duration(minutes: 1));
      expect(gate.addSteps(1, later).committed, 0);
      expect(gate.isWalking, isFalse);
    });

    test('hardware batch deltas (several steps per event) are handled', () {
      final gate = CadenceGate();
      var committed = 0;
      for (var i = 0; i < 10; i++) {
        committed += gate.addSteps(4, t0.add(Duration(seconds: 2 * i))).committed; // 120 SPM
      }
      expect(committed, 40);
    });
  });

  group('Accelerometer cadence estimator', () {
    double? run(double hz, {double amp = 3}) {
      final e = AccelCadenceEstimator();
      for (var i = 0; i < 300; i++) {
        final t = i / 100; // 100 Hz for 3 s
        e.add(t0.add(Duration(milliseconds: i * 10)), 0, 0, 9.81 + amp * math.sin(2 * math.pi * hz * t));
      }
      return e.cadence;
    }

    test('walking (~1.9 Hz) reads ~114 cycles/min', () => expect(run(1.9), closeTo(114, 25)));
    test('shaking (~6 Hz) reads > 260 cycles/min', () => expect(run(6)!, greaterThan(260)));
    test('still device reads 0', () => expect(run(2, amp: 0.05), 0));
  });

  group('15-minute UTC health deduplication', () {
    test('bucket start is aligned to 15 min UTC', () {
      final b = bucketStart(DateTime.utc(2026, 11, 17, 8, 22, 41));
      expect(b, DateTime.utc(2026, 11, 17, 8, 15));
    });

    test('watch + phone steps for the same walk are not double-counted', () {
      final phone = bucketize([StepSample(t0, t0.add(const Duration(minutes: 15)), 1500)]);
      final watch = bucketize([StepSample(t0, t0.add(const Duration(minutes: 15)), 1620)]);
      final merged = mergeDedup(phone, watch);
      expect(merged.values.fold<int>(0, (a, b) => a + b), 1620);
    });

    test('steps only one source saw are still credited', () {
      final phone = {bucketStartMs(t0): 900};
      final watch = {bucketStartMs(t0.add(const Duration(hours: 1))): 700};
      final merged = mergeDedup(phone, watch);
      expect(merged.values.fold<int>(0, (a, b) => a + b), 1600);
    });

    test('a sample spanning two buckets is split proportionally', () {
      final m = bucketize([StepSample(t0.add(const Duration(minutes: 10)), t0.add(const Duration(minutes: 20)), 1000)]);
      expect(m[bucketStartMs(t0)], 500);
      expect(m[bucketStartMs(t0.add(const Duration(minutes: 15)))], 500);
    });
  });

  group('UTC ledger & Streak Shield', () {
    test('local day uses the offset recorded at the time (travel-proof)', () {
      // 23:30 in Karachi (+5) is 18:30 UTC same day.
      final karachi = LedgerEntry(utc: DateTime.utc(2026, 11, 16, 18, 30), offsetMinutes: 300, steps: 100);
      // 01:00 next day UTC, recorded while in New York (-5) => 20:00 on the 16th.
      final ny = LedgerEntry(utc: DateTime.utc(2026, 11, 17, 1), offsetMinutes: -300, steps: 50);
      expect(karachi.localDay, '2026-11-16');
      expect(ny.localDay, '2026-11-16');
      expect(dailyTotals([karachi, ny]), {'2026-11-16': 150});
    });

    test('consecutive goal days build a streak; today in progress does not break it', () {
      final r = computeStreak(
        totals: {'2026-11-14': 10000, '2026-11-15': 12000, '2026-11-16': 10500, '2026-11-17': 2000},
        goal: 10000,
        today: '2026-11-17',
      );
      expect(r.days, 3);
      expect(r.shieldsUsed, 0);
    });

    test('a rest day auto-deploys a Streak Shield', () {
      final r = computeStreak(
        totals: {'2026-11-13': 11000, '2026-11-14': 10000, '2026-11-15': 3000, '2026-11-16': 10500},
        goal: 10000,
        today: '2026-11-17',
        shieldsAvailable: 2,
      );
      expect(r.days, 4);
      expect(r.shieldsUsed, 1);
      expect(r.shieldedDays, contains('2026-11-15'));
    });

    test('already-shielded days are not charged twice', () {
      final r = computeStreak(
        totals: {'2026-11-14': 10000, '2026-11-15': 3000, '2026-11-16': 10500},
        goal: 10000,
        today: '2026-11-17',
        shieldsAvailable: 0,
        alreadyShielded: {'2026-11-15'},
      );
      expect(r.days, 3);
      expect(r.shieldsUsed, 0);
    });

    test('streak breaks with no shields', () {
      final r = computeStreak(
        totals: {'2026-11-14': 10000, '2026-11-15': 3000, '2026-11-16': 10500},
        goal: 10000,
        today: '2026-11-17',
      );
      expect(r.days, 1);
    });
  });
}

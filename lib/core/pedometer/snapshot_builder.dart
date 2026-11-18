import '../data/aero_database.dart';
import '../state/activity_state.dart';
import 'streak.dart';

/// Builds the UI [ActivitySnapshot] from the deduplicated UTC ledger.
class SnapshotBuilder {
  SnapshotBuilder(this.db);
  final AeroDatabase db;

  Future<ActivitySnapshot> build({
    required int goal,
    required double strideM,
    required double weightKg,
    required int cadenceSpm,
    required bool vehicle,
    required int shieldsAvailable,
    void Function(int shieldsUsed)? onShieldsUsed,
    String? resetDay,
    int resetBase = 0,
  }) async {
    final now = DateTime.now();
    final today = dayKey(now);
    final entries = await db.entriesSince(now.toUtc().subtract(const Duration(days: 400)));
    final totals = dailyTotals(entries);

    final hourly = List<int>.filled(24, 0);
    for (final e in entries) {
      if (e.localDay != today) continue;
      final local = e.utc.add(Duration(minutes: e.offsetMinutes));
      hourly[local.hour] += e.steps;
    }
    var steps = totals[today] ?? 0;
    if (resetDay == today && resetBase > 0) {
      // "Start today from zero": hide the steps counted before the reset.
      steps = applyTodayReset(steps, resetBase, hourly);
      totals[today] = steps;
    }

    // Monday..Sunday of the current local week.
    final monday = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekly = [for (var i = 0; i < 7; i++) totals[dayKey(monday.add(Duration(days: i)))] ?? 0];

    final alreadyShielded = await db.loadShieldedDays();
    final streak = computeStreak(
      totals: totals,
      goal: goal,
      today: today,
      shieldsAvailable: shieldsAvailable,
      alreadyShielded: alreadyShielded,
    );
    if (streak.shieldsUsed > 0) {
      await db.markShielded(streak.shieldedDays.difference(alreadyShielded));
      onShieldsUsed?.call(streak.shieldsUsed);
    }

    // Active time: ~100 steps per brisk minute is a robust approximation
    // without storing per-minute data.
    final activeMinutes = (steps / 100).round();
    final kcal = (steps * 0.04 * (weightKg / 70)).round();

    return ActivitySnapshot(
      steps: steps,
      goal: goal,
      distanceKm: steps * strideM / 1000,
      activeMinutes: activeMinutes,
      kcal: kcal,
      cadenceSpm: cadenceSpm,
      streakDays: streak.days,
      hourlySteps: hourly,
      weeklySteps: weekly,
      isVehicleDetected: vehicle,
    );
  }
}

/// Today's raw (un-reset) ledger total, used as the base when the user resets.
Future<int> rawTodaySteps(AeroDatabase db) async {
  final now = DateTime.now();
  final entries = await db.entriesSince(now.toUtc().subtract(const Duration(days: 2)));
  return dailyTotals(entries)[dayKey(now)] ?? 0;
}

/// Removes [base] steps from today's total and from the earliest hours of
/// [hourly] (in place), so the day chart matches the reset count.
int applyTodayReset(int raw, int base, List<int> hourly) {
  var left = base;
  for (var h = 0; h < hourly.length && left > 0; h++) {
    final take = hourly[h] < left ? hourly[h] : left;
    hourly[h] -= take;
    left -= take;
  }
  return raw > base ? raw - base : 0;
}

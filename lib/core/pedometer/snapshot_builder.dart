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
    final steps = totals[today] ?? 0;

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

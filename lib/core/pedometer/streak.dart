/// Timezone-proof daily totals and Streak Shield logic.
///
/// Every ledger row is stored with its UTC instant AND the device's UTC offset
/// at the moment it was recorded. A row's "day" is the local calendar date the
/// user experienced (utc + offset), so flying across timezones never moves a
/// walk to a different day or breaks a streak.
library;

class LedgerEntry {
  const LedgerEntry({required this.utc, required this.offsetMinutes, required this.steps});
  final DateTime utc;
  final int offsetMinutes;
  final int steps;

  /// Local calendar day as yyyy-mm-dd, using the offset captured at record time.
  String get localDay => dayKey(utc.toUtc().add(Duration(minutes: offsetMinutes)));
}

String dayKey(DateTime wallClock) =>
    '${wallClock.year.toString().padLeft(4, '0')}-${wallClock.month.toString().padLeft(2, '0')}-${wallClock.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

Map<String, int> dailyTotals(Iterable<LedgerEntry> entries) {
  final out = <String, int>{};
  for (final e in entries) {
    out[e.localDay] = (out[e.localDay] ?? 0) + e.steps;
  }
  return out;
}

class StreakResult {
  const StreakResult({required this.days, required this.shieldsUsed, required this.shieldedDays});

  /// Consecutive qualifying days ending today (or yesterday if today is still open).
  final int days;

  /// Shields newly consumed by this evaluation.
  final int shieldsUsed;

  /// All days covered by a shield (previously or newly).
  final Set<String> shieldedDays;
}

/// Walks back from [today] counting days that met [goal]. A missed *completed*
/// day is covered automatically by a Streak Shield if one is available (or was
/// already applied, per [alreadyShielded]); otherwise the streak ends. Today
/// never breaks the streak because it is still in progress.
StreakResult computeStreak({
  required Map<String, int> totals,
  required int goal,
  required String today,
  int shieldsAvailable = 0,
  Set<String> alreadyShielded = const {},
  int maxLookbackDays = 3650,
}) {
  var day = parseDayKey(today);
  var streak = 0;
  var used = 0;
  final shielded = {...alreadyShielded};

  // Today counts if already achieved, but is never a miss.
  if ((totals[today] ?? 0) >= goal) streak++;
  day = day.subtract(const Duration(days: 1));

  // Only consider history after the user's first recorded day.
  final first = totals.keys.isEmpty ? today : (totals.keys.toList()..sort()).first;

  for (var i = 0; i < maxLookbackDays; i++) {
    final k = dayKey(day);
    if (k.compareTo(first) < 0) break;
    if ((totals[k] ?? 0) >= goal) {
      streak++;
    } else if (shielded.contains(k)) {
      streak++;
    } else if (used < shieldsAvailable) {
      used++;
      shielded.add(k);
      streak++;
    } else {
      break;
    }
    day = day.subtract(const Duration(days: 1));
  }
  return StreakResult(days: streak, shieldsUsed: used, shieldedDays: shielded);
}

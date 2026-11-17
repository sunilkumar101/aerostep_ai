import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import 'app_settings.dart';

/// Today's live activity numbers shown across Home / Tracker / Widgets.
/// Fed by the pedometer engine (lib/core/pedometer) — UI only reads it.
class ActivitySnapshot {
  const ActivitySnapshot({
    required this.steps,
    required this.goal,
    required this.distanceKm,
    required this.activeMinutes,
    required this.kcal,
    required this.cadenceSpm,
    required this.streakDays,
    required this.hourlySteps,
    required this.weeklySteps,
    required this.isVehicleDetected,
  });

  final int steps;
  final int goal;
  final double distanceKm;
  final int activeMinutes;
  final int kcal;
  final int cadenceSpm;
  final int streakDays;

  /// 24 buckets of local-hour step totals for today.
  final List<int> hourlySteps;

  /// Last 7 days (Mon..Sun of the current week) step totals.
  final List<int> weeklySteps;
  final bool isVehicleDetected;

  double get progress => goal == 0 ? 0 : (steps / goal).clamp(0, 1).toDouble();
  int get percent => (progress * 100).round();
  int get remaining => (goal - steps).clamp(0, goal);
  int get weeklyTotal => weeklySteps.fold(0, (a, b) => a + b);

  ActivitySnapshot copyWith({
    int? steps,
    int? goal,
    double? distanceKm,
    int? activeMinutes,
    int? kcal,
    int? cadenceSpm,
    int? streakDays,
    List<int>? hourlySteps,
    List<int>? weeklySteps,
    bool? isVehicleDetected,
  }) =>
      ActivitySnapshot(
        steps: steps ?? this.steps,
        goal: goal ?? this.goal,
        distanceKm: distanceKm ?? this.distanceKm,
        activeMinutes: activeMinutes ?? this.activeMinutes,
        kcal: kcal ?? this.kcal,
        cadenceSpm: cadenceSpm ?? this.cadenceSpm,
        streakDays: streakDays ?? this.streakDays,
        hourlySteps: hourlySteps ?? this.hourlySteps,
        weeklySteps: weeklySteps ?? this.weeklySteps,
        isVehicleDetected: isVehicleDetected ?? this.isVehicleDetected,
      );

  /// Values from the Stitch mockups (demo / screenshot mode).
  static ActivitySnapshot demo(int goal) => ActivitySnapshot(
        steps: 8420,
        goal: goal,
        distanceKm: 6.1,
        activeMinutes: 52,
        kcal: 380,
        cadenceSpm: 114,
        streakDays: 12,
        hourlySteps: const [0, 0, 0, 0, 0, 0, 420, 980, 1240, 610, 380, 520, 860, 450, 300, 410, 690, 820, 560, 120, 0, 0, 0, 0],
        weeklySteps: const [9120, 8640, 10450, 7980, 9870, 9800, 8420],
        isVehicleDetected: false,
      );

  static ActivitySnapshot empty(int goal) => ActivitySnapshot(
        steps: 0,
        goal: goal,
        distanceKm: 0,
        activeMinutes: 0,
        kcal: 0,
        cadenceSpm: 0,
        streakDays: 0,
        hourlySteps: List.filled(24, 0),
        weeklySteps: List.filled(7, 0),
        isVehicleDetected: false,
      );
}

class ActivityNotifier extends Notifier<ActivitySnapshot> {
  @override
  ActivitySnapshot build() {
    final goal = ref.watch(userProfileProvider.select((p) => p.stepGoal));
    final prev = stateOrNull;
    if (prev != null) return prev.copyWith(goal: goal);
    return kAeroDemoMode ? ActivitySnapshot.demo(goal) : ActivitySnapshot.empty(goal);
  }

  /// Called by the pedometer engine whenever the ledger changes.
  void publish(ActivitySnapshot snapshot) {
    if (kAeroDemoMode) return;
    state = snapshot.copyWith(goal: state.goal);
  }
}

final activityProvider = NotifierProvider<ActivityNotifier, ActivitySnapshot>(ActivityNotifier.new);

/// Hydration log for today (ml). Goal 2.5 L.
class HydrationState {
  const HydrationState(this.ml, this.goalMl);
  final int ml;
  final int goalMl;
  double get progress => (ml / goalMl).clamp(0, 1).toDouble();
  String get litres => (ml / 1000).toStringAsFixed(2);
}

class HydrationNotifier extends Notifier<HydrationState> {
  static const _key = 'hydration_ml';
  static const _dayKey = 'hydration_day';

  @override
  HydrationState build() {
    final p = ref.watch(sharedPrefsProvider);
    final today = _todayKey();
    if (p.getString(_dayKey) != today) {
      p.setString(_dayKey, today);
      p.setInt(_key, kAeroDemoMode ? 1750 : 0);
    }
    return HydrationState(p.getInt(_key) ?? 0, 2500);
  }

  void add(int ml) {
    state = HydrationState(state.ml + ml, state.goalMl);
    ref.read(sharedPrefsProvider)
      ..setString(_dayKey, _todayKey())
      ..setInt(_key, state.ml);
    // UTC ledger copy (timezone-proof history).
    ref.read(databaseProvider).logHydration(ml).ignore();
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}

final hydrationProvider = NotifierProvider<HydrationNotifier, HydrationState>(HydrationNotifier.new);

/// Streak Shields owned (rest-day guards). Earned via level-ups or a voluntary rewarded ad.
class StreakShieldNotifier extends Notifier<int> {
  static const _key = 'streak_shields';

  @override
  int build() => ref.watch(sharedPrefsProvider).getInt(_key) ?? 2;

  void add([int n = 1]) => _set(state + n);

  bool consume() {
    if (state <= 0) return false;
    _set(state - 1);
    return true;
  }

  void _set(int v) {
    state = v;
    ref.read(sharedPrefsProvider).setInt(_key, v);
  }
}

final streakShieldProvider = NotifierProvider<StreakShieldNotifier, int>(StreakShieldNotifier.new);

/// Active 24h Trail Pass expiry (UTC), unlocked via a rewarded ad.
class TrailPassNotifier extends Notifier<DateTime?> {
  static const _key = 'trail_pass_expiry_utc';

  @override
  DateTime? build() {
    final ms = ref.watch(sharedPrefsProvider).getInt(_key);
    if (ms == null) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return t.isAfter(DateTime.now().toUtc()) ? t : null;
  }

  void grant24h() {
    final t = DateTime.now().toUtc().add(const Duration(hours: 24));
    state = t;
    ref.read(sharedPrefsProvider).setInt(_key, t.millisecondsSinceEpoch);
  }
}

final trailPassProvider = NotifierProvider<TrailPassNotifier, DateTime?>(TrailPassNotifier.new);

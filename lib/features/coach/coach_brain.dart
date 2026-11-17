import 'package:intl/intl.dart';

import '../../core/state/activity_state.dart';

/// Offline, rule-based AI Coach reply generator.
///
/// No network: every answer is assembled from today's live activity snapshot
/// and hydration log so the coach works in airplane mode.
final NumberFormat _group = NumberFormat('#,##0');

/// `8420` -> `8,420`.
String groupDigits(num n) => _group.format(n);

/// `10000` -> `10k`, `12500` -> `12.5k`.
String compactGoal(int goal) {
  if (goal < 1000) return '$goal';
  final k = goal / 1000;
  return k == k.roundToDouble() ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
}

/// Brisk walking cadence used for time estimates when no live cadence exists.
const int kBriskCadenceSpm = 110;

/// Approximate kcal burned per walking step (70 kg walker).
const double kKcalPerStep = 0.06;

/// Minutes needed to walk [steps] at [cadenceSpm] (falls back to brisk pace).
int minutesForSteps(int steps, int cadenceSpm) {
  final spm = cadenceSpm >= 60 ? cadenceSpm : kBriskCadenceSpm;
  return (steps / spm).ceil();
}

/// Rough kcal for [steps] for a walker of [weightKg].
int kcalForSteps(int steps, {double weightKg = 70}) => (steps * kKcalPerStep * weightKg / 70).round();

/// True when any [keys] matches: phrases (with a space) by substring,
/// single keys as a word prefix (`hydrat` matches `hydration`).
bool _has(String q, List<String> keys) {
  final words = q.split(RegExp(r'[^a-z0-9]+'));
  return keys.any((k) => k.contains(' ') ? q.contains(k) : words.any((w) => w.startsWith(k)));
}

/// Returns a helpful coach answer for [question].
///
/// [shields] is the number of Streak Shields (rest-day guards) the user owns;
/// [weightKg] personalises calorie estimates.
String coachReply(
  String question,
  ActivitySnapshot a,
  HydrationState h, {
  int shields = 0,
  double weightKg = 70,
}) {
  final q = question.toLowerCase().trim();
  if (q.isEmpty) return 'Ask me about steps left, hydration, cadence, calories or rest days.';

  final goalLabel = compactGoal(a.goal);
  final waterLeft = (h.goalMl - h.ml).clamp(0, h.goalMl);
  final glasses = (waterLeft / 250).ceil();

  String stepsAnswer() {
    if (a.remaining == 0) {
      return 'Goal crushed! You have ${groupDigits(a.steps)} steps today, past your $goalLabel target. '
          'An easy 10-minute cool-down walk keeps the streak glowing without extra strain.';
    }
    final mins = minutesForSteps(a.remaining, a.cadenceSpm);
    final kcal = kcalForSteps(a.remaining, weightKg: weightKg);
    return 'You are ${groupDigits(a.remaining)} steps away from your $goalLabel goal '
        '(${a.percent}% done). A $mins-minute brisk walk closes the gap and burns about $kcal kcal.';
  }

  String waterAnswer() {
    if (waterLeft == 0) {
      return 'Hydration goal reached: ${h.litres} L logged. Keep sipping to thirst, '
          'especially after your evening walk.';
    }
    return 'You have logged ${h.litres} of ${(h.goalMl / 1000).toStringAsFixed(1)} L. '
        '$glasses more ${glasses == 1 ? 'glass' : 'glasses'} of 250 ml finishes today. '
        'Drink one now and one with your next walk - steady hydration helps fat oxidation.';
  }

  String cadenceAnswer() {
    final spm = a.cadenceSpm;
    if (spm == 0) {
      return 'No cadence recorded yet today. Aim for 100-120 steps per minute on your next walk; '
          'try the Interval Cadence Drill in Gait & Audio Drills to lock in the rhythm.';
    }
    final zone = spm >= 130
        ? 'power-walk zone'
        : spm >= 110
            ? 'fat-burn zone'
            : spm >= 100
                ? 'brisk zone'
                : 'easy stroll zone';
    final tip = spm < 110
        ? 'Shorten your stride slightly and quicken your steps to reach 110+ SPM.'
        : 'Great rhythm - keep shoulders relaxed and land under your hips.';
    return 'Your cadence is $spm SPM, the $zone. $tip';
  }

  String restAnswer() {
    final s = shields == 1 ? '1 Streak Shield' : '$shields Streak Shields';
    if (shields == 0) {
      return 'You have no Streak Shields right now. Rest days are part of training - '
          'grab a free shield in the Unlock Pass so a recovery day will not break your '
          '${a.streakDays}-day streak.';
    }
    return 'You have $s ready. If you rest or feel unwell, a shield auto-deploys when you stay '
        'under 5k steps, protecting your ${a.streakDays}-day streak. Gentle mobility or a '
        '10-minute stroll still helps recovery.';
  }

  String calorieAnswer() {
    final remainingKcal = kcalForSteps(a.remaining, weightKg: weightKg);
    final base = 'You have burned ${groupDigits(a.kcal)} active kcal today';
    if (a.remaining == 0) return '$base and hit your step goal. Pair it with a protein-rich dinner to stay in a healthy deficit.';
    return '$base. Finishing your ${groupDigits(a.remaining)} remaining steps adds about $remainingKcal kcal. '
        'A sustainable deficit is 300-500 kcal a day - walk after meals and keep hydrated.';
  }

  String gaitAnswer() =>
      'Your last gait scan shows 72% forefoot / 28% heel loading with +4.2 deg/s pronation - '
      'within neutral range. Shift your stride angle about 3 degrees rearward and keep cadence near '
      '164 SPM on runs to ease knee shear.';

  final words = q.split(RegExp(r'[^a-z0-9]+')).toSet();
  if (words.intersection(const {'hello', 'hi', 'hey', 'hiya', 'yo'}).isNotEmpty && words.length <= 4) {
    return 'Hi! You are at ${groupDigits(a.steps)} steps (${a.percent}%). '
        'Ask me about steps left, water, cadence, calories or rest days.';
  }
  if (_has(q, ['water', 'hydrat', 'drink', 'thirst', 'electrolyte'])) return waterAnswer();
  if (_has(q, ['rest', 'shield', 'tired', 'sore', 'sick', 'illness', 'unwell', 'recover', 'day off', 'injur'])) {
    return restAnswer();
  }
  if (_has(q, ['stride', 'gait', 'pronat', 'forefoot', 'heel', 'knee', 'posture', 'angle'])) return gaitAnswer();
  if (_has(q, ['calor', 'kcal', 'burn', 'fat', 'weight', 'lose', 'deficit', 'diet', 'meal', 'eat'])) {
    return calorieAnswer();
  }
  if (_has(q, ['cadence', 'spm', 'pace', 'rhythm', 'tempo', 'bpm', 'fast', 'speed'])) return cadenceAnswer();
  if (_has(q, ['streak'])) {
    return 'Your streak is ${a.streakDays} days. ${restAnswer()}';
  }
  if (_has(q, ['distance', 'km', 'mile', 'far'])) {
    return 'You have covered ${a.distanceKm.toStringAsFixed(1)} km in ${a.activeMinutes} active minutes today. ${stepsAnswer()}';
  }
  if (_has(q, ['step', 'goal', 'left', 'remain', 'how many', 'how much more', 'progress', 'walk'])) {
    return stepsAnswer();
  }

  return '${stepsAnswer()} Hydration: ${h.litres} / ${(h.goalMl / 1000).toStringAsFixed(1)} L. '
      'Ask me about cadence, calories, stride or rest days for more.';
}

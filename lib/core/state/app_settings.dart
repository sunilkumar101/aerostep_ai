import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

/// Compile with `--dart-define=AERO_DEMO=true` to seed Stitch mockup values
/// (used for store screenshots). Default builds show the user's real data.
const bool kAeroDemoMode = bool.fromEnvironment('AERO_DEMO');

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final v = ref.watch(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.light);
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }

  /// Flip between Warm Peach light and Warm Espresso dark.
  void toggle(Brightness current) => set(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class UserProfile {
  const UserProfile({
    required this.name,
    required this.stepGoal,
    required this.onboarded,
    required this.autoPauseVehicles,
    required this.strideLengthM,
    required this.weightKg,
  });

  final String name;
  final int stepGoal;
  final bool onboarded;
  final bool autoPauseVehicles;
  final double strideLengthM;
  final double weightKg;

  UserProfile copyWith({
    String? name,
    int? stepGoal,
    bool? onboarded,
    bool? autoPauseVehicles,
    double? strideLengthM,
    double? weightKg,
  }) =>
      UserProfile(
        name: name ?? this.name,
        stepGoal: stepGoal ?? this.stepGoal,
        onboarded: onboarded ?? this.onboarded,
        autoPauseVehicles: autoPauseVehicles ?? this.autoPauseVehicles,
        strideLengthM: strideLengthM ?? this.strideLengthM,
        weightKg: weightKg ?? this.weightKg,
      );
}

class UserProfileNotifier extends Notifier<UserProfile> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  UserProfile build() {
    final p = ref.watch(sharedPrefsProvider);
    return UserProfile(
      name: p.getString('profile_name') ?? '',
      stepGoal: p.getInt('step_goal') ?? 10000,
      onboarded: p.getBool('onboarded') ?? false,
      autoPauseVehicles: p.getBool('auto_pause_vehicles') ?? true,
      strideLengthM: p.getDouble('stride_m') ?? 0.72,
      weightKg: p.getDouble('weight_kg') ?? 70,
    );
  }

  void setStepGoal(int goal) {
    state = state.copyWith(stepGoal: goal);
    _p.setInt('step_goal', goal);
  }

  void setAutoPause(bool v) {
    state = state.copyWith(autoPauseVehicles: v);
    _p.setBool('auto_pause_vehicles', v);
  }

  void setName(String v) {
    final name = v.trim();
    state = state.copyWith(name: name);
    _p.setString('profile_name', name);
  }

  void completeOnboarding() {
    state = state.copyWith(onboarded: true);
    _p.setBool('onboarded', true);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

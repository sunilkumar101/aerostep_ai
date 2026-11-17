import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state/app_settings.dart';
import '../design_system/design_system.dart';

/// Which main dock tab is active (0 Home, 1 Analysis, 2 Trails, 3 Squads).
class _IntNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final dockIndexProvider = NotifierProvider<_IntNotifier, int>(_IntNotifier.new);

/// Home tab sub-view: 0 = Home Dashboard, 1 = Daily Activity Tracker.
final homeSubViewProvider = NotifierProvider<_IntNotifier, int>(_IntNotifier.new);

/// Analysis tab sub-view: 0 = Analysis & Active Calories, 1 = Trends & Analytics.
final analysisSubViewProvider = NotifierProvider<_IntNotifier, int>(_IntNotifier.new);

/// Compact segmented switcher placed under a screen header to flip between the
/// two views that share a dock tab.
class SubViewSwitcher extends ConsumerWidget {
  const SubViewSwitcher.home({super.key})
      : _analysis = false,
        _labels = const ['Today', 'Tracker'];
  const SubViewSwitcher.analysis({super.key})
      : _analysis = true,
        _labels = const ['Calories', 'Trends'];

  final bool _analysis;
  final List<String> _labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = _analysis ? analysisSubViewProvider : homeSubViewProvider;
    final idx = ref.watch(provider);
    return AeroSegmented<int>(
      options: const [0, 1],
      selected: idx,
      labelOf: (i) => _labels[i],
      onChanged: (i) => ref.read(provider.notifier).set(i),
      activeTangerine: true,
      height: 40,
    );
  }
}

/// Light (Warm Peach) / Dark (Warm Espresso) header toggle.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    return AeroCircleButton(
      tooltip: b == Brightness.dark ? 'Switch to light mode' : 'Switch to espresso dark mode',
      icon: b == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(b),
    );
  }
}

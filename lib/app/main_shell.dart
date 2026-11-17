import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/pedometer/pedometer_controller.dart';
import '../design_system/design_system.dart';
import '../features/analysis/analysis_calories_view.dart';
import '../features/analysis/trends_analytics_view.dart';
import '../features/home/activity_tracker_view.dart';
import '../features/home/home_dashboard_view.dart';
import '../features/squads/squads_view.dart';
import '../features/trails/virtual_trails_view.dart';
import 'routes.dart';
import 'shell_state.dart';

/// Main tabbed shell with the unified [AeroFloatingBottomDock].
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Start the zero-GPS step engine once the user reaches the main app.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(pedometerControllerProvider).start());
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(dockIndexProvider);
    final homeSub = ref.watch(homeSubViewProvider);
    final analysisSub = ref.watch(analysisSubViewProvider);

    final tabs = <Widget>[
      _Fade(index: homeSub, children: const [HomeDashboardView(), ActivityTrackerView()]),
      _Fade(index: analysisSub, children: const [AnalysisCaloriesView(), TrendsAnalyticsView()]),
      const VirtualTrailsView(),
      const SquadsView(),
    ];

    return Scaffold(
      extendBody: true,
      body: AeroCanvas(
        child: Stack(
          children: [
            Positioned.fill(child: IndexedStack(index: index, children: tabs)),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Center(
                child: AeroFloatingBottomDock(
                  index: index,
                  onTap: (i) {
                    // Re-tapping an active dual-view tab flips its sub-view.
                    if (i == index && i == 0) {
                      ref.read(homeSubViewProvider.notifier).set(1 - homeSub);
                    } else if (i == index && i == 1) {
                      ref.read(analysisSubViewProvider.notifier).set(1 - analysisSub);
                    }
                    ref.read(dockIndexProvider.notifier).set(i);
                  },
                  onAiTap: () => context.push(AeroRoutes.coach),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(key: ValueKey(index), child: children[index]),
      );
}

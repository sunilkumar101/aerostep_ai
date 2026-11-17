import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/state/app_settings.dart';
import '../features/coach/ai_coach_hub_screen.dart';
import '../features/live_walk/live_walk_screen.dart';
import '../features/onboarding/onboarding_welcome_screen.dart';
import '../features/onboarding/smart_setup_screen.dart';
import '../features/unlock/unlock_pass_screen.dart';
import '../features/widgets_showcase/widget_showcase_screen.dart';
import 'main_shell.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AeroRoutes.home,
    redirect: (context, state) {
      final onboarded = ref.read(userProfileProvider).onboarded;
      final loc = state.matchedLocation;
      final inOnboarding = loc == AeroRoutes.onboarding || loc == AeroRoutes.setup;
      if (!onboarded && !inOnboarding) return AeroRoutes.onboarding;
      return null;
    },
    routes: [
      GoRoute(path: AeroRoutes.onboarding, builder: (_, _) => const OnboardingWelcomeScreen()),
      GoRoute(path: AeroRoutes.setup, builder: (_, _) => const SmartSetupScreen()),
      GoRoute(path: AeroRoutes.home, builder: (_, _) => const MainShell()),
      GoRoute(path: AeroRoutes.coach, builder: (_, _) => const AiCoachHubScreen()),
      GoRoute(path: AeroRoutes.liveWalk, builder: (_, _) => const LiveWalkScreen()),
      GoRoute(path: AeroRoutes.widgets, builder: (_, _) => const WidgetShowcaseScreen()),
      GoRoute(
        path: AeroRoutes.unlock,
        pageBuilder: (_, _) => const MaterialPage(fullscreenDialog: true, child: UnlockPassScreen()),
      ),
    ],
  );
});

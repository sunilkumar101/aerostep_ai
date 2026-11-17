import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/ads/admob_reward_gateway.dart';
import 'core/state/activity_state.dart';
import 'core/state/app_settings.dart';
import 'core/widgets/home_widget_bridge.dart';
import 'design_system/design_system.dart';
import 'features/unlock/reward_ad_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  FlutterForegroundTask.initCommunicationPort();
  final prefs = await SharedPreferences.getInstance();
  unawaited(HomeWidgetBridge.init());
  // Preloads one rewarded ad silently; nothing is ever shown without a tap.
  unawaited(AdMobRewardGateway.instance.init());
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        rewardAdGatewayProvider.overrideWithValue(AdMobRewardGateway.instance),
      ],
      child: const AeroStepApp(),
    ),
  );
}

class AeroStepApp extends ConsumerWidget {
  const AeroStepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    // Keep the native home-screen widgets in sync with live numbers.
    void pushWidgets() =>
        HomeWidgetBridge.push(ref.read(activityProvider), ref.read(hydrationProvider).ml);
    ref.listen(activityProvider, (_, _) => pushWidgets());
    ref.listen(hydrationProvider, (_, _) => pushWidgets());
    return MaterialApp.router(
      title: 'AeroStep AI',
      debugShowCheckedModeBanner: false,
      theme: AeroTheme.light(),
      darkTheme: AeroTheme.dark(),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

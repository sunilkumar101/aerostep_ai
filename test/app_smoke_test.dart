// Run with: flutter test --dart-define=AERO_DEMO=true test/app_smoke_test.dart
import 'package:aerostep_ai/app/router.dart';
import 'package:aerostep_ai/app/routes.dart';
import 'package:aerostep_ai/app/shell_state.dart';
import 'package:aerostep_ai/core/state/app_settings.dart';
import 'package:aerostep_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<ProviderContainer> pumpApp(WidgetTester tester, {required bool onboarded, required String theme}) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarded': onboarded, 'theme_mode': theme});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AeroStepApp()));
    await tester.pump(const Duration(milliseconds: 500));
    return container;
  }

  /// Google Fonts can't load offline in tests; those errors are expected.
  void expectNoLayoutErrors(WidgetTester tester) {
    Object? e;
    while ((e = tester.takeException()) != null) {
      final s = e.toString();
      if (s.contains('google_fonts') || s.contains('GoogleFonts') || s.contains('allowRuntimeFetching')) continue;
      fail('Unexpected exception: $s');
    }
  }

  test('requires --dart-define=AERO_DEMO=true', () => expect(kAeroDemoMode, isTrue));

  for (final theme in ['light', 'dark']) {
    testWidgets('onboarding + setup render ($theme)', (tester) async {
      final c = await pumpApp(tester, onboarded: false, theme: theme);
      expect(find.textContaining('Get Started'), findsWidgets);
      expectNoLayoutErrors(tester);
      c.read(routerProvider).push(AeroRoutes.setup);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Complete Setup', findRichText: true), findsWidgets);
      expectNoLayoutErrors(tester);
    });

    testWidgets('all main tabs and sub-views render ($theme)', (tester) async {
      final c = await pumpApp(tester, onboarded: true, theme: theme);
      for (var tab = 0; tab < 4; tab++) {
        c.read(dockIndexProvider.notifier).set(tab);
        await tester.pump(const Duration(milliseconds: 400));
        expectNoLayoutErrors(tester);
        if (tab < 2) {
          (tab == 0 ? c.read(homeSubViewProvider.notifier) : c.read(analysisSubViewProvider.notifier)).set(1);
          await tester.pump(const Duration(milliseconds: 400));
          expectNoLayoutErrors(tester);
        }
        // Scroll the page to lay out everything below the fold.
        final scrollable = find.byType(Scrollable).hitTestable();
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -3000));
          await tester.pump(const Duration(milliseconds: 400));
          expectNoLayoutErrors(tester);
        }
      }
    });

    for (final route in [AeroRoutes.coach, AeroRoutes.liveWalk, AeroRoutes.widgets, AeroRoutes.unlock]) {
      testWidgets('$route renders ($theme)', (tester) async {
        final c = await pumpApp(tester, onboarded: true, theme: theme);
        c.read(routerProvider).push(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expectNoLayoutErrors(tester);
        final scrollable = find.byType(Scrollable).hitTestable();
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -3000));
          await tester.pump(const Duration(milliseconds: 400));
          expectNoLayoutErrors(tester);
        }
      });
    }
  }
}

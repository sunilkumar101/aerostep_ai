// Renders Play Store graphics from the real app UI.
//
//   flutter test --dart-define=AERO_DEMO=true tool/store_assets_render_test.dart
//
// Output: store_assets/play/ (icon 512, feature graphic 1024x500, 8 phone
// screenshots 1080x1920) + store_assets/launcher/ (1024 icon sources).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aerostep_ai/app/main_shell.dart';
import 'package:aerostep_ai/app/shell_state.dart';
import 'package:aerostep_ai/core/state/app_settings.dart';
import 'package:aerostep_ai/design_system/design_system.dart';
import 'package:aerostep_ai/features/coach/ai_coach_hub_screen.dart';
import 'package:aerostep_ai/features/live_walk/live_walk_screen.dart';
import 'package:aerostep_ai/features/widgets_showcase/widget_showcase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _outPlay = 'store_assets/play';
const _outLauncher = 'store_assets/launcher';

Future<void> _loadFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'C:\flutter';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  final loader = FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then((b) => ByteData.sublistView(b)));
  await loader.load();
  // Pre-load every bundled weight so text never falls back mid-frame.
  for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800]) {
    GoogleFonts.plusJakartaSans(fontWeight: w);
    if (w != FontWeight.w800) GoogleFonts.spaceGrotesk(fontWeight: w);
  }
  await GoogleFonts.pendingFonts();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path, {required double pixelRatio}) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File(path)..createSync(recursive: true);
    f.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _setSize(WidgetTester tester, Size logical, double dpr) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);
}

/// Runs async work (fonts, prefs) and settles animations for a fixed time.
Future<void> _settle(WidgetTester tester, [int ms = 1500]) async {
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// ─────────────────────────────── Brand art ───────────────────────────────

/// Charcoal tile + glowing tangerine stride ring + walking figure.
class _AppIcon extends StatelessWidget {
  const _AppIcon({this.background = true});
  final bool background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = c.biggest.shortestSide;
      return SizedBox.square(
        dimension: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (background)
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.15),
                    radius: 0.85,
                    colors: [Color(0xFF2A1A12), AeroColors.charcoal],
                  ),
                ),
              ),
            // Soft glow behind the ring.
            Container(
              width: s * 0.66,
              height: s * 0.66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AeroColors.tangerine.withValues(alpha: 0.45), blurRadius: s * 0.12)],
              ),
            ),
            CustomPaint(size: Size.square(s * 0.66), painter: _StrideRingPainter(s * 0.075)),
            Icon(Icons.directions_walk_rounded, size: s * 0.36, color: Colors.white),
          ],
        ),
      );
    });
  }
}

class _StrideRingPainter extends CustomPainter {
  _StrideRingPainter(this.stroke);
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Colors.white.withValues(alpha: 0.10));
    const sweep = math.pi * 2 * 0.84;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AeroColors.tangerine, AeroColors.tangerineLight, AeroColors.peachFixedDim, AeroColors.tangerine],
          stops: [0, 0.45, 0.8, 1],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(Offset.zero & size),
    );
    // Sky-cyan "live" dot at the arc's end.
    final end = rect.center +
        Offset(math.cos(-math.pi / 2 + sweep), math.sin(-math.pi / 2 + sweep)) * (rect.width / 2);
    canvas.drawCircle(end, stroke * 0.62, Paint()..color = AeroColors.skyCyan);
    canvas.drawCircle(end, stroke * 0.62, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.22
      ..color = AeroColors.charcoal);
  }

  @override
  bool shouldRepaint(_StrideRingPainter old) => false;
}

/// 1024x500 feature graphic (logical 1024x500 @1x).
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    return AeroCanvas(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 48, 48, 48),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    const SizedBox(width: 44, height: 44, child: ClipRRect(borderRadius: BorderRadius.all(Radius.circular(12)), child: _AppIcon())),
                    const SizedBox(width: 12),
                    Text('AeroStep AI', style: AeroText.titleMd.copyWith(fontSize: 22, color: AeroColors.onSurface)),
                  ]),
                  const SizedBox(height: 22),
                  Text('Step Today,', style: AeroText.headlineLg.copyWith(fontSize: 52, height: 1.05, color: AeroColors.onSurface)),
                  ShaderMask(
                    shaderCallback: (r) => AeroColors.tangerineGradient.createShader(r),
                    child: Text('Shine Tomorrow.', style: AeroText.headlineLg.copyWith(fontSize: 52, height: 1.1, color: Colors.white)),
                  ),
                  const SizedBox(height: 14),
                  Text('Zero Battery Drain.', style: AeroText.headlineMd.copyWith(fontSize: 26, color: AeroColors.onSurfaceVariant)),
                  const SizedBox(height: 22),
                  const Wrap(spacing: 10, runSpacing: 10, children: [
                    AeroBadge('0% GPS', icon: Icons.gps_off_rounded, background: AeroColors.charcoal, foreground: Colors.white),
                    AeroBadge('Anti-shake', icon: Icons.vibration_rounded, background: AeroColors.cyanFixed, foreground: AeroColors.onCyanFixed),
                    AeroBadge('No popup ads', icon: Icons.verified_rounded, background: AeroColors.peachFixed, foreground: AeroColors.tangerineDeep),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              flex: 9,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 330,
                    child: TangerineCard(
                      padding: const EdgeInsets.all(26),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('CURRENT COUNT', style: AeroText.labelCaps.copyWith(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text('8,420', style: AeroText.displayHeroMobile.copyWith(color: Colors.white, fontSize: 52)),
                                Text('/ 10,000 steps', style: AeroText.bodyMd.copyWith(color: Colors.white)),
                                const SizedBox(height: 14),
                                Text('6.1 km  •  380 kcal', style: AeroText.metricSm.copyWith(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          ),
                          ProgressRing(
                            value: 0.84,
                            size: 104,
                            stroke: 10,
                            child: Text('84%', style: AeroText.metricSm.copyWith(color: Colors.white, fontSize: 22)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(right: -6, bottom: -18, child: const _WatchDial(size: 150)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchDial extends StatelessWidget {
  const _WatchDial({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: const Color(0xFF3A3A3E), width: size * 0.05),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Stack(alignment: Alignment.center, children: [
        ProgressRing(value: 0.84, size: size * 0.82, stroke: size * 0.05, gradient: const [AeroColors.tangerine, AeroColors.skyCyan, AeroColors.tangerine], track: const Color(0xFF1F1F22)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('10:42', style: AeroText.metricSm.copyWith(color: Colors.white, fontSize: size * 0.17)),
          Text('8,420', style: AeroText.metricSm.copyWith(color: AeroColors.tangerine, fontSize: size * 0.11)),
          Text('118 SPM', style: AeroText.labelCaps.copyWith(color: AeroColors.skyCyan, fontSize: size * 0.065)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────── Framed screenshots ───────────────────────────

/// 1080x1920 store screenshot: caption + phone frame showing [screen].
class _Framed extends StatelessWidget {
  const _Framed({required this.title, required this.subtitle, required this.screens, this.dark = false});
  final String title;
  final String subtitle;
  final List<Widget> screens;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final two = screens.length == 2;
    return Container(
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C1714), Color(0xFF12100E)])
            : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF3EA), Color(0xFFFDE0C9)]),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _CornerStars(dark))),
        Column(children: [
          const SizedBox(height: 34),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(title,
                textAlign: TextAlign.center,
                style: AeroText.headlineLg.copyWith(fontSize: 27, height: 1.12, color: dark ? Colors.white : AeroColors.onSurface)),
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AeroText.bodyMd.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, color: dark ? AeroColors.peachFixedDim : AeroColors.tangerineDeep)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < screens.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Transform.translate(
                    offset: Offset(0, two && i == 1 ? 26 : 0),
                    child: _PhoneFrame(width: two ? 160 : 252, child: screens[i]),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ]),
    );
  }
}

class _CornerStars extends CustomPainter {
  _CornerStars(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AeroColors.tangerine.withValues(alpha: dark ? 0.10 : 0.14)
      ..strokeWidth = 10;
    void star(Offset c, double r) {
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(c - Offset(math.cos(a), math.sin(a)) * r, c + Offset(math.cos(a), math.sin(a)) * r, p);
      }
    }

    star(Offset(size.width * 0.95, size.height * 0.06), 48);
    star(Offset(size.width * 0.03, size.height * 0.62), 40);
  }

  @override
  bool shouldRepaint(_CornerStars old) => false;
}

/// Device bezel. The app is laid out at 360x780 logical and scaled to [width].
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.width, required this.child});
  final double width;
  final Widget child;

  static const screen = Size(360, 780);

  @override
  Widget build(BuildContext context) {
    final bezel = width * 0.035;
    final innerW = width - bezel * 2;
    final innerH = innerW * screen.height / screen.width;
    return Container(
      width: width,
      height: innerH + bezel * 2,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: AeroColors.charcoal,
        borderRadius: BorderRadius.circular(width * 0.13),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.10),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox.fromSize(
            size: screen,
            child: MediaQuery(
              data: const MediaQueryData(size: screen, padding: EdgeInsets.only(top: 28, bottom: 12)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────── Tests ─────────────────────────────────

Future<ProviderContainer> _container({required bool dark}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'onboarded': true, 'theme_mode': dark ? 'dark' : 'light', 'profile_name': 'Sunil Kumar'});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
}

/// One app screen with its own theme + providers (so light & dark can sit side by side).
class _AppScreen extends StatelessWidget {
  const _AppScreen({required this.container, required this.dark, required this.child});
  final ProviderContainer container;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
        container: container,
        child: Theme(
          data: dark ? AeroTheme.dark() : AeroTheme.light(),
          child: Builder(builder: (context) => DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child)),
        ),
      );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('demo mode is on', () => expect(kAeroDemoMode, isTrue, reason: 'run with --dart-define=AERO_DEMO=true'));

  testWidgets('icon + launcher sources', (tester) async {
    await tester.runAsync(_loadFonts);
    for (final (name, size, bg) in [('$_outPlay/icon_512.png', 512.0, true), ('$_outLauncher/icon_1024.png', 1024.0, true), ('$_outLauncher/icon_foreground_1024.png', 1024.0, false)]) {
      await _setSize(tester, Size.square(size), 1);
      final key = GlobalKey();
      // Adaptive-icon foreground: flutter_launcher_icons adds a 16% inset itself,
      // which keeps the art inside the 66% safe zone.
      final Widget art = _AppIcon(background: bg);
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: RepaintBoundary(key: key, child: Material(type: MaterialType.transparency, child: art))));
      await _settle(tester, 300);
      await _capture(tester, key, name, pixelRatio: 1);
    }
  });

  testWidgets('feature graphic 1024x500', (tester) async {
    await tester.runAsync(_loadFonts);
    await _setSize(tester, const Size(1024, 500), 1);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AeroTheme.light(),
      home: RepaintBoundary(key: key, child: const Material(child: _FeatureGraphic())),
    ));
    await _settle(tester, 1200);
    await _capture(tester, key, '$_outPlay/feature_graphic_1024x500.png', pixelRatio: 1);
  });

  // (file, caption, subtitle, frame dark?, [(dark?, dock tab, sub-view, route widget, scroll-to text)])
  final shots = <(String, String, String, bool, List<(bool, int, int, Widget?, String?)>)>[
    ('01_home', 'Accurate steps.\nZero GPS battery drain.', 'Hardware step sensor • works offline', false, [(false, 0, 0, null, null)]),
    ('02_tracker_light_dark', 'Warm light or\nespresso dark mode', 'Daily rhythm, distance, energy & gait', false, [(false, 0, 1, null, null), (true, 0, 1, null, null)]),
    ('03_analysis', 'Weekly steps &\nactive calories', 'Streak Shields protect your rest days', false, [(false, 1, 0, null, null)]),
    ('04_live_walk', 'Live walk coach\nwith cadence & pace', 'Auto-pauses in cars, buses & rickshaws', true, [(true, 0, 0, const LiveWalkScreen(), null)]),
    ('05_trends', 'Day, week, month\n& year trends', 'See your progress at a glance', false, [(false, 1, 1, null, null)]),
    ('06_step_bingo', 'Turn your week into\nKinetic Step Bingo', 'Fun 3x3 walking challenges', false, [(false, 3, 0, null, 'Kinetic Step Bingo')]),
    ('07_coach', 'Stride coach &\nhydration tracker', 'Tips on steps left, water, cadence & rest', false, [(false, 0, 0, const AiCoachHubScreen(), null)]),
    ('08_widgets', 'Home-screen widgets\n& watch-style dial', '1-tap +250 ml water right from your home screen', true, [(true, 0, 0, const WidgetShowcaseScreen(), null)]),
  ];

  // Bare phones (transparent background) for the promo video.
  final phones = <(String, bool, int, int, Widget?)>[
    ('home', false, 0, 0, null),
    ('tracker_light', false, 0, 1, null),
    ('tracker_dark', true, 0, 1, null),
    ('analysis', false, 1, 0, null),
    ('trends', false, 1, 1, null),
    ('live_walk', true, 0, 0, const LiveWalkScreen()),
    ('coach', false, 0, 0, const AiCoachHubScreen()),
    ('widgets', true, 0, 0, const WidgetShowcaseScreen()),
  ];
  for (final (name, dark, tab, sub, route) in phones) {
    testWidgets('promo phone $name', (tester) async {
      await tester.runAsync(_loadFonts);
      await _setSize(tester, const Size(300, 630), 3);
      final c = (await tester.runAsync(() => _container(dark: dark)))!;
      c.read(dockIndexProvider.notifier).set(tab);
      c.read(homeSubViewProvider.notifier).set(tab == 0 ? sub : 0);
      c.read(analysisSubViewProvider.notifier).set(tab == 1 ? sub : 0);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        color: Colors.transparent,
        home: ColoredBox(
          color: Colors.transparent,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _PhoneFrame(width: 270, child: _AppScreen(container: c, dark: dark, child: route ?? const MainShell())),
              ),
            ),
          ),
        ),
      ));
      await _settle(tester, 1600);
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await _settle(tester, 300);
      await _capture(tester, key, 'store_assets/promo_video/assets/phones/$name.png', pixelRatio: 3);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      c.dispose();
    });
  }

  for (final (file, title, subtitle, frameDark, screens) in shots) {
    testWidgets('screenshot $file', (tester) async {
      await tester.runAsync(_loadFonts);
      await _setSize(tester, const Size(360, 640), 3);
      final widgets = <Widget>[];
      final containers = <ProviderContainer>[];
      for (final (dark, tab, sub, route, _) in screens) {
        final c = await tester.runAsync(() => _container(dark: dark));
        containers.add(c!);
        c.read(dockIndexProvider.notifier).set(tab);
        c.read(homeSubViewProvider.notifier).set(tab == 0 ? sub : 0);
        c.read(analysisSubViewProvider.notifier).set(tab == 1 ? sub : 0);
        widgets.add(_AppScreen(container: c, dark: dark, child: route ?? const MainShell()));
      }
      addTearDown(() {
        for (final c in containers) {
          c.dispose();
        }
      });
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AeroTheme.light(),
        home: RepaintBoundary(key: key, child: Material(child: _Framed(title: title, subtitle: subtitle, screens: widgets, dark: frameDark))),
      ));
      await _settle(tester, 1600);
      final scrollTo = screens.first.$5;
      if (scrollTo != null) {
        // Lazily built lists: step the main vertical scrollable down until the target exists.
        final vertical = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .where((st) => st.position.axis == Axis.vertical)
            .reduce((a, b) => a.position.maxScrollExtent >= b.position.maxScrollExtent ? a : b);
        for (var i = 0; i < 30 && find.text(scrollTo).evaluate().isEmpty; i++) {
          vertical.position.jumpTo(math.min(vertical.position.pixels + 300, vertical.position.maxScrollExtent));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.runAsync(() => Scrollable.ensureVisible(tester.element(find.text(scrollTo).first), alignment: 0.04));
        await _settle(tester, 600);
      }
      // Decode asset photos (avatar crops etc.) before capturing.
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await _settle(tester, 300);
      await _capture(tester, key, '$_outPlay/screenshots/$file.png', pixelRatio: 3);
      // Unmount before disposing containers.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}

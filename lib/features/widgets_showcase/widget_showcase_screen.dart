import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';

final NumberFormat _group = NumberFormat('#,##0');

/// Fully qualified Android AppWidgetProvider for the 2x2 widget.
const _kSmallWidgetProvider = 'com.sunilkhatri.aerostep.AeroStepSmallWidgetProvider';

enum _Platform { all, ios, android, watch }

/// Widgets & Watch showcase (Stitch `aerostep_ai_widget_showcase_smartwatch`).
class WidgetShowcaseScreen extends ConsumerStatefulWidget {
  const WidgetShowcaseScreen({super.key});

  @override
  ConsumerState<WidgetShowcaseScreen> createState() => _WidgetShowcaseScreenState();
}

class _WidgetShowcaseScreenState extends ConsumerState<WidgetShowcaseScreen> {
  _Platform _platform = _Platform.all;
  bool _pinning = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AeroRoutes.home);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addToHomeScreen() async {
    if (_pinning) return;
    setState(() => _pinning = true);
    const manual = 'Long-press an empty spot on your home screen, tap Widgets, then drag AeroStep onto it.';
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) {
        _snackIfMounted('Your launcher can\'t add widgets automatically. $manual');
      } else {
        await HomeWidget.requestPinWidget(qualifiedAndroidName: _kSmallWidgetProvider);
        _snackIfMounted('Confirm the prompt to place the AeroStep widget on your home screen.');
      }
    } catch (_) {
      _snackIfMounted('Couldn\'t open the widget picker. $manual');
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  void _snackIfMounted(String msg) {
    if (mounted) _snack(msg);
  }

  bool get _showPhone => _platform != _Platform.watch;
  bool get _showWatch => _platform == _Platform.all || _platform == _Platform.watch;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AeroCanvas(
        child: AeroScrollPage(
          dockClearance: false,
          children: [
            Row(
              children: [
                AeroCircleButton(icon: Icons.arrow_back_ios_new_rounded, onPressed: _back, size: 44, tooltip: 'Back'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Widgets & Watch',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.headlineMd.copyWith(color: p.text),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final (pf, label, icon) in const [
                    (_Platform.all, 'All Widgets', Icons.widgets_rounded),
                    (_Platform.ios, 'iOS Lockscreen', Icons.phone_iphone_rounded),
                    (_Platform.android, 'Android 14 Material', Icons.android_rounded),
                    (_Platform.watch, 'Smartwatch', Icons.watch_rounded),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AeroCategoryChip(
                        label: label,
                        icon: icon,
                        selected: pf == _platform,
                        onTap: () => setState(() => _platform = pf),
                      ),
                    ),
                ],
              ),
            ),
            const _InfoCard(),
            if (_showPhone) ...[
              const _SectionLabel(lead: 'System preview', accent: '2x2 small component', trailing: '160 × 160 DP'),
              const _SmallWidgetStage(),
              Row(
                children: [
                  Expanded(
                    child: AeroPillButton(
                      label: _pinning ? 'Opening…' : 'Add to Home Screen',
                      icon: Icons.add_circle_outline_rounded,
                      expand: true,
                      onPressed: _pinning ? null : _addToHomeScreen,
                    ),
                  ),
                ],
              ),
              const _SectionLabel(lead: 'Expanded dashboard', accent: '4x2 interactive', trailing: 'Tap-to-Log Ready'),
              const _BentoWidgetPreview(),
            ],
            if (_showWatch) ...[
              const _WatchBanner(),
              const _SectionLabel(lead: 'Wrist ecosystem', accent: 'OLED dial component', trailing: 'Apple Watch & Wear OS'),
              const _WatchDialSection(),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AeroIconTile(
            icon: Icons.bolt_rounded,
            background: p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed,
            foreground: p.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glanceable kinetic telemetry without waking your phone.',
                  style: AeroText.bodyLg.copyWith(color: p.text, fontSize: 15, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  '0% battery drain synced directly via on-device pedometer coprocessor.',
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.lead, required this.accent, required this.trailing});
  final String lead;
  final String accent;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final caps = AeroText.labelCaps.copyWith(fontSize: 10);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: lead.toUpperCase(), style: caps.copyWith(color: p.text)),
                  TextSpan(text: '  •  ', style: caps.copyWith(color: p.accent)),
                  TextSpan(text: accent.toUpperCase(), style: caps.copyWith(color: p.accentText)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(trailing, style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2x2 small widget
// ---------------------------------------------------------------------------

class _SmallWidgetStage extends StatelessWidget {
  const _SmallWidgetStage();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: p.isDark
              ? const [Color(0xFF221C18), Color(0xFF181310)]
              : const [Color(0xFFF2EFF1), Color(0xFFE9E5E8)],
        ),
        border: Border.all(color: p.cardBorder),
      ),
      child: const Center(child: _SmallTangerineWidget()),
    );
  }
}

class _SmallTangerineWidget extends ConsumerWidget {
  const _SmallTangerineWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(activityProvider);
    final white80 = Colors.white.withValues(alpha: 0.82);
    final hourIdx = DateTime.now().hour;
    final lastHour = hourIdx > 0 && a.hourlySteps.length > hourIdx ? a.hourlySteps[hourIdx - 1] : 0;
    return Semantics(
      label: '2 by 2 widget preview: ${_group.format(a.steps)} steps, ${a.percent} percent of goal',
      child: Container(
        width: 168,
        height: 168,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AeroColors.tangerineGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x40FF7A2F), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -30,
              child: Icon(Icons.star_rounded, size: 110, color: Colors.white.withValues(alpha: 0.14)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_run_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text('LIVE', style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 9)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('AEROSTEP', style: AeroText.labelCaps.copyWith(color: white80, fontSize: 8)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _group.format(a.steps),
                                style: AeroText.numeric(26, color: Colors.white),
                              ),
                            ),
                            Text(
                              'STEPS TODAY',
                              style: AeroText.labelCaps.copyWith(color: white80, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      ProgressRing(
                        value: a.progress,
                        size: 44,
                        stroke: 4.5,
                        track: Colors.white.withValues(alpha: 0.22),
                        child: Text('${a.percent}%', style: AeroText.numeric(10, color: Colors.white)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Goal: ${_group.format(a.goal)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.numeric(10, weight: FontWeight.w500, color: white80),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '+${_group.format(lastHour)} pace',
                          style: AeroText.numeric(9, weight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4x2 interactive bento widget
// ---------------------------------------------------------------------------

class _BentoWidgetPreview extends ConsumerStatefulWidget {
  const _BentoWidgetPreview();

  @override
  ConsumerState<_BentoWidgetPreview> createState() => _BentoWidgetPreviewState();
}

class _BentoWidgetPreviewState extends ConsumerState<_BentoWidgetPreview> {
  bool _flash = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _addWater() {
    ref.read(hydrationProvider.notifier).add(250);
    _t?.cancel();
    setState(() => _flash = true);
    _t = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final a = ref.watch(activityProvider);
    final h = ref.watch(hydrationProvider);
    final wd = DateTime.now().weekday; // Mon = 1; weeklySteps is Mon..Sun.
    final yesterday = wd > 1 && a.weeklySteps.length >= wd ? a.weeklySteps[wd - 2] : 0;
    final delta = yesterday > 0 ? ((a.steps - yesterday) / yesterday * 100).round() : 0;
    final peachBg = p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed;
    final deep = p.isDark ? AeroColors.peachFixed : AeroColors.tangerineDeep;

    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tangerine step block.
                Expanded(
                  child: _Tile(
                    color: peachBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up_rounded, size: 16, color: deep),
                            const Spacer(),
                            Text(
                              '${delta >= 0 ? '+' : ''}$delta%',
                              style: AeroText.numeric(10, color: deep),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _FitNum(_group.format(a.steps), color: p.text),
                        Text('Steps Pace', style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: a.progress,
                            minHeight: 5,
                            color: AeroColors.tangerine,
                            backgroundColor: Colors.white.withValues(alpha: p.isDark ? 0.1 : 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sky-cyan calorie block.
                Expanded(
                  child: _Tile(
                    gradient: AeroColors.cyanGradient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 16, color: AeroColors.onCyanFixed),
                            const Spacer(),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: AeroColors.cyanDeep, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _FitNum(_group.format(a.kcal), color: AeroColors.onCyanFixed),
                        Text(
                          'kcal Burn',
                          style: AeroText.caption.copyWith(color: AeroColors.onCyanFixed, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.cadenceSpm >= 110 ? 'PEAK ZONE' : 'ACTIVE ZONE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.labelCaps.copyWith(color: AeroColors.onCyanFixed, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Charcoal quick hydration action (whole tile tappable).
                Expanded(
                  child: _Tile(
                    color: AeroColors.charcoal,
                    onTap: _addWater,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 16, color: Colors.white),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _flash ? AeroColors.skyCyan : Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _flash ? '+250!' : 'TAP +',
                                style: AeroText.labelCaps.copyWith(
                                  fontSize: 8,
                                  color: _flash ? AeroColors.onCyanFixed : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(h.litres, style: AeroText.numeric(20, color: Colors.white)),
                              Text(
                                '/${(h.goalMl / 1000).toStringAsFixed(1)}L',
                                style: AeroText.numeric(10, weight: FontWeight.w500, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Hydration Log',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.caption.copyWith(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AeroColors.cyanDeep,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('+250ml', style: AeroText.numeric(11, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: p.track),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.widgets_outlined, size: 16, color: p.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'iOS 17 & Android AppWidget',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ),
              const AeroBadge('Standby ready'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.child, this.color, this.gradient, this.onTap});
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(color: color, gradient: gradient, borderRadius: br),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(10), child: child),
        ),
      ),
    );
  }
}

class _FitNum extends StatelessWidget {
  const _FitNum(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text, style: AeroText.numeric(22, color: color)),
      );
}

// ---------------------------------------------------------------------------
// Watch banner + OLED dial
// ---------------------------------------------------------------------------

class _WatchBanner extends StatelessWidget {
  const _WatchBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF6B3A1F), AeroColors.charcoalWarm, AeroColors.charcoal],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AeroColors.tangerine.withValues(alpha: 0.45), AeroColors.tangerine.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WRIST HUD COMPANION',
                        style: AeroText.labelCaps.copyWith(color: AeroColors.peachFixed, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Always-On OLED Cadence',
                        style: AeroText.titleMd.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.watch_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('v3.4 Sync', style: AeroText.numeric(11, weight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchDialSection extends ConsumerStatefulWidget {
  const _WatchDialSection();

  @override
  ConsumerState<_WatchDialSection> createState() => _WatchDialSectionState();
}

class _WatchDialSectionState extends ConsumerState<_WatchDialSection> {
  DateTime _now = DateTime.now();
  Timer? _clock;
  bool _sync = true;
  bool _cyanFace = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.minute != _now.minute || n.hour != _now.hour) setState(() => _now = n);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _toggleSync(bool v) {
    setState(() => _sync = v);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            v
                ? 'Companion face sync on — your watch dial mirrors live steps & cadence.'
                : 'Companion face sync paused. Your phone keeps counting steps.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final a = ref.watch(activityProvider);
    final accent = _cyanFace ? AeroColors.skyCyan : AeroColors.tangerine;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2523), AeroColors.charcoal],
            ),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, c) => _OledDial(
                size: math.min(260, c.maxWidth),
                now: _now,
                activity: a,
                accent: accent,
                live: _sync,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        BentoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AeroIconTile(icon: Icons.devices_rounded, size: 42, foreground: p.accentText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sync Companion Face', style: AeroText.titleMd.copyWith(color: p.text)),
                        Text(
                          'Apple Watch Series 6+ & Wear OS 3+',
                          style: AeroText.caption.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sync,
                    onChanged: _toggleSync,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AeroColors.tangerine,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final f in const ['AOD Battery Guard', 'Real-Time Haptic Cadence'])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: p.cyan),
                        const SizedBox(width: 6),
                        Flexible(child: Text(f, style: AeroText.caption.copyWith(color: p.text))),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AeroPillButton(
                      label: 'Install Watch Face',
                      icon: Icons.download_rounded,
                      height: 46,
                      expand: true,
                      onPressed: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('The watch companion app is coming in a future update.')),
                        ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: p.chip,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => setState(() => _cyanFace = !_cyanFace),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette_outlined, size: 16, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              _cyanFace ? 'Sky Cyan' : 'Tangerine',
                              style: AeroText.caption.copyWith(color: p.text, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OledDial extends StatelessWidget {
  const _OledDial({
    required this.size,
    required this.now,
    required this.activity,
    required this.accent,
    required this.live,
  });

  final double size;
  final DateTime now;
  final ActivitySnapshot activity;
  final Color accent;
  final bool live;

  String get _zone {
    final spm = activity.cadenceSpm;
    if (spm == 0) return 'IDLE';
    if (spm >= 130) return 'POWER';
    if (spm >= 110) return 'FAT-BURN';
    if (spm >= 100) return 'BRISK';
    return 'EASY';
  }

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final time = '$h12:${now.minute.toString().padLeft(2, '0')}';
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    final white60 = Colors.white.withValues(alpha: 0.6);
    final goalK = a.goal >= 1000 ? '${(a.goal / 1000).toStringAsFixed(a.goal % 1000 == 0 ? 0 : 1)}k' : '${a.goal}';
    final inner = size * 0.80;

    return Semantics(
      label: 'Watch face: $time $ampm, ${_group.format(a.steps)} of $goalK steps, ${a.cadenceSpm} steps per minute',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient halo.
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: -6)],
              ),
            ),
            // Bezel.
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A3A30), Color(0xFF1C1714), Color(0xFF3A2A20)],
                ),
              ),
            ),
            // Progress ring.
            TweenAnimationBuilder<double>(
              tween: Tween(end: a.progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => CustomPaint(
                size: Size.square(size * 0.94),
                painter: _DialRingPainter(progress: v, color: accent),
              ),
            ),
            // OLED face.
            Container(
              width: inner,
              height: inner,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              padding: EdgeInsets.all(inner * 0.13),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 12, color: accent),
                          const SizedBox(width: 3),
                          Text(
                            '${a.cadenceSpm} SPM • $_zone',
                            style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(time, style: AeroText.numeric(44, color: Colors.white)),
                        const SizedBox(width: 3),
                        Text(ampm, style: AeroText.numeric(11, weight: FontWeight.w600, color: white60)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(Icons.directions_walk_rounded, size: 15, color: accent),
                        const SizedBox(width: 3),
                        Text(_group.format(a.steps), style: AeroText.numeric(17, color: Colors.white)),
                        Text(' / $goalK', style: AeroText.numeric(10, weight: FontWeight.w500, color: white60)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 12, color: AeroColors.skyCyan),
                        const SizedBox(width: 3),
                        Text('${_group.format(a.kcal)} kcal', style: AeroText.numeric(11, color: Colors.white)),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: white60, shape: BoxShape.circle),
                        ),
                        Icon(Icons.straighten_rounded, size: 12, color: white60),
                        const SizedBox(width: 3),
                        Text(
                          '${a.distanceKm.toStringAsFixed(1)} km',
                          style: AeroText.numeric(11, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 11, color: accent),
                        const SizedBox(width: 2),
                        Text(
                          live ? 'AOD • GYRO LIVE (0% GPS)' : 'AOD • SYNC PAUSED',
                          style: AeroText.labelCaps.copyWith(color: white60, fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialRingPainter extends CustomPainter {
  _DialRingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    if (progress <= 0) return;
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    const start = -math.pi / 2;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    final r = rect.width / 2;
    final tip = rect.center + Offset(math.cos(start + sweep), math.sin(start + sweep)) * r;
    canvas.drawCircle(tip, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_DialRingPainter old) => old.progress != progress || old.color != color;
}

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../app/shell_state.dart';
import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';
import 'health_sync_card.dart';
import 'home_common.dart';

/// Home tab, sub-view 1: Daily Activity Tracker. One widget that renders the
/// Stitch `aerostep_ai_activity_tracker_light` layout (white / peach bento,
/// tangerine hero) and the `..._dark_mode` layout (espresso cards with a neon
/// tangerine-cyan ring) depending on the active brightness.
class ActivityTrackerView extends ConsumerStatefulWidget {
  const ActivityTrackerView({super.key});

  @override
  ConsumerState<ActivityTrackerView> createState() => _ActivityTrackerViewState();
}

class _ActivityTrackerViewState extends ConsumerState<ActivityTrackerView> {
  bool _coachDismissed = false;

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(activityProvider);
    final dark = context.aero.isDark;
    return AeroScrollPage(
      children: [
        const _TrackerHeader(),
        const SubViewSwitcher.home(),
        _StatusRow(dark: dark),
        if (dark) _DarkHero(a: a) else _LightHero(a: a),
        const HealthSyncCard(),
        _EnergyGaitRow(a: a),
        const _VitalsRow(),
        if (!_coachDismissed) _CoachInsight(onDismiss: () => setState(() => _coachDismissed = true)),
        _RhythmCard(hourly: a.hourlySteps),
        const _RecoveryCard(),
        _WeeklyCadenceCard(weekly: a.weeklySteps),
        const _QuickLogButton(),
        const _QuickStartRow(),
      ],
    );
  }
}

/// Recessed sub-surface inside cards.
Color _sunken(AeroPalette p) => p.isDark ? const Color(0xFF17120F) : AeroColors.surfaceLow;

// ───────────────────────────── Header ─────────────────────────────

class _TrackerHeader extends StatelessWidget {
  const _TrackerHeader();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final wide = MediaQuery.sizeOf(context).width >= 400;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AeroColors.tangerineGradient,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [BoxShadow(color: Color(0x40FF7A2F), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AeroStep AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AeroText.titleMd.copyWith(color: p.text, fontWeight: FontWeight.w800, height: 1.15),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AeroColors.tangerine, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Activity Tracker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.caption.copyWith(color: p.accentText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (wide) ...[
          AeroBadge('Pro Athlete', icon: Icons.bolt_rounded, foreground: p.cyan),
          const SizedBox(width: 8),
        ],
        const ThemeToggleButton(),
        const SizedBox(width: 8),
        Tooltip(
          message: 'AeroStep Pro',
          child: GestureDetector(
            onTap: () => context.push(AeroRoutes.unlock),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AeroColors.tangerineGradient),
              child: HeroCrop(size: 40, dark: p.isDark, focus: p.isDark ? HeroCrop.faceDark : HeroCrop.faceLight),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final date = 'Today, ${DateFormat('MMM d', 'en_US').format(DateTime.now())}';
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? AeroColors.espressoCard : AeroColors.surfaceLow,
        borderRadius: BorderRadius.circular(99),
        boxShadow: dark ? const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4))] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingDot(color: dark ? AeroColors.tangerine : AeroColors.skyCyan, size: 7),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              dark ? 'ESPRESSO TELEMETRY • LIVE' : 'LIVE SYNCING',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.labelCaps.copyWith(
                color: dark ? AeroColors.peachFixed : AeroColors.cyanDeep,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
    final dateRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          dark ? Icons.sync_rounded : Icons.calendar_today_rounded,
          size: 15,
          color: dark ? AeroColors.skyCyan : p.accentText,
        ),
        const SizedBox(width: 6),
        Text(date, style: AeroText.numeric(12, weight: FontWeight.w600, color: p.textMuted)),
      ],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dark
          ? [Flexible(child: pill), const SizedBox(width: 8), dateRow]
          : [dateRow, const SizedBox(width: 8), Flexible(child: pill)],
    );
  }
}

// ──────────────────────────── Hero (light) ────────────────────────────

class _LightHero extends StatelessWidget {
  const _LightHero({required this.a});
  final ActivitySnapshot a;

  /// Steps vs yesterday (null on Mondays — the weekly ledger starts fresh).
  int? get _deltaVsYesterday {
    final i = DateTime.now().weekday - 1;
    if (i == 0 || a.weeklySteps.length < i) return null;
    return a.steps - a.weeklySteps[i - 1];
  }

  @override
  Widget build(BuildContext context) {
    final delta = _deltaVsYesterday;
    return TangerineCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: GlowBlob(size: 200, color: AeroColors.peachFixed.withValues(alpha: 0.45)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY MOVEMENT',
                          style: AeroText.labelCaps.copyWith(color: AeroColors.peachFixed, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Steps Count',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.headlineMd.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (delta != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${delta >= 0 ? '+' : '−'}${fmtInt(delta.abs())} vs yest.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.labelCaps.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: fmtInt(a.steps),
                                style: AeroText.displayHeroMobile.copyWith(color: Colors.white),
                              ),
                              numSpan(
                                '  / ${fmtCompact(a.goal)}',
                                size: 15,
                                weight: FontWeight.w500,
                                color: AeroColors.peachFixed,
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: AeroColors.peachFixed, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text.rich(
                                TextSpan(children: [
                                  numSpan('${a.percent}%', size: 12, weight: FontWeight.w600, color: Colors.white),
                                  const TextSpan(text: ' of daily target reached'),
                                ]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ProgressRing(
                    value: a.progress,
                    size: 96,
                    stroke: 7.5,
                    track: Colors.white.withValues(alpha: 0.22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${a.percent}%', style: AeroText.metricSm.copyWith(color: Colors.white)),
                        Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final icons = c.maxWidth >= 320;
                  Widget divider() => Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: Colors.white.withValues(alpha: 0.2),
                      );
                  return Row(
                    children: [
                      Expanded(
                        child: _MicroStat(
                          icon: Icons.route_rounded,
                          label: 'Distance',
                          value: '${a.distanceKm.toStringAsFixed(1)} km',
                          showIcon: icons,
                        ),
                      ),
                      divider(),
                      Expanded(
                        child: _MicroStat(
                          icon: Icons.timer_outlined,
                          label: 'Active Time',
                          value: fmtDuration(a.activeMinutes),
                          showIcon: icons,
                        ),
                      ),
                      divider(),
                      Expanded(
                        child: _MicroStat(
                          icon: Icons.terrain_rounded,
                          label: 'Climb',
                          value: '142 m',
                          showIcon: icons,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroStat extends StatelessWidget {
  const _MicroStat({required this.icon, required this.label, required this.value, required this.showIcon});
  final IconData icon;
  final String label;
  final String value;
  final bool showIcon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (showIcon) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(
                    fontSize: 11,
                    color: AeroColors.peachFixed.withValues(alpha: 0.95),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AeroText.metricSm.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      );
}

// ──────────────────────────── Hero (dark) ────────────────────────────

class _DarkHero extends StatelessWidget {
  const _DarkHero({required this.a});
  final ActivitySnapshot a;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final remaining = a.remaining;
    return BentoCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: GlowBlob(size: 200, color: AeroColors.tangerine.withValues(alpha: 0.12)),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AeroColors.tangerine.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_walk_rounded, size: 18, color: AeroColors.tangerine),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daily Kinetic Output',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.titleMd.copyWith(color: p.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AeroBadge(
                    '${a.percent}% Goal',
                    background: AeroColors.tangerine.withValues(alpha: 0.15),
                    foreground: AeroColors.tangerine,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final size = math.min(208.0, c.maxWidth);
                  return _NeonRing(
                    value: a.progress,
                    size: size,
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'STEPS TODAY',
                            maxLines: 1,
                            style: AeroText.labelCaps.copyWith(color: p.textMuted, letterSpacing: 2),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              fmtInt(a.steps),
                              style: AeroText.displayHeroMobile.copyWith(color: p.text),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  remaining > 0 ? Icons.arrow_upward_rounded : Icons.check_circle_rounded,
                                  size: 14,
                                  color: AeroColors.tangerine,
                                ),
                                const SizedBox(width: 4),
                                Text.rich(
                                  remaining > 0
                                      ? TextSpan(children: [
                                          numSpan(fmtInt(remaining), size: 12, weight: FontWeight.w600,
                                              color: AeroColors.peachFixed),
                                          const TextSpan(text: ' steps to target'),
                                        ])
                                      : const TextSpan(text: 'Target crushed'),
                                  style: AeroText.caption.copyWith(color: AeroColors.peachFixed),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DarkTile(
                      icon: Icons.timer_outlined,
                      tint: AeroColors.peachFixedDim,
                      label: 'Active Time',
                      value: fmtDuration(a.activeMinutes),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DarkTile(
                      icon: Icons.local_fire_department_rounded,
                      tint: AeroColors.tangerine,
                      label: 'Energy Burn',
                      value: '${fmtInt(a.kcal)} kcal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkTile extends StatelessWidget {
  const _DarkTile({required this.icon, required this.tint, required this.label, required this.value});
  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AeroColors.espressoSubtle, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AeroText.metricSm.copyWith(color: p.text)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Giant progress ring with a tangerine → peach → cyan sweep and neon glow.
class _NeonRing extends StatelessWidget {
  const _NeonRing({required this.value, required this.size, required this.child});
  final double value;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1).toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, c) => CustomPaint(painter: _NeonRingPainter(v), child: Center(child: c)),
          child: child,
        ),
      );
}

class _NeonRingPainter extends CustomPainter {
  _NeonRingPainter(this.value);
  final double value;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2 + 4);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xFF2D2420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );
    if (value <= 0) return;
    const start = -math.pi / 2;
    final sweep = math.pi * 2 * value;
    // Neon glow halo.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = AeroColors.tangerine.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Gradient arc (rotated slightly back so the round start cap stays tangerine).
    const lead = 0.12;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          endAngle: sweep + lead,
          colors: const [AeroColors.tangerine, AeroColors.tangerineLight, AeroColors.skyCyan],
          stops: const [0, 0.7, 1],
          transform: const GradientRotation(start - lead),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_NeonRingPainter old) => old.value != value;
}

// ──────────────────────── Energy + Gait row ────────────────────────

class _EnergyGaitRow extends StatelessWidget {
  const _EnergyGaitRow({required this.a});
  final ActivitySnapshot a;

  /// Last 6 hours of steps, normalized to 0..1 (drives the energy sparkline).
  List<double> get _recent {
    final now = DateTime.now().hour;
    final h = a.hourlySteps;
    final vals = [
      for (var i = 5; i >= 0; i--) (now - i) >= 0 && (now - i) < h.length ? h[now - i].toDouble() : 0.0,
    ];
    final m = vals.fold<double>(0, math.max);
    return m == 0 ? List.filled(6, 0) : [for (final v in vals) v / m];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final cyanTint = p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep;
    final recent = _recent;
    final barColors = [
      p.track,
      p.track,
      AeroColors.skyCyan.withValues(alpha: 0.6),
      AeroColors.skyCyan,
      AeroColors.tangerine,
      AeroColors.tangerine,
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTop(
                    icon: Icons.local_fire_department_rounded,
                    iconBg: AeroColors.skyCyan.withValues(alpha: p.isDark ? 0.16 : 0.22),
                    iconFg: cyanTint,
                    label: 'Energy',
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(fmtInt(a.kcal), style: AeroText.numeric(30, color: p.text)),
                  ),
                  Text('kcal burned', style: AeroText.caption.copyWith(color: p.textMuted)),
                  const Spacer(),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 10 + 30 * recent[i],
                              decoration: BoxDecoration(
                                color: barColors[i],
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BentoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTop(
                    icon: Icons.speed_rounded,
                    iconBg: p.isDark ? Colors.white : AeroColors.charcoal,
                    iconFg: p.isDark ? AeroColors.charcoal : Colors.white,
                    label: 'Gait',
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: a.avgPaceKmh.toStringAsFixed(1),
                          style: AeroText.numeric(30, color: p.text),
                        ),
                        TextSpan(
                          text: ' km/h',
                          style: AeroText.caption.copyWith(color: p.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  ),
                  Text('Avg pace', style: AeroText.caption.copyWith(color: p.textMuted)),
                  const Spacer(),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: _sunken(p), borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      children: [
                        Icon(Icons.directions_run_rounded, size: 13, color: p.accentText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Cadence',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.caption.copyWith(color: p.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text.rich(
                          TextSpan(children: [
                            numSpan('${a.cadenceSpm}', size: 13, color: p.text),
                            TextSpan(
                              text: ' spm',
                              style: AeroText.caption.copyWith(fontSize: 10, color: p.textMuted),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTop extends StatelessWidget {
  const _CardTop({required this.icon, required this.iconBg, required this.iconFg, required this.label});
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(99)),
            child: Icon(icon, size: 20, color: iconFg),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.labelCaps.copyWith(color: context.aero.textMuted, letterSpacing: 1),
            ),
          ),
        ],
      );
}

// ─────────────────────── Heart rate + elevation ───────────────────────

class _VitalsRow extends StatelessWidget {
  const _VitalsRow();

  // Static demo telemetry (no sensor source yet): ECG-like pulse + hill profile.
  static const List<double> _pulse = [
    11.0, 11, 11, 11.5, 11, 5, 20, 7, 12.5, 11, 11, 11, 11, 11.5, 11, 4, 21, 6, 12, 11, 11, 11,
  ];
  static const List<double> _hill = [3.0, 4, 5, 7, 10, 12.5, 13, 12, 11.5, 12, 13.5, 15, 16, 15, 14.5, 15.5, 17];

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final cyanLine = p.isDark ? AeroColors.skyCyan : AeroColors.telemetryCyan;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _VitalCard(
              icon: Icons.favorite_border_rounded,
              tint: p.cyan,
              badge: 'Zone 2',
              label: 'Heart Rate',
              value: '134',
              unit: 'bpm',
              footer: 'Aerobic endurance tier',
              glow: AeroColors.skyCyan,
              chart: _sparkline(_pulse, cyanLine, curved: false, fill: false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _VitalCard(
              icon: Icons.landscape_rounded,
              tint: p.accentText,
              badge: 'Climb',
              label: 'Elevation Gain',
              value: '142',
              unit: 'm',
              footer: 'Peak grade: 6.4% incline',
              glow: AeroColors.tangerine,
              chart: _sparkline(_hill, AeroColors.tangerine, curved: true, fill: true),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sparkline(List<double> ys, Color color, {required bool curved, required bool fill}) {
    final maxY = ys.reduce(math.max) + 3;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (ys.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.none(),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
            isCurved: curved,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.2,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            dotData: const FlDotData(show: false),
            shadow: Shadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
            belowBarData: BarAreaData(
              show: fill,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.icon,
    required this.tint,
    required this.badge,
    required this.label,
    required this.value,
    required this.unit,
    required this.footer,
    required this.glow,
    required this.chart,
  });

  final IconData icon;
  final Color tint;
  final String badge;
  final String label;
  final String value;
  final String unit;
  final String footer;
  final Color glow;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: GlowBlob(size: 110, color: glow.withValues(alpha: p.isDark ? 0.16 : 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), shape: BoxShape.circle),
                        child: Icon(icon, size: 16, color: tint),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: AeroBadge(badge, background: tint.withValues(alpha: 0.14), foreground: tint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.caption.copyWith(color: p.textMuted),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: value, style: AeroText.metricLg.copyWith(color: p.text)),
                        TextSpan(
                          text: ' $unit',
                          style: AeroText.caption.copyWith(color: tint, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 8),
                  SizedBox(height: 32, width: double.infinity, child: chart),
                  const SizedBox(height: 8),
                  Text.rich(
                    _numbersIn(footer, p.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.caption.copyWith(color: p.textMuted),
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

/// Splits copy so every digit run renders in Space Grotesk tabular.
TextSpan _numbersIn(String text, Color color, {double size = 12}) {
  final spans = <InlineSpan>[];
  text.splitMapJoin(
    RegExp(r'[0-9][0-9.,:%]*'),
    onMatch: (m) {
      spans.add(numSpan(m[0]!, size: size, weight: FontWeight.w600, color: color));
      return '';
    },
    onNonMatch: (s) {
      spans.add(TextSpan(text: s));
      return '';
    },
  );
  return TextSpan(children: spans);
}

// ─────────────────────────── Coach insight ───────────────────────────

class _CoachInsight extends StatelessWidget {
  const _CoachInsight({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: p.isDark
              ? [AeroColors.tangerine.withValues(alpha: 0.14), AeroColors.espressoCard, AeroColors.espressoCard]
              : [AeroColors.peachFixed.withValues(alpha: 0.55), Colors.white, Colors.white],
        ),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [AeroColors.tangerineDeep, AeroColors.tangerine],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x66FF7A2F), blurRadius: 14, offset: Offset(0, 4))],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Stride AI Coach',
                            style: AeroText.titleMd.copyWith(fontSize: 14, color: p.text),
                          ),
                          AeroBadge(
                            'Optimal Gait',
                            background: AeroColors.tangerine.withValues(alpha: 0.12),
                            foreground: p.accentText,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Just now', style: AeroText.caption.copyWith(fontSize: 11, color: p.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Stride AI detected optimal gait efficiency '),
                    numSpan('(+8%)', size: 14, color: p.accentText),
                    const TextSpan(text: '. Recommend a '),
                    numSpan('12', size: 14, weight: FontWeight.w500, color: p.textMuted),
                    const TextSpan(text: '-min brisk cooldown to lock in recovery.'),
                  ]),
                  style: AeroText.bodyMd.copyWith(color: p.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AeroPillButton(
                      label: 'Start Cooldown',
                      icon: Icons.play_arrow_rounded,
                      height: 36,
                      onPressed: () => context.push(AeroRoutes.liveWalk),
                    ),
                    Material(
                      color: _sunken(p),
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onDismiss,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          child: Text(
                            'Dismiss',
                            style: AeroText.caption.copyWith(color: p.textMuted, fontWeight: FontWeight.w600),
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
      ),
    );
  }
}

// ─────────────────────────── Walking rhythm ───────────────────────────

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.hourly});
  final List<int> hourly;

  static const _startHours = [6, 8, 10, 12, 14, 16, 18, 20];

  static String _hourLabel(int h, {bool long = false}) {
    final suffix = h < 12 ? (long ? ' AM' : 'a') : (long ? ' PM' : 'p');
    final v = h % 12 == 0 ? 12 : h % 12;
    return '$v$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    int at(int h) => h < hourly.length ? hourly[h] : 0;
    final buckets = [for (final h in _startHours) at(h) + at(h + 1)];
    final maxV = buckets.fold<int>(0, math.max);
    final ranked = [for (var i = 0; i < buckets.length; i++) i]..sort((x, y) => buckets[y].compareTo(buckets[x]));
    final peaks = maxV == 0 ? <int>{} : ranked.take(2).where((i) => buckets[i] > 0).toSet();
    final peakIdx = maxV == 0 ? null : ranked.first;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Walking Rhythm', style: AeroText.titleMd.copyWith(color: p.text)),
                    Text.rich(
                      _numbersIn('Hourly distribution (6 AM – 8 PM)', p.textMuted),
                      style: AeroText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _sunken(p), borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AeroColors.tangerine, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text.rich(
                      peakIdx == null
                          ? const TextSpan(text: 'No steps yet')
                          : TextSpan(children: [
                              const TextSpan(text: 'Peak at '),
                              numSpan(_hourLabel(_startHours[peakIdx], long: true),
                                  size: 11, weight: FontWeight.w500, color: p.textMuted),
                            ]),
                      style: AeroText.caption.copyWith(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, c) => BarChart(
                _barData(context, buckets, peaks, maxV, barWidth: (c.maxWidth / buckets.length) * 0.74),
                duration: const Duration(milliseconds: 400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _barData(BuildContext context, List<int> buckets, Set<int> peaks, int maxV, {required double barWidth}) {
    final p = context.aero;
    final lightFill = p.isDark ? AeroColors.tangerine.withValues(alpha: 0.3) : AeroColors.peachFixed;
    final peakGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: p.isDark
          ? const [AeroColors.tangerine, AeroColors.tangerineLight]
          : const [AeroColors.tangerineDeep, AeroColors.tangerine],
    );
    String compact(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: math.max(maxV * 1.3, 100),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => p.isDark
              ? AeroColors.tangerine.withValues(alpha: 0.22)
              : AeroColors.peachFixed.withValues(alpha: 0.75),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          tooltipMargin: 4,
          tooltipBorderRadius: BorderRadius.circular(5),
          getTooltipItem: (group, _, rod, _) => BarTooltipItem(
            compact(rod.toY.round()),
            AeroText.labelCaps.copyWith(fontSize: 9, color: p.accentText),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final i = value.round();
              if (i < 0 || i >= _startHours.length) return const SizedBox.shrink();
              final peak = peaks.contains(i);
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _hourLabel(_startHours[i]),
                  style: AeroText.labelCaps.copyWith(
                    fontSize: 10,
                    letterSpacing: 0,
                    color: peak ? p.accentText : p.textMuted,
                    fontWeight: peak ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < buckets.length; i++)
          BarChartGroupData(
            x: i,
            showingTooltipIndicators: peaks.contains(i) ? const [0] : const [],
            barRods: [
              BarChartRodData(
                toY: buckets[i].toDouble(),
                width: barWidth,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                gradient: peaks.contains(i) ? peakGradient : null,
                color: peaks.contains(i)
                    ? null
                    : (maxV > 0 && buckets[i] >= maxV * 0.5 ? lightFill : p.track),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────── Recovery card ───────────────────────────

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: GlowBlob(size: 150, color: AeroColors.tangerine.withValues(alpha: p.isDark ? 0.2 : 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [AeroColors.tangerineDeep, AeroColors.tangerine],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Color(0x66FF7A2F), blurRadius: 16, offset: Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.bedtime_rounded, color: Colors.white, size: 24),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AeroColors.skyCyan,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.isDark ? AeroColors.espressoCard : Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.auto_awesome, size: 9, color: AeroColors.onCyanFixed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Adaptive Recovery',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.headlineMd.copyWith(color: p.text, height: 1.2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AeroBadge(
                              'Night Sync',
                              background: p.isDark ? const Color(0xFF2D2420) : AeroColors.surfaceHigh,
                              foreground: p.isDark ? AeroColors.peachFixedDim : AeroColors.tangerineDeep,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'You hit peak velocity during your sunset sprint at '),
                            numSpan('18:42', size: 14, weight: FontWeight.w500, color: p.textMuted),
                            const TextSpan(text: '. Muscular strain is moderately elevated.'),
                          ]),
                          style: AeroText.bodyMd.copyWith(color: p.textMuted, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: _sunken(p), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Icon(Icons.nights_stay_rounded, size: 18, color: p.cyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recommended Rest',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AeroText.caption.copyWith(color: p.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '7h 45m',
                                style: AeroText.metricSm.copyWith(
                                  color: p.isDark ? AeroColors.peachFixed : AeroColors.tangerineDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ──────────────────────── Weekly kinetic cadence ────────────────────────

class _WeeklyCadenceCard extends StatelessWidget {
  const _WeeklyCadenceCard({required this.weekly});
  final List<int> weekly;

  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final values = [for (var i = 0; i < 7; i++) i < weekly.length ? weekly[i] : 0];
    final active = values.where((v) => v > 0).toList();
    final avg = active.isEmpty ? 0 : active.reduce((x, y) => x + y) ~/ active.length;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final peakIdx = maxV > 0 ? values.indexOf(maxV) : -1;
    final range = math.max(maxV - minV, 500);
    final minY = math.max(0, minV - range * 0.7).toDouble();
    final maxY = maxV + range * 0.35;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Kinetic Cadence', style: AeroText.titleMd.copyWith(color: p.text)),
                    Text('Mon - Sun Momentum', style: AeroText.caption.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _sunken(p), borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AeroColors.skyCyan, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AVG ${fmtInt(avg)}',
                      style: AeroText.labelCaps.copyWith(color: p.cyan, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: minY,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                clipData: const FlClipData.none(),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < 7; i++) FlSpot(i.toDouble(), values[i].toDouble())],
                    isCurved: true,
                    curveSmoothness: 0.4,
                    preventCurveOverShooting: true,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    gradient: const LinearGradient(
                      colors: [AeroColors.skyCyan, AeroColors.tangerine, AeroColors.tangerineLight],
                    ),
                    shadow: p.isDark
                        ? Shadow(color: AeroColors.tangerine.withValues(alpha: 0.45), blurRadius: 8)
                        : const Shadow(color: Colors.transparent),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AeroColors.tangerine.withValues(alpha: 0.25),
                          AeroColors.tangerine.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      checkToShowDot: (spot, _) => spot.x.round() == peakIdx,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4.5,
                        color: AeroColors.tangerine,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 16,
            child: Stack(
              children: [
                for (var i = 0; i < 7; i++)
                  Align(
                    alignment: Alignment(-1 + i / 3, 0),
                    child: Text(
                      i == peakIdx ? '${_days[i]} (PEAK)' : _days[i],
                      style: AeroText.labelCaps.copyWith(
                        fontSize: 10,
                        color: i == peakIdx ? p.accentText : p.textMuted,
                      ),
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

// ─────────────────────────── Quick actions ───────────────────────────

class _QuickLogButton extends ConsumerWidget {
  const _QuickLogButton();

  static String get _partOfDay {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.aero;
    void log() {
      ref.read(hydrationProvider.notifier).add(250);
      final h = ref.read(hydrationProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, AeroFloatingBottomDock.clearance + 8),
            content: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Electrolytes logged! '),
                numSpan('+250ml', size: 14, color: AeroColors.peachFixed),
                const TextSpan(text: ' • '),
                numSpan('${h.litres} L', size: 14, weight: FontWeight.w600, color: Colors.white),
                const TextSpan(text: ' today'),
              ]),
            ),
          ),
        );
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), boxShadow: p.cardShadow),
      child: Material(
        color: p.isDark ? const Color(0xFF1A1512) : p.card,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: log,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop_outlined, size: 20, color: p.cyan),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Quick Log: $_partOfDay Rehydration '),
                      numSpan('(+250ml)', size: 14, weight: FontWeight.w600, color: p.text),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.bodyLg.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: p.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStartRow extends ConsumerWidget {
  const _QuickStartRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.aero;
    return Row(
      children: [
        Expanded(
          child: AeroPillButton(
            label: 'Quick Start Walk',
            icon: Icons.directions_run_rounded,
            height: 56,
            expand: true,
            onPressed: () => context.push(AeroRoutes.liveWalk),
          ),
        ),
        const SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: p.cardShadow),
          child: AeroCircleButton(
            icon: Icons.map_outlined,
            size: 56,
            tooltip: 'Virtual trails',
            foreground: p.cyan,
            onPressed: () => ref.read(dockIndexProvider.notifier).set(2),
          ),
        ),
      ],
    );
  }
}

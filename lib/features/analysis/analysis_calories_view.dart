import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/shell_state.dart';
import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';
import 'widgets/analysis_header.dart';

/// Analysis tab, view 0 — `aerostep_ai_analysis_active_calories`.
class AnalysisCaloriesView extends ConsumerWidget {
  const AnalysisCaloriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(activityProvider);
    final shields = ref.watch(streakShieldProvider);
    return AeroScrollPage(
      children: [
        const AnalysisHeader(title: 'Analysis', subtitle: 'Active calories & cadence', icon: Icons.query_stats_rounded),
        _WeeklySummaryCard(activity: a),
        _ActiveMetricsSheet(activity: a),
        _StreakShieldSection(streakDays: a.streakDays, shields: shields),
        const _CoachTip(),
      ],
    );
  }
}

/// Active kcal burned per step, derived from today's numbers when available.
double _kcalPerStep(ActivitySnapshot a) => a.steps > 0 && a.kcal > 0 ? a.kcal / a.steps : 0.045;

// ---------------------------------------------------------------------------
// Weekly Summary (Tangerine hero with Trio-Bar chart)
// ---------------------------------------------------------------------------

class _WeeklySummaryCard extends ConsumerWidget {
  const _WeeklySummaryCard({required this.activity});
  final ActivitySnapshot activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = activity;
    final kcalDailyAvg = (a.weeklyTotal * _kcalPerStep(a) / 7).round();
    return TangerineCard(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: 40,
            child: AsteriskMark(size: 120, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'WEEKLY SUMMARY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  _PeriodPill(onTap: () => ref.read(analysisSubViewProvider.notifier).set(1)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Total Steps & Burn',
                style: AeroText.bodyLg.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(fmtInt(a.weeklyTotal), style: AeroText.displayHeroMobile.copyWith(color: Colors.white)),
                    const SizedBox(width: 6),
                    Text('STEPS', style: AeroText.labelCaps.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                    child: const Icon(Icons.trending_up_rounded, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: fmtInt(kcalDailyAvg), style: AeroText.numeric(14, weight: FontWeight.w600)),
                          const TextSpan(text: ' kcal daily avg • '),
                          TextSpan(text: '+14.2%', style: AeroText.numeric(14, weight: FontWeight.w700)),
                          const TextSpan(text: ' vs last week'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.bodyMd.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(height: 150, child: _TrioBarChart(activity: a)),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: _LegendDot(color: Colors.white, label: 'Step Activity')),
                  const Flexible(child: _LegendDot(color: AeroColors.skyCyan, label: 'Burn Pace')),
                  Flexible(
                    child: _LegendDot(color: AeroColors.charcoal.withValues(alpha: 0.65), label: 'Base Goal'),
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

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Weekly',
                  style: AeroText.bodyMd.copyWith(color: AeroColors.charcoal, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, size: 18, color: AeroColors.charcoal),
              ],
            ),
          ),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      );
}

/// Grouped bars per weekday: Base Goal (charcoal), Burn Pace (cyan), Step Activity (white).
class _TrioBarChart extends StatelessWidget {
  const _TrioBarChart({required this.activity});
  final ActivitySnapshot activity;

  // Relative walking intensity per weekday (brisk vs. leisurely) used to shape
  // the Burn Pace series until per-day kcal history is persisted.
  static const _intensity = [0.84, 0.9, 0.86, 1.06, 0.93, 0.97, 0.9];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final steps = activity.weeklySteps;
    final goal = activity.goal.toDouble();
    final burn = [for (var i = 0; i < 7; i++) steps[i] * _intensity[i]];
    final maxY = [goal, ...steps.map((e) => e.toDouble()), ...burn].reduce(math.max) * 1.08;
    final today = DateTime.now().weekday - 1;

    BarChartRodData rod(double y, Color c, double w) => BarChartRodData(
          toY: y,
          color: c,
          width: w,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(99)),
        );

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AeroColors.charcoal,
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tooltipMargin: 6,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, _, rod, rodIndex) {
              final i = group.x;
              final text = switch (rodIndex) {
                0 => 'Goal ${fmtCompact(goal)}',
                1 => 'Burn ${(steps[i] * _kcalPerStep(activity)).round()} kcal',
                _ => '${fmtInt(steps[i])} steps',
              };
              return BarTooltipItem(text, AeroText.numeric(11, color: Colors.white));
            },
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
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _labels[v.toInt()],
                  style: AeroText.labelCaps.copyWith(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: v.toInt() == today ? 1 : 0.8),
                    fontWeight: v.toInt() == today ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < 7; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                rod(goal, AeroColors.charcoal.withValues(alpha: 0.6), 6),
                rod(burn[i], AeroColors.skyCyan, 6),
                rod(steps[i].toDouble(), Colors.white, 8),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Metrics white sheet (asymmetric bento grid)
// ---------------------------------------------------------------------------

class _ActiveMetricsSheet extends StatelessWidget {
  const _ActiveMetricsSheet({required this.activity});
  final ActivitySnapshot activity;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final a = activity;
    return BentoCard(
      radius: 32,
      padding: const EdgeInsets.all(16),
      color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Active Metrics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.headlineMd.copyWith(color: p.text),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.insights_rounded, size: 18, color: p.accentText),
              const Spacer(),
              const _LiveTelemetryBadge(),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 236,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _StepsTallCard(activity: a)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CapsuleMetricCard(
                          value: '${fmtInt(a.kcal)} kcal',
                          label: 'Active Cardio',
                          capsuleColor: AeroColors.skyCyan.withValues(alpha: p.isDark ? 0.22 : 0.2),
                          iconColor: p.cyan,
                          icon: Icons.local_fire_department_rounded,
                          capsuleLeading: true,
                          footer: AeroBadge(
                            'Peak',
                            background: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
                            foreground: p.isDark ? AeroColors.peachFixed : const Color(0xFF351000),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _CapsuleMetricCard(
                          value: '${a.distanceKm.toStringAsFixed(1)} km',
                          label: 'Distance & Pace',
                          capsuleColor: AeroColors.charcoal,
                          iconColor: AeroColors.skyCyan,
                          icon: Icons.explore_outlined,
                          capsuleLeading: false,
                          footer: Text(
                            _paceLabel(a),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11),
                          ),
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
    );
  }

  static String _paceLabel(ActivitySnapshot a) {
    if (a.activeMinutes <= 0 || a.distanceKm <= 0) return 'Pace pending';
    final kmh = a.distanceKm / (a.activeMinutes / 60);
    return '${kmh.toStringAsFixed(1)} km/h steady';
  }
}

class _LiveTelemetryBadge extends StatelessWidget {
  const _LiveTelemetryBadge();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 10, 2),
      decoration: BoxDecoration(
        color: AeroColors.telemetryCyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingDot(color: p.cyan, size: 6),
          const SizedBox(width: 2),
          Text('LIVE', style: AeroText.labelCaps.copyWith(color: p.cyan)),
        ],
      ),
    );
  }
}

class _StepsTallCard extends StatelessWidget {
  const _StepsTallCard({required this.activity});
  final ActivitySnapshot activity;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final dailyAvg = (a.weeklyTotal / 7).round();
    final delta = a.steps - a.goal;
    final deltaLabel = delta >= 0 ? '+${fmtInt(delta)} vs goal' : '${fmtInt(-delta)} to goal';
    final white80 = Colors.white.withValues(alpha: 0.8);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF853A), Color(0xFFFF6B1A)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x47FF6B1A), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: AsteriskMark(size: 112, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.directions_walk_rounded, size: 20, color: Colors.white),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(fmtInt(a.steps), style: AeroText.metricLg.copyWith(color: Colors.white)),
                ),
                Text(
                  'STEPS TODAY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.labelCaps.copyWith(color: white80),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Daily avg '),
                      TextSpan(text: fmtInt(dailyAvg), style: AeroText.numeric(14, weight: FontWeight.w700)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Brisk walk • Level 2',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delta >= 0 ? Icons.north_east_rounded : Icons.flag_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          deltaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 10),
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
    );
  }
}

/// Small bento with a vertical capsule icon (Sky-Cyan or Charcoal) and a metric.
class _CapsuleMetricCard extends StatelessWidget {
  const _CapsuleMetricCard({
    required this.value,
    required this.label,
    required this.capsuleColor,
    required this.iconColor,
    required this.icon,
    required this.capsuleLeading,
    required this.footer,
  });

  final String value;
  final String label;
  final Color capsuleColor;
  final Color iconColor;
  final IconData icon;
  final bool capsuleLeading;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final capsule = Container(
      width: 36,
      height: 60,
      decoration: BoxDecoration(
        color: capsuleColor,
        borderRadius: BorderRadius.circular(99),
        border: p.isDark && capsuleColor == AeroColors.charcoal
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(height: 4),
          Container(width: 4, height: 4, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
        ],
      ),
    );
    final align = capsuleLeading ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final details = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: align,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: capsuleLeading ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(value, style: AeroText.metricSm.copyWith(color: p.text, fontWeight: FontWeight.w700)),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.caption.copyWith(color: p.text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          footer,
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF2A221D) : AeroColors.surfaceLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: capsuleLeading
            ? [capsule, const SizedBox(width: 8), details]
            : [details, const SizedBox(width: 8), capsule],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery & Streak Shield banner
// ---------------------------------------------------------------------------

class _StreakShieldSection extends StatelessWidget {
  const _StreakShieldSection({required this.streakDays, required this.shields});
  final int streakDays;
  final int shields;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final active = shields > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Prioritize proper recovery & streak',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.titleMd.copyWith(color: p.text),
                ),
              ),
              const SizedBox(width: 8),
              Text('AI Stride', style: AeroText.caption.copyWith(color: p.accentText, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [AeroColors.tangerine, Color(0xFFFF853A), Color(0xFFE48B4F)]),
            boxShadow: const [BoxShadow(color: Color(0x40FF7A2F), blurRadius: 26, offset: Offset(0, 10))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => context.push(AeroRoutes.unlock),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 3))],
                            ),
                            child: const Center(
                              child: Icon(Icons.verified_user_rounded, size: 24, color: AeroColors.tangerine),
                            ),
                          ),
                          if (active)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AeroColors.skyCyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  active ? 'Streak Shield Active' : 'Earn a Streak Shield',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AeroText.titleMd.copyWith(color: Colors.white, fontSize: 15),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'DAY $streakDays',
                                  style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            active
                                ? '$shields shield${shields == 1 ? '' : 's'} ready • walking advice & recovery windows'
                                : 'Watch a short video to guard your rest day',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachTip extends StatelessWidget {
  const _CoachTip();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: p.accentText),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Coach Tip: ', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
                  const TextSpan(text: 'Evening 15-min walk burns '),
                  TextSpan(text: '92', style: AeroText.numeric(12, weight: FontWeight.w600)),
                  const TextSpan(text: ' kcal & regulates glycemic recovery.'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.caption.copyWith(color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

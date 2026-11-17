import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';
import 'widgets/analysis_header.dart';

enum _Period { day, week, month, year }

extension on _Period {
  String get label => switch (this) {
        _Period.day => 'Day',
        _Period.week => 'Week',
        _Period.month => 'Month',
        _Period.year => 'Year',
      };

  String get volumeTitle => switch (this) {
        _Period.day => 'Daily Stride Volume',
        _Period.week => 'Weekly Stride Volume',
        _Period.month => 'Monthly Stride Volume',
        _Period.year => 'Yearly Stride Volume',
      };
}

/// One chart series for a period: bucket labels, values, how many calendar
/// days it spans (for the daily average) and a goal-attainment caption.
class _Series {
  const _Series({
    required this.labels,
    required this.values,
    required this.days,
    required this.goalCaption,
    required this.trend,
  });
  final List<String> labels;
  final List<int> values;
  final int days;
  final String goalCaption;
  final String trend;

  int get total => values.fold(0, (a, b) => a + b);
}

/// Builds the Day / Week / Month / Year series. Day & Week come straight from
/// [ActivitySnapshot]; Month & Year are extrapolated from the current weekly
/// rhythm until the step-ledger history provider is exposed to the UI.
_Series _seriesFor(_Period period, ActivitySnapshot a) {
  final goal = a.goal;
  switch (period) {
    case _Period.day:
      final buckets = [
        for (var b = 0; b < 8; b++) a.hourlySteps.skip(b * 3).take(3).fold<int>(0, (s, v) => s + v),
      ];
      return _Series(
        labels: const ['12a', '3a', '6a', '9a', '12p', '3p', '6p', '9p'],
        values: buckets,
        days: 1,
        goalCaption: '${a.percent}% of today\'s ${fmtInt(goal)} goal',
        trend: '+6.4%',
      );
    case _Period.week:
      final hit = a.weeklySteps.where((s) => s >= goal).length;
      return _Series(
        labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        values: a.weeklySteps,
        days: 7,
        goalCaption: 'Goal surpassed on $hit out of 7 days',
        trend: '+12.8%',
      );
    case _Period.month:
      const shape = [0.86, 0.95, 1.07, 1.0];
      final week = a.weeklyTotal;
      final values = [for (final f in shape) (week * f).round()];
      final hit = values.where((v) => v >= goal * 7).length;
      return _Series(
        labels: const ['W1', 'W2', 'W3', 'W4'],
        values: values,
        days: 28,
        goalCaption: 'Weekly target met in $hit of 4 weeks',
        trend: '+8.1%',
      );
    case _Period.year:
      const shape = [0.78, 0.82, 0.9, 0.96, 1.04, 1.1, 1.14, 1.08, 1.0, 0.94, 0.86, 0.8];
      final dailyAvg = a.weeklyTotal / 7;
      final values = [for (final f in shape) (dailyAvg * 30.4 * f).round()];
      final hit = values.where((v) => v >= goal * 30.4).length;
      return _Series(
        labels: const ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'],
        values: values,
        days: 365,
        goalCaption: 'Monthly target met in $hit of 12 months',
        trend: '+21.5%',
      );
  }
}

/// Analysis tab, view 1 — `aerostep_ai_trends_analytics`.
class TrendsAnalyticsView extends ConsumerStatefulWidget {
  const TrendsAnalyticsView({super.key});

  @override
  ConsumerState<TrendsAnalyticsView> createState() => _TrendsAnalyticsViewState();
}

class _TrendsAnalyticsViewState extends ConsumerState<TrendsAnalyticsView> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(activityProvider);
    final series = _seriesFor(_period, a);
    return AeroScrollPage(
      children: [
        const AnalysisHeader(title: 'Trends', subtitle: 'Stride analytics', icon: Icons.insights_rounded),
        AeroSegmented<_Period>(
          options: _Period.values,
          selected: _period,
          labelOf: (p) => p.label,
          onChanged: (p) => setState(() => _period = p),
        ),
        _StrideVolumeCard(period: _period, series: series),
        const _TempoBanner(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _CadenceCard(cadence: a.cadenceSpm)),
              const SizedBox(width: 12),
              const Expanded(child: _CardioFitnessCard()),
            ],
          ),
        ),
        _CenturyStreakCard(streakDays: a.streakDays, goal: a.goal),
        const _ReadinessTile(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stride volume bar chart
// ---------------------------------------------------------------------------

class _StrideVolumeCard extends StatelessWidget {
  const _StrideVolumeCard({required this.period, required this.series});
  final _Period period;
  final _Series series;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final avg = series.days == 0 ? 0 : (series.total / series.days).round();
    return BentoCard(
      color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AeroIconTile(icon: Icons.bar_chart_rounded, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  period.volumeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              AeroBadge(series.trend, icon: Icons.trending_up_rounded, foreground: p.accentText),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fmtInt(series.total), style: AeroText.displayHeroMobile.copyWith(color: p.text)),
                const SizedBox(width: 6),
                Text('STEPS', style: AeroText.labelCaps.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Daily Avg: ', style: AeroText.bodyMd.copyWith(color: p.textMuted)),
              Flexible(
                child: Text(
                  fmtInt(avg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.metricSm.copyWith(color: p.accentText),
                ),
              ),
              Text(' /day', style: AeroText.caption.copyWith(color: p.textMuted)),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 170,
            child: _VolumeChart(key: ValueKey(period), series: series),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF2A221D) : AeroColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, size: 18, color: p.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    series.goalCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.caption.copyWith(color: p.text),
                  ),
                ),
                const SizedBox(width: 8),
                Text('TOP 4%', style: AeroText.labelCaps.copyWith(color: p.accentText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatefulWidget {
  const _VolumeChart({super.key, required this.series});
  final _Series series;

  @override
  State<_VolumeChart> createState() => _VolumeChartState();
}

class _VolumeChartState extends State<_VolumeChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final values = widget.series.values;
    final labels = widget.series.labels;
    final n = values.length;
    final maxV = values.fold<int>(0, math.max);

    // Highlight the two strongest buckets (Stitch: Wed + Sat peaks).
    final ranked = List<int>.generate(n, (i) => i)..sort((x, y) => values[y].compareTo(values[x]));
    final peaks = maxV > 0 ? ranked.take(2).toSet() : <int>{};
    final selected = _selected ?? (maxV > 0 ? ranked.first : null);

    final barWidth = switch (n) { <= 4 => 34.0, <= 7 => 26.0, <= 8 => 22.0, _ => 14.0 };
    final restColor = p.isDark ? const Color(0xFF3A2A20) : const Color(0xFFFFDCC6).withValues(alpha: 0.75);
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.22;
    final tooltipBg = p.isDark ? Colors.white : AeroColors.charcoal;
    final tooltipFg = p.isDark ? AeroColors.charcoal : Colors.white;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            final spot = response?.spot;
            if (event.isInterestedForInteractions && spot != null && spot.touchedBarGroupIndex != _selected) {
              setState(() => _selected = spot.touchedBarGroupIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => tooltipBg,
            tooltipBorderRadius: BorderRadius.circular(99),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            tooltipMargin: 6,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            direction: TooltipDirection.top,
            getTooltipItem: (group, _, rod, _) =>
                BarTooltipItem(fmtCompact(rod.toY), AeroText.numeric(11, color: tooltipFg)),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                final hot = peaks.contains(i);
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    labels[i],
                    style: AeroText.labelCaps.copyWith(
                      fontSize: n > 8 ? 9.5 : 11,
                      color: hot ? p.accentText : p.textMuted,
                      fontWeight: hot ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: i == selected ? const [0] : const [],
              barRods: [
                BarChartRodData(
                  // Keep a visible stub for empty buckets so the rhythm reads.
                  toY: math.max(values[i].toDouble(), maxY * 0.04),
                  width: barWidth,
                  borderRadius: BorderRadius.circular(99),
                  color: peaks.contains(i) ? null : restColor,
                  gradient: peaks.contains(i)
                      ? const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AeroColors.tangerineDeep, AeroColors.tangerine],
                        )
                      : null,
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 380),
    );
  }
}

// ---------------------------------------------------------------------------
// Elevated Ground Tempo banner (offline vector stand-in for the Stitch photo)
// ---------------------------------------------------------------------------

class _TempoBanner extends StatelessWidget {
  const _TempoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _SunsetPainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AeroColors.charcoalWarm.withValues(alpha: 0.82),
                  AeroColors.charcoalWarm.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.nature_people_rounded, size: 15, color: AeroColors.skyCyan),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'OUTDOOR DYNAMICS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.labelCaps.copyWith(color: AeroColors.skyCyan, letterSpacing: 1.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Elevated Ground Tempo', style: AeroText.headlineMd.copyWith(color: Colors.white)),
                ),
                Text(
                  'Optimal stride symmetry recorded during Saturday sunset run.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Coastal sunset: warm sky, low sun, sea bands and a headland path.
class _SunsetPainter extends CustomPainter {
  const _SunsetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B3A2A), Color(0xFFE07A3F), Color(0xFFFFC08A)],
          stops: [0, 0.5, 0.62],
        ).createShader(rect),
    );
    final sun = Offset(w * 0.78, h * 0.55);
    canvas.drawCircle(
      sun,
      h * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFE2B8).withValues(alpha: 0.9), const Color(0x00FFC08A)],
        ).createShader(Rect.fromCircle(center: sun, radius: h * 0.5)),
    );
    canvas.drawCircle(sun, h * 0.12, Paint()..color = const Color(0xFFFFF1DC));
    // Sea
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.6, w, h * 0.4),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB8613A), Color(0xFF4A2A22)],
        ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4)),
    );
    final glint = Paint()
      ..color = const Color(0xFFFFE2B8).withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = h * (0.66 + i * 0.06);
      final half = w * (0.07 - i * 0.008);
      canvas.drawLine(Offset(sun.dx - half, y), Offset(sun.dx + half, y), glint);
    }
    // Headland
    final land = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.22, h * 0.42, w * 0.42, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.72, w * 0.56, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF2C1A14));
  }

  @override
  bool shouldRepaint(_SunsetPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Biometric telemetry row
// ---------------------------------------------------------------------------

class _CadenceCard extends StatelessWidget {
  const _CadenceCard({required this.cadence});
  final int cadence;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    const left = 50.4;
    return BentoCard(
      padding: const EdgeInsets.all(16),
      color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AeroIconTile(
                icon: Icons.sync_alt_rounded,
                size: 32,
                background: AeroColors.cyanFixed.withValues(alpha: p.isDark ? 0.18 : 0.6),
                foreground: p.cyan,
              ),
              const Spacer(),
              AeroBadge(
                'Live',
                background: p.isDark ? AeroColors.skyCyan.withValues(alpha: 0.18) : AeroColors.cyanFixed,
                foreground: p.isDark ? AeroColors.skyCyan : AeroColors.onCyanFixed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Cadence & Balance',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.caption.copyWith(color: p.textMuted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(cadence > 0 ? '$cadence' : '--', style: AeroText.metricLg.copyWith(color: p.text)),
                const SizedBox(width: 4),
                Text('SPM', style: AeroText.labelCaps.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('L ${left.toStringAsFixed(1)}%', style: AeroText.labelCaps.copyWith(color: p.cyan)),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'R ${(100 - left).toStringAsFixed(1)}%',
                    style: AeroText.labelCaps.copyWith(color: p.textMuted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  const Expanded(flex: 504, child: ColoredBox(color: AeroColors.skyCyan)),
                  const SizedBox(width: 2),
                  Expanded(flex: 496, child: ColoredBox(color: p.isDark ? AeroColors.telemetryCyan : AeroColors.cyanDeep)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Optimal Symmetry',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.caption.copyWith(color: p.cyan, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardioFitnessCard extends StatelessWidget {
  const _CardioFitnessCard();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final off = p.isDark ? p.track : AeroColors.surfaceContainer;
    return BentoCard(
      padding: const EdgeInsets.all(16),
      color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AeroIconTile(icon: Icons.monitor_heart_outlined, size: 32),
              const Spacer(),
              AeroBadge(
                'Est.',
                background: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
                foreground: p.isDark ? AeroColors.peachFixed : const Color(0xFF351000),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Cardio Fitness',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.caption.copyWith(color: p.textMuted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('48.2', style: AeroText.metricLg.copyWith(color: p.accentText)),
                const SizedBox(width: 4),
                Text('VO₂', style: AeroText.labelCaps.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'SUPERIOR TIER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.labelCaps.copyWith(color: p.accentText),
                ),
              ),
              Icon(Icons.verified_outlined, size: 16, color: p.accentText),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final (i, c) in [off, off, p.isDark ? const Color(0xFF5A3420) : AeroColors.peachFixed, AeroColors.tangerine].indexed) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: i == 3
                            ? [BoxShadow(color: AeroColors.tangerine.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Top 5% for Age',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Century Streak (dark #141416 card — title forced #FFFFFF, contrast fix)
// ---------------------------------------------------------------------------

class _CenturyStreakCard extends StatelessWidget {
  const _CenturyStreakCard({required this.streakDays, required this.goal});
  final int streakDays;
  final int goal;

  static const _tiers = [3, 7, 17, 30, 60, 100];

  @override
  Widget build(BuildContext context) {
    final next = _tiers.firstWhere((t) => t > streakDays, orElse: () => streakDays + 1);
    final level = _tiers.indexOf(next) + 1;
    final progress = next == 0 ? 0.0 : (streakDays / next).clamp(0.0, 1.0);
    final daysLeft = next - streakDays;
    final white70 = Colors.white.withValues(alpha: 0.72);

    return CharcoalCard(
      radius: 28,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AeroColors.tangerine.withValues(alpha: 0.28), AeroColors.tangerine.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AeroColors.tangerine,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x80FF7A2F), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'STREAK ACTIVE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.labelCaps.copyWith(color: AeroColors.peachFixed, letterSpacing: 1.2),
                      ),
                    ),
                    Text(
                      '$streakDays Days',
                      style: AeroText.metricSm.copyWith(color: AeroColors.tangerine),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // CONTRAST FIX: explicit #FFFFFF title on #141416.
                Text('Century Streak', style: AeroText.headlineMd.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$streakDays', style: AeroText.numeric(14, weight: FontWeight.w600)),
                      const TextSpan(text: ' consecutive days above '),
                      TextSpan(
                        text: '${fmtInt(goal)} steps',
                        style: const TextStyle(color: AeroColors.peachFixed, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '! Next reward unlocks in '),
                      TextSpan(
                        text: '$daysLeft day${daysLeft == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  style: AeroText.bodyMd.copyWith(color: white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Milestone Level $level: \'Apex Nomad\'',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.caption.copyWith(color: white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$streakDays/$next Days',
                      style: AeroText.numeric(12, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF303032),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: const LinearGradient(colors: [AeroColors.tangerineDeep, AeroColors.tangerine]),
                          boxShadow: [BoxShadow(color: AeroColors.tangerine.withValues(alpha: 0.7), blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Badge: Golden Pacesetter Tier II',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.caption.copyWith(color: AeroColors.peachFixedDim),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AeroPillButton(
                      label: 'Claim Perks',
                      trailingIcon: Icons.arrow_forward_rounded,
                      tone: AeroButtonTone.ghost,
                      height: 34,
                      onPressed: () => context.push(AeroRoutes.unlock),
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

class _ReadinessTile extends StatelessWidget {
  const _ReadinessTile();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      padding: const EdgeInsets.all(16),
      color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.75),
      onTap: () => context.push(AeroRoutes.coach),
      child: Row(
        children: [
          AeroIconTile(
            icon: Icons.hotel_class_rounded,
            size: 44,
            background: AeroColors.skyCyan.withValues(alpha: p.isDark ? 0.18 : 0.3),
            foreground: p.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '94%', style: AeroText.numeric(19, weight: FontWeight.w700)),
                      const TextSpan(text: ' Readiness'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.titleMd.copyWith(color: p.text),
                ),
                Text(
                  'Cardio load balanced. Ready for speed bursts.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}

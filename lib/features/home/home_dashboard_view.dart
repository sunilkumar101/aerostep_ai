import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/shell_state.dart';
import '../../core/state/activity_state.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'home_common.dart';

/// Home tab, sub-view 0: the "Walk today, shine tomorrow." dashboard
/// (Stitch `aerostep_ai_home_dashboard`). Body only — MainShell owns the
/// canvas and floating dock.
class HomeDashboardView extends ConsumerWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(activityProvider);
    final name = ref.watch(userProfileProvider.select((u) => u.name));
    return AeroScrollPage(
      children: [
        _Header(name: name),
        const _Headline(),
        const _SearchRow(),
        const SubViewSwitcher.home(),
        const _CategoryChips(),
        _StepHeroCard(a: a),
        _QuickBentoRow(a: a),
        _CoachCallout(a: a),
        const _IntervalWalkCard(),
      ],
    );
  }
}

// ───────────────────────────── Header ─────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Row(
      children: [
        const _ProAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'KINETIC OS • V2.4',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.labelCaps.copyWith(fontSize: 10, color: p.textMuted, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: p.cyan, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AeroText.titleMd.copyWith(color: p.text, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _Shadowed(
          child: AeroCircleButton(
            icon: Icons.watch_rounded,
            size: 44,
            tooltip: 'Watch & home-screen widgets',
            foreground: p.text,
            onPressed: () => context.push(AeroRoutes.widgets),
          ),
        ),
        const SizedBox(width: 6),
        const _Shadowed(child: ThemeToggleButton()),
        const SizedBox(width: 6),
        const _BellButton(),
      ],
    );
  }
}

class _Shadowed extends StatelessWidget {
  const _Shadowed({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: context.aero.cardShadow),
        child: child,
      );
}

/// Circular runner avatar with gradient ring and a tappable PRO pill that
/// opens the Unlock Pass screen.
class _ProAvatar extends StatelessWidget {
  const _ProAvatar();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Semantics(
      button: true,
      label: 'AeroStep Pro',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(AeroRoutes.unlock),
        child: SizedBox(
          width: 48,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [AeroColors.tangerine, AeroColors.skyCyan],
                  ),
                ),
                child: const HeroCrop(size: 44, focus: HeroCrop.faceLight),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: AeroColors.tangerineGradient,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: p.isDark ? AeroColors.espresso : Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'PRO',
                    style: AeroText.labelCaps.copyWith(fontSize: 8, color: Colors.white, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          _Shadowed(
            child: AeroCircleButton(
              icon: Icons.notifications_none_rounded,
              size: 44,
              tooltip: 'Notifications',
              foreground: p.text,
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(_snack("You're all caught up — Stride AI will nudge you here.")),
            ),
          ),
          Positioned(
            top: 9,
            right: 10,
            child: IgnorePointer(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AeroColors.tangerine,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.isDark ? AeroColors.espressoCard : Colors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

SnackBar _snack(String text) => SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, AeroFloatingBottomDock.clearance + 8),
    );

// ──────────────────────────── Headline ────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final base = AeroText.headlineLg.copyWith(color: p.text, fontWeight: FontWeight.w800, letterSpacing: -1);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Walk today,', style: base),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => LinearGradient(
                      colors: p.isDark
                          ? const [AeroColors.tangerine, AeroColors.tangerineLight]
                          : const [AeroColors.tangerineDeep, AeroColors.tangerine],
                    ).createShader(r),
                    child: Text('shine tomorrow.', style: base),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _BouncingArrow(),
        ],
      ),
    );
  }
}

class _BouncingArrow extends StatefulWidget {
  const _BouncingArrow();

  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
            child: child,
          ),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(painter: _CurvedArrowPainter(AeroColors.tangerine)),
          ),
        ),
      );
}

/// Hand-drawn curved accent arrow pointing down toward the hero card
/// (Stitch SVG path on a 64x64 viewbox).
class _CurvedArrowPainter extends CustomPainter {
  const _CurvedArrowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final curve = Path()
      ..moveTo(14 * s, 10 * s)
      ..cubicTo(26 * s, 8 * s, 48 * s, 18 * s, 44 * s, 42 * s);
    final head = Path()
      ..moveTo(34 * s, 38 * s)
      ..lineTo(44 * s, 43 * s)
      ..lineTo(49 * s, 32 * s);
    canvas
      ..drawPath(curve, paint)
      ..drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_CurvedArrowPainter old) => old.color != color;
}

// ─────────────────────────── Search row ───────────────────────────

class _SearchRow extends StatelessWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    void openCoach() => context.push(AeroRoutes.coach);
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), boxShadow: p.cardShadow),
            child: Material(
              color: p.card,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: openCoach,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search_rounded, size: 20, color: p.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ask Stride AI or search trails...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.bodyMd.copyWith(color: p.textMuted),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x40FF7A2F), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: AeroCircleButton(
            icon: Icons.tune_rounded,
            tooltip: 'Filters',
            background: AeroColors.tangerine,
            foreground: Colors.white,
            onPressed: openCoach,
          ),
        ),
        const SizedBox(width: 8),
        _Shadowed(
          child: AeroCircleButton(
            icon: Icons.mic_rounded,
            tooltip: 'Voice Stride Coach',
            onPressed: openCoach,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────── Category chips ─────────────────────────

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void dock(int i) => ref.read(dockIndexProvider.notifier).set(i);
    final chips = <Widget>[
      const AeroCategoryChip(label: 'Daily Steps', icon: Icons.local_fire_department_rounded, selected: true),
      AeroCategoryChip(label: 'Virtual Trails', icon: Icons.explore_outlined, onTap: () => dock(2)),
      AeroCategoryChip(label: 'Squads', icon: Icons.groups_outlined, onTap: () => dock(3)),
      AeroCategoryChip(
        label: 'Fast Walk',
        icon: Icons.directions_run_rounded,
        onTap: () => context.push(AeroRoutes.liveWalk),
      ),
      AeroCategoryChip(
        label: 'Hydration',
        icon: Icons.water_drop_outlined,
        onTap: () => context.push(AeroRoutes.coach),
      ),
      AeroCategoryChip(
        label: 'Cadence Drills',
        icon: Icons.speed_rounded,
        onTap: () => context.push(AeroRoutes.liveWalk),
      ),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}

// ─────────────────────────── Hero card ────────────────────────────

class _StepHeroCard extends ConsumerWidget {
  const _StepHeroCard({required this.a});
  final ActivitySnapshot a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final white80 = Colors.white.withValues(alpha: 0.8);
    return TangerineCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -80,
            bottom: -80,
            child: GlowBlob(size: 220, color: Colors.white.withValues(alpha: 0.22)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GlassBadge(
                      tint: Colors.black.withValues(alpha: 0.2),
                      leading: const PulsingDot(color: Colors.white, size: 6),
                      child: Text.rich(
                        TextSpan(children: [
                          numSpan('${a.percent}%', size: 11, color: Colors.white),
                          const TextSpan(text: ' COMPLETED'),
                        ]),
                        style: AeroText.labelCaps.copyWith(color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                    _GlassBadge(
                      tint: Colors.white.withValues(alpha: 0.25),
                      leading: const Icon(Icons.battery_saver_rounded, size: 14, color: Colors.white),
                      child: Text(
                        'Zero Drain • Anti-Shake',
                        style: AeroText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT COUNT',
                          style: AeroText.labelCaps.copyWith(color: white80, letterSpacing: 1.6),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fmtInt(a.steps),
                            style: AeroText.displayHeroMobile.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(children: [
                                const TextSpan(text: '/ '),
                                numSpan(fmtInt(a.goal), size: 15, weight: FontWeight.w500, color: Colors.white),
                                const TextSpan(text: ' steps'),
                              ]),
                              style: AeroText.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Streak: ${a.streakDays}d',
                                style: AeroText.numeric(11, color: Colors.white),
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
                    stroke: 8,
                    track: Colors.white.withValues(alpha: 0.25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${a.percent}%', style: AeroText.metricSm.copyWith(color: Colors.white)),
                        Text('GOAL', style: AeroText.labelCaps.copyWith(fontSize: 9, color: white80)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(child: _SubStat(label: 'Distance', value: a.distanceKm.toStringAsFixed(1), unit: 'km')),
                    Expanded(child: _SubStat(label: 'Active Time', value: '${a.activeMinutes}', unit: 'min')),
                    Expanded(child: _SubStat(label: 'Burned', value: fmtInt(a.kcal), unit: 'kcal')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.directions_walk_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        numSpan('${a.cadenceSpm}', size: 12, weight: FontWeight.w600, color: Colors.white),
                        TextSpan(text: ' spm ${_cadenceLabel(a.cadenceSpm)}'),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: const Color(0x33000000),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => ref.read(homeSubViewProvider.notifier).set(1),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AeroColors.tangerine,
                          semanticLabel: 'View activity breakdown',
                        ),
                      ),
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

  static String _cadenceLabel(int spm) {
    if (spm >= 100) return 'Brisk Cadence • Stable';
    if (spm > 0) return 'Easy Cadence • Steady';
    return 'Cadence idle • Ready';
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.tint, required this.leading, required this.child});
  final Color tint;
  final Widget leading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [leading, const SizedBox(width: 4), Flexible(child: child)],
        ),
      );
}

class _SubStat extends StatelessWidget {
  const _SubStat({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: value, style: AeroText.metricSm.copyWith(color: Colors.white)),
                TextSpan(
                  text: ' $unit',
                  style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                ),
              ]),
            ),
          ),
        ],
      );
}

// ────────────────────────── Bento row ────────────────────────────

class _QuickBentoRow extends StatelessWidget {
  const _QuickBentoRow({required this.a});
  final ActivitySnapshot a;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final cyanBg = p.isDark ? AeroColors.skyCyan.withValues(alpha: 0.16) : AeroColors.cyanFixed;
    final cyanFg = p.isDark ? AeroColors.skyCyan : AeroColors.onCyanFixed;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AeroIconTile(icon: Icons.bolt_rounded),
                      const SizedBox(width: 8),
                      Flexible(child: AeroBadge('+12%', background: cyanBg, foreground: cyanFg)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Active Burn', style: AeroText.caption.copyWith(color: p.textMuted)),
                  const SizedBox(height: 2),
                  _MetricLine(value: fmtInt(a.kcal), unit: 'kcal'),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Metabolic zone sustained for '),
                      numSpan('${a.activeMinutes}', size: 11, weight: FontWeight.w600, color: p.textMuted),
                      const TextSpan(text: ' mins'),
                    ]),
                    style: AeroText.caption.copyWith(fontSize: 11, color: p.textMuted),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AeroIconTile(
                        icon: Icons.monitor_heart_rounded,
                        background: cyanBg,
                        foreground: p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(child: AeroBadge('Balanced')),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: 12),
                  Text('Average Pace', style: AeroText.caption.copyWith(color: p.textMuted)),
                  const SizedBox(height: 2),
                  _MetricLine(value: a.avgPaceKmh.toStringAsFixed(1), unit: 'km/h'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('L 50.1%', style: AeroText.numeric(11, weight: FontWeight.w600, color: p.accentText)),
                      Text('•', style: AeroText.caption.copyWith(fontSize: 10, color: p.textMuted)),
                      Text('R 49.9%', style: AeroText.numeric(11, weight: FontWeight.w600, color: p.cyan)),
                    ],
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

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.value, required this.unit});
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: value, style: AeroText.numeric(22, color: p.text)),
          TextSpan(text: ' $unit', style: AeroText.caption.copyWith(color: p.textMuted)),
        ]),
      ),
    );
  }
}

// ──────────────────────── Coach callout ─────────────────────────

class _CoachCallout extends StatelessWidget {
  const _CoachCallout({required this.a});
  final ActivitySnapshot a;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final br = BorderRadius.circular(28);
    final body = AeroText.bodyMd.copyWith(color: p.text, height: 1.4);
    final strong = AeroText.numeric(14, color: p.accentText);
    final List<InlineSpan> message;
    if (a.steps == 0) {
      message = [
        const TextSpan(text: 'Ready when you are! '),
        TextSpan(text: '${fmtInt(a.goal)} steps', style: strong),
        const TextSpan(text: " stand between you and today's gold streak."),
      ];
    } else if (a.remaining > 0) {
      message = [
        const TextSpan(text: 'Your cadence is optimal for fat oxidation! Just '),
        TextSpan(text: '${fmtInt(a.remaining)} steps', style: strong),
        const TextSpan(text: ' remaining to lock in your daily gold streak.'),
      ];
    } else {
      message = [
        const TextSpan(text: 'Gold streak locked in with '),
        TextSpan(text: '${fmtInt(a.steps)} steps', style: strong),
        const TextSpan(text: '! A gentle cooldown stroll now boosts recovery.'),
      ];
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          colors: p.isDark
              ? const [AeroColors.espressoCard, Color(0xFF2E2019)]
              : const [Colors.white, Color(0xFFFFF1E8)],
        ),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: () => context.push(AeroRoutes.coach),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AeroColors.tangerine,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Color(0x40FF7A2F), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 22, color: Colors.white),
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
                              'STRIDE AI COACH',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AeroText.labelCaps.copyWith(color: p.accentText, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AeroColors.tangerine, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('Real-time', style: AeroText.caption.copyWith(fontSize: 11, color: p.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: message), style: body),
                    ],
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

// ───────────────────── Interval walk widget ─────────────────────

class _IntervalWalkCard extends StatelessWidget {
  const _IntervalWalkCard();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    void start() => context.push(AeroRoutes.liveWalk);
    return BentoCard(
      padding: const EdgeInsets.all(16),
      onTap: start,
      child: Row(
        children: [
          HeroCrop(
            size: 48,
            dark: p.isDark,
            focus: p.isDark ? HeroCrop.shoeDark : HeroCrop.shoeLight,
            cropWidth: 0.32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sunset Interval Walk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.titleMd.copyWith(fontSize: 15, color: p.text),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Suggested AI Playlist • '),
                    numSpan('20', size: 12, weight: FontWeight.w500, color: p.textMuted),
                    const TextSpan(text: ' mins'),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AeroPillButton(
            label: 'START',
            icon: Icons.play_arrow_rounded,
            tone: AeroButtonTone.charcoal,
            height: 40,
            onPressed: start,
          ),
        ],
      ),
    );
  }
}

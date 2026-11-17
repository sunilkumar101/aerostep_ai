import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/state/activity_state.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'coach_brain.dart';
import 'coach_chat.dart';

/// "Weight-Loss & Hydration" tab of the AI Coach Hub
/// (Stitch `aerostep_ai_ai_coach_weight_loss_hub`).
class WeightLossHubView extends ConsumerWidget {
  const WeightLossHubView({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onSpeakInsight,
  });

  final CoachInputMode mode;
  final ValueChanged<CoachInputMode> onModeChanged;

  /// Posts the hero insight into the coach conversation.
  final VoidCallback onSpeakInsight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        _ModeRow(mode: mode, onChanged: onModeChanged),
        const SizedBox(height: 12),
        _InsightHeroCard(onSpeak: onSpeakInsight),
        const SizedBox(height: 12),
        const _HydrationCard(),
        const SizedBox(height: 12),
        const _MealSnapCard(),
        const SizedBox(height: 12),
        const _StreakShieldCard(),
        const SizedBox(height: 12),
        const _MetabolicDeficitCard(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mode row
// ---------------------------------------------------------------------------

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.mode, required this.onChanged});
  final CoachInputMode mode;
  final ValueChanged<CoachInputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    Widget pill(CoachInputMode m, IconData icon, String label) {
      final on = m == mode;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: on ? (p.isDark ? AeroColors.tangerine : AeroColors.tangerineDeep) : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: on ? Colors.white : p.textMuted),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AeroText.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(99)),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'STRIDE AI LIVE • ACTIVE SYNC',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.labelCaps.copyWith(color: p.textMuted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: p.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pill(CoachInputMode.voice, Icons.mic_rounded, 'Voice'),
              pill(CoachInputMode.chat, Icons.chat_bubble_outline_rounded, 'Chat'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero insight
// ---------------------------------------------------------------------------

class _InsightHeroCard extends ConsumerWidget {
  const _InsightHeroCard({required this.onSpeak});
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(activityProvider);
    final weight = ref.watch(userProfileProvider.select((u) => u.weightKg));
    final done = a.remaining == 0;
    final mins = done ? 10 : minutesForSteps(a.remaining, a.cadenceSpm);
    final kcal = kcalForSteps(done ? 1100 : a.remaining, weightKg: weight);
    final quoteStyle = AeroText.headlineMd.copyWith(color: Colors.white, height: 1.3);
    final emphasis = quoteStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withValues(alpha: 0.7),
      decorationThickness: 2,
    );

    return TangerineCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: IgnorePointer(
              child: Icon(Icons.star_rounded, size: 180, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REAL-TIME INSIGHT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.labelCaps.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                          Text(
                            'Stride Intelligence',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.titleMd.copyWith(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.headphones_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Voice Coach $mins:00 min',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.numeric(11, weight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text.rich(
                  done
                      ? TextSpan(
                          style: quoteStyle,
                          children: [
                            const TextSpan(text: '"Goal smashed! '),
                            TextSpan(text: '${groupDigits(a.steps)} steps', style: emphasis),
                            TextSpan(
                              text: ' today. A $mins-minute cool-down stroll adds ~$kcal kcal to your deficit."',
                            ),
                          ],
                        )
                      : TextSpan(
                          style: quoteStyle,
                          children: [
                            const TextSpan(text: '"You are '),
                            TextSpan(text: '${groupDigits(a.remaining)} steps', style: emphasis),
                            TextSpan(
                              text: ' away from your ${compactGoal(a.goal)} goal! A $mins-minute evening '
                                  'stroll locks in a $kcal kcal deficit."',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AeroPillButton(
                        label: 'Start Evening Stride',
                        trailingIcon: Icons.arrow_forward_rounded,
                        tone: AeroButtonTone.white,
                        expand: true,
                        onPressed: () => context.push(AeroRoutes.liveWalk),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AeroCircleButton(
                      icon: Icons.volume_up_rounded,
                      tooltip: 'Read insight in chat',
                      onPressed: onSpeak,
                      size: 52,
                      background: Colors.white.withValues(alpha: 0.22),
                      foreground: Colors.white,
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

// ---------------------------------------------------------------------------
// Hydration (liquid cylinder)
// ---------------------------------------------------------------------------

class _HydrationCard extends ConsumerStatefulWidget {
  const _HydrationCard();

  @override
  ConsumerState<_HydrationCard> createState() => _HydrationCardState();
}

class _HydrationCardState extends ConsumerState<_HydrationCard> {
  bool _added = false;
  Timer? _toast;

  @override
  void dispose() {
    _toast?.cancel();
    super.dispose();
  }

  void _add() {
    ref.read(hydrationProvider.notifier).add(250);
    _toast?.cancel();
    setState(() => _added = true);
    _toast = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final h = ref.watch(hydrationProvider);
    final goalL = h.goalMl / 1000;
    final pct = (h.progress * 100).round();
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AeroIconTile(
                icon: Icons.water_drop_rounded,
                background: p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed,
                foreground: p.cyan,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Hydration', style: AeroText.titleMd.copyWith(color: p.text))),
              AeroBadge(
                '$pct% goal',
                background: p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed,
                foreground: p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(h.litres, style: AeroText.metricLg.copyWith(color: p.text)),
              const SizedBox(width: 4),
              Text('/ ${goalL.toStringAsFixed(1)} L', style: AeroText.numeric(16, weight: FontWeight.w500, color: p.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 15, color: p.cyan),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Hydration speeds fat oxidation by +18%',
                  style: AeroText.caption.copyWith(color: p.cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: _LiquidCylinder(
              level: h.progress,
              maxLabel: '${goalL.toStringAsFixed(1)}L Max',
              midLabel: '${(goalL / 2).toStringAsFixed(2)}L Mid',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SolidPill(
                  label: 'Tap +250ml',
                  icon: Icons.add_rounded,
                  background: p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep,
                  foreground: p.isDark ? AeroColors.onCyanFixed : Colors.white,
                  onTap: _add,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedOpacity(
                opacity: _added ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: Text('Added!', style: AeroText.caption.copyWith(color: p.cyan, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidCylinder extends StatefulWidget {
  const _LiquidCylinder({required this.level, required this.maxLabel, required this.midLabel});
  final double level;
  final String maxLabel;
  final String midLabel;

  @override
  State<_LiquidCylinder> createState() => _LiquidCylinderState();
}

class _LiquidCylinderState extends State<_LiquidCylinder> with SingleTickerProviderStateMixin {
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final labelStyle = AeroText.numeric(10, weight: FontWeight.w600, color: p.textMuted.withValues(alpha: 0.8));
    return Semantics(
      label: 'Hydration level ${(widget.level * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.level),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, level, _) => AnimatedBuilder(
            animation: _wave,
            builder: (context, _) => CustomPaint(
              painter: _LiquidPainter(
                level: level,
                phase: _wave.value * 2 * math.pi,
                track: p.isDark ? const Color(0xFF1A2A30) : const Color(0xFFEFF7FA),
              ),
              child: Stack(
                children: [
                  Positioned(top: 10, right: 12, child: Text(widget.maxLabel, style: labelStyle)),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 12,
                    child: Center(child: Text(widget.midLabel, style: labelStyle)),
                  ),
                  Positioned(bottom: 10, right: 12, child: Text('0.0L', style: labelStyle)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({required this.level, required this.phase, required this.track});
  final double level;
  final double phase;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    // Graduation lines.
    final grid = Paint()
      ..color = AeroColors.cyanDeep.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (level <= 0) return;

    final surface = size.height * (1 - level.clamp(0.0, 1.0));
    final amp = level >= 1 ? 2.0 : 5.0;

    Path wave(double shift, double amplitude) {
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final y = surface + math.sin(x / size.width * 2 * math.pi * 1.4 + phase + shift) * amplitude;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      return path;
    }

    // Back wave.
    canvas.drawPath(wave(math.pi, amp * 0.8), Paint()..color = AeroColors.skyCyan.withValues(alpha: 0.35));
    // Front wave with depth gradient.
    final rect = Rect.fromLTWH(0, surface - amp, size.width, size.height - surface + amp);
    canvas.drawPath(
      wave(0, amp),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AeroColors.skyCyan, AeroColors.telemetryCyan, AeroColors.cyanDeep],
          stops: [0, 0.45, 1],
        ).createShader(rect),
    );
    // Bubble dots.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (double y = surface + 14; y < size.height - 4; y += 12) {
      for (double x = 10; x < size.width - 4; x += 14) {
        final r = 0.9 + 0.5 * math.sin(x * 0.7 + y * 0.3 + phase);
        canvas.drawCircle(Offset(x, y), r, dot);
      }
    }
    // Highlight sheen.
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.06, surface + 6, 6, math.max(0, size.height - surface - 14)),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_LiquidPainter old) => old.level != level || old.phase != phase || old.track != track;
}

// ---------------------------------------------------------------------------
// AI Meal Snap
// ---------------------------------------------------------------------------

class _MealSnapCard extends StatelessWidget {
  const _MealSnapCard();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    // Meal logging is not wired yet: demo builds show the Stitch sample meal.
    const demo = kAeroDemoMode;
    const kcal = demo ? 1420 : 0;
    const target = 2100;
    final macros = demo ? const ['P: 84g', 'C: 160g', 'F: 42g'] : const ['P: 0g', 'C: 0g', 'F: 0g'];
    final deep = p.isDark ? AeroColors.tangerine : AeroColors.tangerineDeep;
    return BentoCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: p.isDark
            ? const [Color(0xFF2E1F16), AeroColors.espressoCard]
            : [AeroColors.peachFixed.withValues(alpha: 0.75), const Color(0xFFFFF4EC)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AeroIconTile(
                icon: Icons.photo_camera_rounded,
                background: AeroColors.tangerine,
                foreground: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Meal Snap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.titleMd.copyWith(color: p.text),
                ),
              ),
              Flexible(
                child: AeroBadge(
                  demo ? 'Balanced Lunch ✓' : 'No meals yet',
                  caps: false,
                  background: p.isDark ? const Color(0xFF3A2416) : Colors.white.withValues(alpha: 0.7),
                  foreground: deep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              Text(groupDigits(kcal), style: AeroText.metricLg.copyWith(color: deep)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${groupDigits(target)} kcal target',
                  style: AeroText.numeric(14, weight: FontWeight.w500, color: p.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in macros)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(m, style: AeroText.numeric(12, weight: FontWeight.w600, color: p.text)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFB6D97A), Color(0xFF6E9B3A), Color(0xFFE08A3C)],
                    stops: [0.2, 0.6, 1],
                  ),
                  boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: const Icon(Icons.rice_bowl_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SolidPill(
                  label: '+ Snap Dinner',
                  icon: Icons.add_a_photo_rounded,
                  background: deep,
                  foreground: Colors.white,
                  onTap: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('AI Meal Snap camera is coming soon — log meals by asking the coach for now.')),
                    ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak Shield
// ---------------------------------------------------------------------------

class _StreakShieldCard extends ConsumerStatefulWidget {
  const _StreakShieldCard();

  @override
  ConsumerState<_StreakShieldCard> createState() => _StreakShieldCardState();
}

class _StreakShieldCardState extends ConsumerState<_StreakShieldCard> {
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    final shields = ref.watch(streakShieldProvider);
    final white70 = Colors.white.withValues(alpha: 0.7);
    return CharcoalCard(
      onTap: () => context.push(AeroRoutes.unlock),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AeroColors.tangerine.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: AeroColors.peachFixed, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak Shield', style: AeroText.titleMd.copyWith(color: Colors.white)),
                    Text('Automatic Rest Day Guard', style: AeroText.caption.copyWith(color: white70)),
                  ],
                ),
              ),
              AeroBadge(
                'Level 4',
                background: Colors.white.withValues(alpha: 0.1),
                foreground: AeroColors.peachFixed,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$shields Rest ${shields == 1 ? 'Day' : 'Days'} Available',
            style: AeroText.titleMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-deploys if cadence drops under 5k steps during rest or illness.',
            style: AeroText.bodyMd.copyWith(color: white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _active ? AeroColors.skyCyan : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _active ? 'Shield Active' : 'Shield Paused',
                  style: AeroText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              Text('Get more', style: AeroText.caption.copyWith(color: AeroColors.peachFixed)),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AeroColors.peachFixed),
              const SizedBox(width: 4),
              Switch(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeThumbColor: Colors.white,
                activeTrackColor: AeroColors.cyanDeep,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metabolic deficit
// ---------------------------------------------------------------------------

class _MetabolicDeficitCard extends ConsumerWidget {
  const _MetabolicDeficitCard();

  static const _target = 500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.aero;
    final a = ref.watch(activityProvider);
    final weight = ref.watch(userProfileProvider.select((u) => u.weightKg));
    final deficit = kAeroDemoMode ? 420 : a.kcal;
    final now = DateTime.now();
    final dayFraction = ((now.hour + now.minute / 60 - 7) / 15).clamp(0.0, 1.0);
    final expected = (_target * dayFraction).round();
    final diff = kAeroDemoMode ? 110 : deficit - expected;
    final progress = (deficit / _target).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final walkSteps = 15 * kBriskCadenceSpm;
    final deep = p.isDark ? AeroColors.tangerine : AeroColors.tangerineDeep;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AeroIconTile(icon: Icons.trending_down_rounded, foreground: deep),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Metabolic Deficit Today', style: AeroText.titleMd.copyWith(color: p.text, fontSize: 16)),
                    Text(
                      diff >= 0 ? 'Ahead of schedule by $diff kcal' : 'Behind by ${-diff} kcal — a short walk catches up',
                      style: AeroText.caption.copyWith(color: deep),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('-${groupDigits(deficit)}', style: AeroText.metricLg.copyWith(color: AeroColors.tangerine)),
                  Text('KCAL NET', style: AeroText.labelCaps.copyWith(color: p.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily Deficit Progress ($pct%)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ),
              Text(
                '${groupDigits(deficit)} / $_target kcal',
                style: AeroText.numeric(12, weight: FontWeight.w700, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: p.track),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AeroColors.tangerineDeep, AeroColors.tangerine]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.isDark ? Colors.white.withValues(alpha: 0.04) : AeroColors.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.isDark ? Colors.white.withValues(alpha: 0.06) : AeroColors.surfaceHigh),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
                  child: Icon(Icons.directions_walk_rounded, color: deep, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post-Dinner 15-min Cadence Walk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.bodyMd.copyWith(color: p.text, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '+${groupDigits(walkSteps)} steps • Burns ~${kcalForSteps(walkSteps, weightKg: weight)} kcal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => context.push(AeroRoutes.liveWalk),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Text(
                        'Launch',
                        style: AeroText.caption.copyWith(color: deep, fontWeight: FontWeight.w800),
                      ),
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

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

class _SolidPill extends StatelessWidget {
  const _SolidPill({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.bodyMd.copyWith(color: foreground, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

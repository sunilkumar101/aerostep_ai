import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';

/// "Gait & Audio Drills" tab of the AI Coach Hub
/// (Stitch `aerostep_ai_stride_ai_coach`).
class StrideCoachView extends StatelessWidget {
  const StrideCoachView({super.key, required this.active});

  /// False while the tab is hidden; stops the metronome.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const _IntelligenceHeroCard(),
        const SizedBox(height: 12),
        const _GaitMatrixCard(),
        const SizedBox(height: 12),
        _CadenceDrillCard(active: active),
        const SizedBox(height: 12),
        const _HydrationWindowCard(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stride Intelligence hero
// ---------------------------------------------------------------------------

class _IntelligenceHeroCard extends StatelessWidget {
  const _IntelligenceHeroCard();

  @override
  Widget build(BuildContext context) {
    final white85 = Colors.white.withValues(alpha: 0.88);
    return TangerineCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -40,
            child: IgnorePointer(
              child: Text(
                '*',
                style: AeroText.numeric(200, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                            const PulsingDot(size: 7),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'LIVE NEURAL SYNC',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.labelCaps.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.monitor_heart_outlined, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'AeroStep Stride Intelligence™',
                  style: AeroText.headlineLgMobile.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time biomechanical telemetry & conversational coaching.',
                  style: AeroText.bodyLg.copyWith(color: white85),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sensors_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Sensors Calibrated: 120Hz Gyro + GPS',
                          style: AeroText.numeric(12, weight: FontWeight.w600, color: Colors.white),
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

// ---------------------------------------------------------------------------
// Dynamic Gait Matrix
// ---------------------------------------------------------------------------

class _GaitMatrixCard extends StatelessWidget {
  const _GaitMatrixCard();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final deep = p.isDark ? AeroColors.tangerine : AeroColors.tangerineDeep;
    final boxColor = p.isDark ? Colors.white.withValues(alpha: 0.04) : AeroColors.surfaceLow;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AeroIconTile(icon: Icons.accessibility_new_rounded, foreground: deep),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dynamic Gait Matrix', style: AeroText.titleMd.copyWith(color: p.text)),
                    Text(
                      'Kinematic kinetic strike analysis',
                      style: AeroText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AeroBadge(
                '98.4% accuracy',
                background: p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed,
                foreground: p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(20)),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(8, 34, 8, 8),
                            child: _PressureSole(),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 8,
                          right: 8,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _StrikeChip(label: '72% Forefoot', color: AeroColors.tangerine, fg: Colors.white),
                              _StrikeChip(label: '28% Heel', color: AeroColors.skyCyan, fg: AeroColors.onCyanFixed),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _MetricBox(
                          label: 'Cadence Tempo',
                          value: '164',
                          unit: 'SPM',
                          color: boxColor,
                          valueColor: p.text,
                          unitColor: deep,
                          footer: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: 0.78,
                              minHeight: 6,
                              color: AeroColors.tangerine,
                              backgroundColor: p.track,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _MetricBox(
                          label: 'Pronation Velocity',
                          value: '+4.2',
                          unit: 'DEG/S',
                          color: boxColor,
                          valueColor: p.cyan,
                          unitColor: p.cyan,
                          footer: Text(
                            'Neutral Deviation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.caption.copyWith(color: p.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF2E1F16) : const Color(0xFFFFF0E7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AeroColors.tangerine.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: deep, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biomechanics Adjustment', style: AeroText.titleMd.copyWith(color: p.text, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          style: AeroText.bodyMd.copyWith(color: p.textMuted),
                          children: [
                            const TextSpan(text: 'Forefoot impact detected. Adjust stride angle by '),
                            TextSpan(
                              text: '3° rearward',
                              style: TextStyle(color: deep, fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(text: ' to relieve localized knee joint shear.'),
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
    );
  }
}

class _StrikeChip extends StatelessWidget {
  const _StrikeChip({required this.label, required this.color, required this.fg});
  final String label;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label, style: AeroText.numeric(10, weight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      );
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.valueColor,
    required this.unitColor,
    required this.footer,
  });
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color valueColor;
  final Color unitColor;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AeroText.metricLg.copyWith(color: valueColor)),
                const SizedBox(width: 4),
                Text(unit, style: AeroText.labelCaps.copyWith(color: unitColor)),
              ],
            ),
          ),
          footer,
        ],
      ),
    );
  }
}

/// Foot-sole pressure heat map (forefoot pulse animated).
class _PressureSole extends StatefulWidget {
  const _PressureSole();

  @override
  State<_PressureSole> createState() => _PressureSoleState();
}

class _PressureSoleState extends State<_PressureSole> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Semantics(
      label: 'Foot pressure map: 72 percent forefoot, 28 percent heel',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _SolePainter(
            pulse: Curves.easeInOut.transform(_pulse.value),
            dark: p.isDark,
          ),
        ),
      ),
    );
  }
}

class _SolePainter extends CustomPainter {
  _SolePainter({required this.pulse, required this.dark});
  final double pulse;
  final bool dark;

  static const _vbW = 100.0;
  static const _vbH = 190.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vbW, size.height / _vbH);
    final dx = (size.width - _vbW * s) / 2;
    final dy = (size.height - _vbH * s) / 2;
    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(s);

    final sole = Path()
      ..moveTo(50, 8)
      ..cubicTo(65, 8, 78, 20, 80, 40)
      ..cubicTo(82, 60, 76, 85, 78, 115)
      ..cubicTo(80, 145, 74, 175, 52, 184)
      ..cubicTo(32, 184, 24, 165, 24, 140)
      ..cubicTo(24, 110, 20, 90, 24, 60)
      ..cubicTo(28, 30, 35, 8, 50, 8)
      ..close();

    // Soft drop shadow.
    canvas.drawShadow(sole, Colors.black.withValues(alpha: 0.4), 3, false);
    canvas.drawPath(sole, Paint()..color = dark ? const Color(0xFF2C241F) : const Color(0xFFF0EDEF));

    canvas
      ..save()
      ..clipPath(sole);

    // Global heat wash: warm forefoot -> cool heel.
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _vbW, _vbH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AeroColors.tangerine.withValues(alpha: 0.16),
            Colors.transparent,
            AeroColors.skyCyan.withValues(alpha: 0.16),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, _vbW, _vbH)),
    );

    void heat(Offset c, double r, List<Color> colors, {double sx = 1, double sy = 1}) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..scale(sx, sy);
      final rect = Rect.fromCircle(center: Offset.zero, radius: r);
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()..shader = RadialGradient(colors: colors).createShader(rect),
      );
      canvas.restore();
    }

    // Forefoot strike (tangerine, pulsing).
    final fr = 24 + 3 * pulse;
    heat(const Offset(51, 47), fr, [
      AeroColors.tangerineDeep,
      AeroColors.tangerine.withValues(alpha: 0.9),
      AeroColors.tangerine.withValues(alpha: 0.35),
      AeroColors.tangerine.withValues(alpha: 0),
    ], sy: 0.8);
    heat(const Offset(63, 47), 6, [AeroColors.tangerine, AeroColors.tangerine.withValues(alpha: 0)]);

    // Midfoot arch (neutral).
    heat(const Offset(44, 105), 12, [
      (dark ? Colors.white : AeroColors.outline).withValues(alpha: 0.22),
      Colors.transparent,
    ], sx: 0.6);

    // Heel (cyan).
    heat(const Offset(50, 155), 20, [
      AeroColors.cyanDeep,
      AeroColors.skyCyan.withValues(alpha: 0.7),
      AeroColors.skyCyan.withValues(alpha: 0),
    ]);

    // Toes.
    final toe = Paint()..color = AeroColors.skyCyan.withValues(alpha: 0.75);
    canvas
      ..drawCircle(const Offset(34, 22), 3.5, toe)
      ..drawCircle(const Offset(44, 17), 3.5, toe)
      ..drawCircle(const Offset(54, 16), 3.5, toe)
      ..drawCircle(const Offset(64, 19), 3, toe..color = AeroColors.skyCyan.withValues(alpha: 0.5))
      ..drawCircle(const Offset(72, 25), 2.5, Paint()..color = AeroColors.outlineVariant);
    canvas.restore();

    canvas.drawPath(
      sole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = dark ? Colors.white.withValues(alpha: 0.14) : AeroColors.outlineVariant,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SolePainter old) => old.pulse != pulse || old.dark != dark;
}

// ---------------------------------------------------------------------------
// Interval Cadence Drill (metronome)
// ---------------------------------------------------------------------------

class _CadenceDrillCard extends StatefulWidget {
  const _CadenceDrillCard({required this.active});
  final bool active;

  @override
  State<_CadenceDrillCard> createState() => _CadenceDrillCardState();
}

class _CadenceDrillCardState extends State<_CadenceDrillCard> with SingleTickerProviderStateMixin {
  static const _minBpm = 100;
  static const _maxBpm = 200;

  /// Running stride (m) used to translate BPM into target pace.
  static const _strideM = 1.118;

  int _bpm = 172;
  bool _playing = false;
  int _beat = 0;
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void initState() {
    super.initState();
    // Stop the metronome when the app is backgrounded.
    _lifecycle = AppLifecycleListener(onHide: _stop);
  }

  @override
  void didUpdateWidget(_CadenceDrillCard old) {
    super.didUpdateWidget(old);
    if (!widget.active && _playing) _stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Duration get _interval => Duration(microseconds: (60000000 / _bpm).round());

  void _tick() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _beat++);
    _pulse.forward(from: 0);
  }

  void _start() {
    _timer?.cancel();
    _tick();
    _timer = Timer.periodic(_interval, (_) => _tick());
    setState(() => _playing = true);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted && _playing) setState(() => _playing = false);
  }

  void _setBpm(int bpm) {
    final v = bpm.clamp(_minBpm, _maxBpm);
    if (v == _bpm) return;
    setState(() => _bpm = v);
    if (_playing) {
      _timer?.cancel();
      _timer = Timer.periodic(_interval, (_) => _tick());
    }
  }

  String get _pace {
    final secPerKm = (1000 / (_bpm * _strideM / 60)).round();
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final playBg = _playing ? (p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep) : AeroColors.tangerine;
    final playFg = _playing && p.isDark ? AeroColors.onCyanFixed : Colors.white;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AeroIconTile(
                icon: Icons.graphic_eq_rounded,
                background: p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed,
                foreground: p.cyan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interval Cadence Drill', style: AeroText.titleMd.copyWith(color: p.text)),
                    Text(
                      'Audio Pacing Coach • 15 Mins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AeroCircleButton(
                icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                tooltip: _playing ? 'Pause metronome' : 'Play metronome',
                onPressed: _playing ? _stop : _start,
                size: 48,
                background: playBg,
                foreground: playFg,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: p.isDark ? Colors.white.withValues(alpha: 0.04) : AeroColors.surfaceLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => _BeatBars(
                        beat: _beat,
                        pulse: _playing ? 1 - Curves.easeOut.transform(_pulse.value) : 0,
                        playing: _playing,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$_bpm', style: AeroText.numeric(24, color: p.text)),
                        const SizedBox(width: 3),
                        Text('BPM', style: AeroText.labelCaps.copyWith(color: p.accentText)),
                      ],
                    ),
                    Text(
                      _playing ? 'Beat ${_beat % 4 + 1} / 4' : 'Harmonic Sync',
                      style: AeroText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AeroCircleButton(
                icon: Icons.remove_rounded,
                tooltip: 'Slower',
                size: 40,
                background: p.chip,
                foreground: p.text,
                onPressed: _bpm > _minBpm ? () => _setBpm(_bpm - 2) : null,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AeroColors.tangerine,
                    inactiveTrackColor: p.track,
                    thumbColor: AeroColors.tangerine,
                    overlayColor: AeroColors.tangerine.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _bpm.toDouble(),
                    min: _minBpm.toDouble(),
                    max: _maxBpm.toDouble(),
                    divisions: (_maxBpm - _minBpm) ~/ 2,
                    label: '$_bpm BPM',
                    onChanged: (v) => _setBpm(v.round()),
                  ),
                ),
              ),
              AeroCircleButton(
                icon: Icons.add_rounded,
                tooltip: 'Faster',
                size: 40,
                background: p.chip,
                foreground: p.text,
                onPressed: _bpm < _maxBpm ? () => _setBpm(_bpm + 2) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headphones_rounded, size: 16, color: p.textMuted),
                  const SizedBox(width: 4),
                  Text('Spatial Metronome', style: AeroText.caption.copyWith(color: p.textMuted)),
                ],
              ),
              Text(
                'Targets $_pace /km Pace',
                style: AeroText.numeric(12, weight: FontWeight.w600, color: p.cyan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BeatBars extends StatelessWidget {
  const _BeatBars({required this.beat, required this.pulse, required this.playing});
  final int beat;
  final double pulse;
  final bool playing;

  static const _base = [0.35, 0.6, 0.45, 0.8, 0.5, 0.95, 0.7, 0.95, 0.5, 0.8, 0.45, 0.6, 0.35];

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final colors = [AeroColors.tangerine, p.cyan, AeroColors.skyCyan];
    final focus = beat % _base.length;
    return LayoutBuilder(
      builder: (context, c) {
        final n = _base.length;
        final barW = math.max(2.0, math.min(5.0, c.maxWidth / (n * 2)));
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < n; i++)
              Builder(
                builder: (_) {
                  final dist = (i - focus).abs();
                  final boost = playing ? pulse * math.max(0, 1 - dist / 3) * 0.6 + pulse * 0.15 : 0.0;
                  final h = (c.maxHeight * (_base[i] * (playing ? 0.75 : 0.6) + boost)).clamp(4.0, c.maxHeight);
                  return Container(
                    width: barW,
                    height: h,
                    decoration: BoxDecoration(
                      color: colors[i % 3].withValues(alpha: playing ? 1 : 0.7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hydration Window
// ---------------------------------------------------------------------------

class _HydrationWindowCard extends ConsumerStatefulWidget {
  const _HydrationWindowCard();

  @override
  ConsumerState<_HydrationWindowCard> createState() => _HydrationWindowCardState();
}

class _HydrationWindowCardState extends ConsumerState<_HydrationWindowCard> {
  static const _ml = 450;
  bool _logged = false;

  void _log() {
    ref.read(hydrationProvider.notifier).add(_ml);
    setState(() => _logged = true);
    final h = ref.read(hydrationProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('+$_ml ml logged • ${h.litres} / ${(h.goalMl / 1000).toStringAsFixed(1)} L today')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final cyanBg = p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed;
    final deep = p.isDark ? AeroColors.tangerine : AeroColors.tangerineDeep;
    return BentoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AeroIconTile(icon: Icons.water_drop_outlined, size: 46, background: cyanBg, foreground: p.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('Hydration Window', style: AeroText.titleMd.copyWith(color: p.text)),
                    ),
                    const SizedBox(width: 6),
                    AeroBadge(_logged ? 'Done' : 'Now', background: cyanBg, foreground: p.cyan),
                  ],
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: AeroText.bodyMd.copyWith(color: p.textMuted),
                    children: [
                      const TextSpan(text: '450ml isotonic blend recommended within next '),
                      TextSpan(
                        text: '20 mins',
                        style: TextStyle(color: p.text, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 14, color: deep),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Replenishes ~380mg Sodium loss',
                        style: AeroText.caption.copyWith(color: deep),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _logged ? cyanBg : p.chip,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: _logged ? null : _log,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: _logged
                    ? Icon(Icons.check_rounded, size: 18, color: p.cyan)
                    : Text('Log', style: AeroText.bodyMd.copyWith(color: p.text, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

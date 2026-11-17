import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Stylized warm vector route map (offline — no tiles, no network).
///
/// [progress] (0..1) is how far along the planned 3 km loop the walker is;
/// the walked portion is drawn solid Sunset Tangerine with a pulsing head,
/// the remainder as a faint dashed preview. `1 km` / `2 km` Sky-Cyan pins sit
/// at the thirds of the route.
class RouteMapCard extends StatefulWidget {
  const RouteMapCard({
    super.key,
    required this.progress,
    required this.pace,
    required this.tag,
    required this.live,
  });

  final double progress;
  final String pace;
  final String tag;
  final bool live;

  @override
  State<RouteMapCard> createState() => _RouteMapCardState();
}

class _RouteMapCardState extends State<RouteMapCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void didUpdateWidget(RouteMapCard old) {
    super.didUpdateWidget(old);
    if (widget.live && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.live && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final chipBg = p.isDark ? AeroColors.espressoCard.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.88);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: widget.progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => CustomPaint(
              painter: _RouteMapPainter(progress: v, dark: p.isDark, pulse: _pulse),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _MapChip(
              background: chipBg,
              leading: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: p.cyan, shape: BoxShape.circle),
              ),
              label: widget.tag,
              color: p.text,
            ),
          ),
          Positioned(
            top: 44,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (p.isDark ? const Color(0xFF3A302A) : const Color(0xFF303032)).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.speed_rounded, size: 15, color: AeroColors.skyCyan),
                  const SizedBox(width: 6),
                  Text('Pace ', style: AeroText.caption.copyWith(color: Colors.white70, fontSize: 11)),
                  Text(widget.pace, style: AeroText.numeric(14, color: Colors.white)),
                  Text(' /km', style: AeroText.caption.copyWith(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: _MapChip(
              background: chipBg,
              leading: Icon(Icons.directions_walk_rounded, size: 14, color: p.accentText),
              label: 'CADENCE PEAK 94%',
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.background, required this.leading, required this.label, required this.color});
  final Color background;
  final Widget leading;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(label, style: AeroText.labelCaps.copyWith(color: color, fontSize: 10)),
          ],
        ),
      );
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({required this.progress, required this.dark, required this.pulse}) : super(repaint: pulse);

  final double progress;
  final bool dark;
  final Animation<double> pulse;

  Path _route(Size s) {
    Offset o(double x, double y) => Offset(s.width * x, s.height * y);
    final a = o(0.15, 0.80), b = o(0.33, 0.50), c = o(0.53, 0.42), d = o(0.75, 0.30);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(s.width * 0.22, s.height * 0.74, s.width * 0.28, s.height * 0.62, b.dx, b.dy)
      ..cubicTo(s.width * 0.38, s.height * 0.36, s.width * 0.46, s.height * 0.30, c.dx, c.dy)
      ..cubicTo(s.width * 0.60, s.height * 0.54, s.width * 0.68, s.height * 0.58, s.width * 0.71, s.height * 0.46)
      ..cubicTo(s.width * 0.73, s.height * 0.40, s.width * 0.74, s.height * 0.35, d.dx, d.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Background
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF241D19), Color(0xFF1C1714)]
              : const [Color(0xFFFFFDFB), Color(0xFFFDE8D7)],
        ).createShader(rect),
    );

    // Districts / parks
    final warmBlock = dark ? const Color(0xFF2C241F) : const Color(0xFFF4EFEA);
    final parkBlock = dark ? const Color(0xFF1F2A24) : const Color(0xFFEAF3EE);
    void block(double x, double y, double bw, double bh, Color c) => canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * x, h * y, w * bw, h * bh), const Radius.circular(18)),
          Paint()..color = c,
        );
    block(0.05, 0.09, 0.23, 0.24, warmBlock);
    block(0.68, 0.12, 0.26, 0.28, parkBlock);
    block(0.64, 0.63, 0.30, 0.31, warmBlock);
    block(0.06, 0.56, 0.26, 0.36, parkBlock);

    // Roads
    final road = Paint()
      ..color = dark ? const Color(0xFF2E2622) : const Color(0xFFFFF7F0)
      ..strokeCap = StrokeCap.round;
    for (final (y, sw) in const [(0.22, 8.0), (0.50, 12.0), (0.79, 9.0)]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), road..strokeWidth = sw);
    }
    for (final (x, sw) in const [(0.2, 10.0), (0.52, 14.0), (0.8, 9.0)]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), road..strokeWidth = sw);
    }

    // Telemetry frame (dashed)
    final frame = Paint()
      ..color = (dark ? Colors.white : const Color(0xFFC9BDB2)).withValues(alpha: dark ? 0.08 : 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _dashed(canvas, Path()..addRect(rect.deflate(18)), frame, 3, 6);

    // Route
    final route = _route(size);
    final metric = route.computeMetrics().first;
    final len = metric.length;
    final walked = metric.extractPath(0, len * progress);

    final preview = Paint()
      ..color = AeroColors.tangerine.withValues(alpha: dark ? 0.35 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    _dashed(canvas, metric.extractPath(len * progress, len), preview, 6, 7);

    canvas.drawPath(
      walked,
      Paint()
        ..color = AeroColors.tangerine.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      walked,
      Paint()
        ..color = AeroColors.tangerine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Start dot
    final start = metric.getTangentForOffset(0)!.position;
    canvas.drawCircle(start, 6, Paint()..color = dark ? Colors.white : AeroColors.charcoal);
    canvas.drawCircle(start, 2.6, Paint()..color = dark ? AeroColors.charcoal : Colors.white);

    // 1 km / 2 km pins
    for (final (f, label) in const [(1 / 3, '1 km'), (2 / 3, '2 km')]) {
      final pos = metric.getTangentForOffset(len * f)!.position;
      canvas.drawCircle(
        pos + const Offset(0, 3),
        16,
        Paint()
          ..color = const Color(0x40006782)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(pos, 16, Paint()..color = AeroColors.skyCyan);
      final tp = TextPainter(
        text: TextSpan(text: label, style: AeroText.numeric(10, color: const Color(0xFF003544))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Live head with ripple
    final head = metric.getTangentForOffset(len * progress)!.position;
    final t = pulse.value;
    canvas.drawCircle(head, 10 + 14 * t, Paint()..color = AeroColors.tangerine.withValues(alpha: 0.22 * (1 - t)));
    canvas.drawCircle(head, 11, Paint()..color = AeroColors.tangerine.withValues(alpha: 0.3));
    canvas.drawCircle(head, 7, Paint()..color = AeroColors.tangerine);
    canvas.drawCircle(head, 2.8, Paint()..color = Colors.white);
  }

  static void _dashed(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final ui.PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + dash).clamp(0, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_RouteMapPainter old) => old.progress != progress || old.dark != dark;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress ring with rounded caps; animates value changes so live
/// step increments glide instead of jumping.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 8,
    this.color = Colors.white,
    this.gradient,
    this.track = const Color(0x40FFFFFF),
    this.child,
  });

  /// 0..1
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final List<Color>? gradient;
  final Color track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => CustomPaint(
          painter: _RingPainter(v, stroke, color, gradient, track),
          child: Center(child: c),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.gradient, this.track);
  final double value;
  final double stroke;
  final Color color;
  final List<Color>? gradient;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (gradient != null) {
      paint.shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: gradient!,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    } else {
      paint.color = color;
    }
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.value != value || o.color != color || o.track != track || o.stroke != stroke;
}

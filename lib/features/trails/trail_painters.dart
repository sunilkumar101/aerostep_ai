import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Offline stand-in for the Inca Trail hero photo: warm dusk sky, layered
/// Andean ridges, topographic contour lines and a dashed trail path whose
/// walked portion glows tangerine up to [progress].
class TopoTrailPainter extends CustomPainter {
  const TopoTrailPainter({required this.progress, this.pulse = 0});

  /// 0..1 portion of the trail already walked.
  final double progress;

  /// 0..1 looping value used for the marker halo.
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8A06C), Color(0xFFB0683E), Color(0xFF4A2C1D), Color(0xFF1C1714)],
          stops: [0, 0.3, 0.62, 1],
        ).createShader(rect),
    );

    // Sun glow.
    canvas.drawCircle(
      Offset(w * 0.74, h * 0.2),
      w * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFDBCC).withValues(alpha: 0.65), const Color(0x00FFDBCC)],
        ).createShader(Rect.fromCircle(center: Offset(w * 0.74, h * 0.2), radius: w * 0.55)),
    );

    // Ridges (far -> near).
    _ridge(canvas, size, base: 0.46, amp: 0.16, seed: 1.3, color: const Color(0xFF9A5A38).withValues(alpha: 0.75));
    _ridge(canvas, size, base: 0.56, amp: 0.14, seed: 2.7, color: const Color(0xFF6B3D26).withValues(alpha: 0.85));
    _ridge(canvas, size, base: 0.68, amp: 0.1, seed: 4.1, color: const Color(0xFF3A2418));

    // Topographic contour rings around the summit.
    final summit = Offset(w * 0.62, h * 0.4);
    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 9; i++) {
      final r = i * w * 0.075;
      contour.color = Colors.white.withValues(alpha: 0.16 - i * 0.01);
      final path = Path();
      for (var a = 0; a <= 72; a++) {
        final t = a / 72 * math.pi * 2;
        final wobble = 1 + 0.08 * math.sin(t * 3 + i) + 0.05 * math.cos(t * 5 - i * 0.7);
        final p = summit + Offset(math.cos(t) * r * 1.35 * wobble, math.sin(t) * r * 0.7 * wobble);
        a == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), contour);
    }

    // Long flowing contour lines (from the Stitch SVG).
    final flow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.22);
    _dashed(
      canvas,
      Path()
        ..moveTo(-w * 0.05, h * 0.3)
        ..quadraticBezierTo(w * 0.17, h * 0.15, w * 0.39, h * 0.27)
        ..quadraticBezierTo(w * 0.6, h * 0.4, w * 0.83, h * 0.18)
        ..quadraticBezierTo(w * 0.95, h * 0.1, w * 1.1, h * 0.32),
      flow,
      4,
      4,
    );

    // Trail path from the trailhead (bottom-left) up to the pass.
    final trail = Path()
      ..moveTo(w * 0.06, h * 0.86)
      ..cubicTo(w * 0.24, h * 0.78, w * 0.2, h * 0.6, w * 0.4, h * 0.56)
      ..cubicTo(w * 0.58, h * 0.52, w * 0.5, h * 0.36, w * 0.66, h * 0.32)
      ..cubicTo(w * 0.78, h * 0.29, w * 0.86, h * 0.22, w * 0.95, h * 0.14);
    final metric = trail.computeMetrics().first;
    final done = metric.length * progress.clamp(0.0, 1.0);

    _dashed(
      canvas,
      metric.extractPath(done, metric.length),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
      5,
      5,
    );
    final walked = metric.extractPath(0, done);
    canvas.drawPath(
      walked,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = AeroColors.tangerine.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      walked,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = AeroColors.tangerine,
    );

    // Current-position marker.
    final tangent = metric.getTangentForOffset(done);
    if (tangent != null) {
      final c = tangent.position;
      canvas.drawCircle(
        c,
        8 + pulse * 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AeroColors.tangerine.withValues(alpha: 0.7 * (1 - pulse)),
      );
      canvas.drawCircle(c, 7, Paint()..color = Colors.white);
      canvas.drawCircle(c, 5, Paint()..color = AeroColors.tangerine);
    }

    // Legibility scrim at the bottom where the copy sits.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            const Color(0xFF141416).withValues(alpha: 0.55),
            const Color(0xFF141416).withValues(alpha: 0.88),
          ],
          stops: const [0, 0.25, 0.6, 1],
        ).createShader(rect),
    );
  }

  void _ridge(
    Canvas canvas,
    Size size, {
    required double base,
    required double amp,
    required double seed,
    required Color color,
  }) {
    final w = size.width;
    final h = size.height;
    final path = Path()..moveTo(0, h);
    for (var x = 0; x <= 40; x++) {
      final t = x / 40;
      final y =
          h * base -
          h *
              amp *
              (0.55 * math.sin(t * math.pi * 2.2 + seed) + 0.35 * math.sin(t * math.pi * 5.1 + seed * 2) + 0.4).abs();
      path.lineTo(w * t, y);
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static void _dashed(Canvas canvas, Path source, Paint paint, double dash, double gap) {
    for (final m in source.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(TopoTrailPainter old) => old.progress != progress || old.pulse != pulse;
}

enum ExpeditionScene { fuji, amalfi }

/// Small illustrated thumbnail for an expedition row (replaces remote photos).
class ExpeditionThumbPainter extends CustomPainter {
  const ExpeditionThumbPainter(this.scene);
  final ExpeditionScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    switch (scene) {
      case ExpeditionScene.fuji:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFC8A8), Color(0xFFFFE6D4), Color(0xFFBFD9E8)],
            ).createShader(rect),
        );
        canvas.drawCircle(Offset(w * 0.78, h * 0.24), w * 0.1, Paint()..color = const Color(0xFFFF9A5C));
        final mountain = Path()
          ..moveTo(-w * 0.05, h * 0.82)
          ..lineTo(w * 0.42, h * 0.3)
          ..lineTo(w * 0.58, h * 0.3)
          ..lineTo(w * 1.05, h * 0.82)
          ..close();
        canvas.drawPath(mountain, Paint()..color = const Color(0xFF5E6C8A));
        final snow = Path()
          ..moveTo(w * 0.31, h * 0.43)
          ..lineTo(w * 0.42, h * 0.3)
          ..lineTo(w * 0.58, h * 0.3)
          ..lineTo(w * 0.69, h * 0.43)
          ..lineTo(w * 0.6, h * 0.4)
          ..lineTo(w * 0.53, h * 0.46)
          ..lineTo(w * 0.46, h * 0.4)
          ..lineTo(w * 0.38, h * 0.46)
          ..close();
        canvas.drawPath(snow, Paint()..color = Colors.white);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.8, w, h * 0.2), Paint()..color = const Color(0xFF8FB3C9));
        // Torii gate.
        final torii = Paint()..color = const Color(0xFFD9381E);
        canvas.drawRect(Rect.fromLTWH(w * 0.1, h * 0.52, w * 0.04, h * 0.36), torii);
        canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.52, w * 0.04, h * 0.36), torii);
        canvas.drawRect(Rect.fromLTWH(w * 0.04, h * 0.5, w * 0.36, h * 0.045), torii);
        canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.59, w * 0.28, h * 0.03), torii);
      case ExpeditionScene.amalfi:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9FE3FF), Color(0xFFDFF5FF)],
            ).createShader(rect),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.5, w, h * 0.5),
          Paint()
            ..shader = ui.Gradient.linear(Offset(0, h * 0.5), Offset(0, h), const [
              Color(0xFF38C6F4),
              Color(0xFF006782),
            ]),
        );
        final cliff = Path()
          ..moveTo(w * 0.35, h)
          ..lineTo(w * 0.5, h * 0.42)
          ..quadraticBezierTo(w * 0.7, h * 0.22, w, h * 0.28)
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(cliff, Paint()..color = const Color(0xFF6E8B4E));
        const houses = [Color(0xFFFFDBCC), Color(0xFFFFB693), Color(0xFFFFF3C4), Color(0xFFFF7A2F), Colors.white];
        var i = 0;
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 4; col++) {
            final x = w * (0.55 + col * 0.1 + row * 0.03);
            final y = h * (0.42 + row * 0.14 + (col.isOdd ? 0.03 : 0));
            if (x > w * 0.95) continue;
            canvas.drawRect(Rect.fromLTWH(x, y, w * 0.08, h * 0.09), Paint()..color = houses[i++ % houses.length]);
          }
        }
    }
  }

  @override
  bool shouldRepaint(ExpeditionThumbPainter old) => old.scene != scene;
}

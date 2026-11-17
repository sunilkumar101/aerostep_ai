import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../aero_palette.dart';

/// Warm peach (light) / espresso (dark) gradient canvas with a subtle
/// geometric asterisk watermark, as specified in DESIGN.md.
class AeroCanvas extends StatelessWidget {
  const AeroCanvas({super.key, required this.child, this.watermark = true});

  final Widget child;
  final bool watermark;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: p.canvas,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (watermark)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _AsteriskPainter(p.isDark)),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _AsteriskPainter extends CustomPainter {
  _AsteriskPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? const Color(0xFFFF7A2F) : const Color(0xFFE8A27A)).withValues(alpha: dark ? 0.05 : 0.16)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;
    void star(Offset c, double r) {
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 4;
        final d = Offset(math.cos(a), math.sin(a)) * r;
        canvas.drawLine(c - d, c + d, paint);
      }
    }

    star(Offset(size.width * 0.92, size.height * 0.07), size.width * 0.22);
    star(Offset(size.width * 0.02, size.height * 0.55), size.width * 0.18);
  }

  @override
  bool shouldRepaint(_AsteriskPainter old) => old.dark != dark;
}

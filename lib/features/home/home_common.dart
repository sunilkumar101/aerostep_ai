import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';

/// Shared helpers for the Home tab views (dashboard + activity tracker).

final NumberFormat _thousands = NumberFormat.decimalPattern('en_US');

/// `8420` -> `8,420`.
String fmtInt(num v) => _thousands.format(v.round());

/// `12000` -> `12k`, `12500` -> `12.5k`, `800` -> `800`.
String fmtCompact(int v) {
  if (v.abs() < 1000) return '$v';
  final k = v / 1000;
  return k == k.roundToDouble() ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
}

/// `74` -> `1h 14m`, `52` -> `52m`.
String fmtDuration(int minutes) => minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60}m';

extension ActivityDerived on ActivitySnapshot {
  /// Average walking speed over today's active minutes (km/h).
  double get avgPaceKmh => activeMinutes <= 0 ? 0 : distanceKm / (activeMinutes / 60);
}

/// Space Grotesk tabular span for numbers embedded in running copy.
TextSpan numSpan(String text, {double size = 14, FontWeight weight = FontWeight.w700, Color? color}) =>
    TextSpan(text: text, style: AeroText.numeric(size, weight: weight, color: color));

/// Hero runner photography (offline asset) cropped into a circle around a
/// normalized focal point of the 896x1200 source image.
class HeroCrop extends StatelessWidget {
  const HeroCrop({
    super.key,
    required this.size,
    required this.focus,
    this.dark = false,
    this.cropWidth = 0.3,
  });

  /// Light focal points.
  static const faceLight = Offset(0.502, 0.175);
  static const faceDark = Offset(0.463, 0.19);
  static const shoeLight = Offset(0.77, 0.754);
  static const shoeDark = Offset(0.424, 0.775);

  final double size;
  final Offset focus;
  final bool dark;

  /// Fraction of the source width visible inside the circle.
  final double cropWidth;

  static const _aspect = 1200 / 896;

  @override
  Widget build(BuildContext context) {
    final w = size / cropWidth;
    final h = w * _aspect;
    final left = (size / 2 - focus.dx * w).clamp(size - w, 0.0);
    final top = (size / 2 - focus.dy * h).clamp(size - h, 0.0);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: Image.asset(
                dark ? 'assets/images/hero_runner_dark.png' : 'assets/images/hero_runner_light.png',
                fit: BoxFit.fill,
                cacheWidth: (w * dpr).round(),
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(gradient: AeroColors.tangerineGradient),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft radial light blob used as ambient glow inside hero cards.
class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}

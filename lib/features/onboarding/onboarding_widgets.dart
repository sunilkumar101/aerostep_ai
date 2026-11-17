import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';

/// Scroll wrapper that gives its [child] (usually a `Column` with an `Expanded`
/// hero) at least the full viewport height, and lets it scroll instead of
/// overflowing on short screens or with large text scale.
class OnboardingFillScroll extends StatelessWidget {
  const OnboardingFillScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: const ClampingScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );
}

/// Soft radial ambient glow orb (cheap stand-in for CSS `blur-3xl` circles).
class GlowOrb extends StatelessWidget {
  const GlowOrb({super.key, required this.color, required this.size, this.opacity = 0.2});
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: size,
      height: size,
      // Keep the orb perfectly round even when its slot is smaller.
      child: OverflowBox(
        minWidth: size,
        maxWidth: size,
        minHeight: size,
        maxHeight: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

enum MarkShape { cross, sparkle }

/// Decorative geometric watermark: a thick rotated cross (light onboarding)
/// or a four-point sparkle (dark onboarding / setup).
class DecoMark extends StatelessWidget {
  const DecoMark({super.key, required this.color, this.size = 24, this.shape = MarkShape.cross, this.rotation = 0});
  final Color color;
  final double size;
  final MarkShape shape;
  final double rotation;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Transform.rotate(
      angle: rotation,
      child: CustomPaint(size: Size.square(size), painter: _MarkPainter(color, shape)),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.shape);
  final Color color;
  final MarkShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..color = color;
    if (shape == MarkShape.sparkle) {
      final w = r * 0.18;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + w, c.dy - w)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx + w, c.dy + w)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - w, c.dy + w)
        ..lineTo(c.dx - r, c.dy)
        ..lineTo(c.dx - w, c.dy - w)
        ..close();
      canvas.drawPath(path, paint);
      return;
    }
    paint
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.butt;
    for (final a in [math.pi / 4, -math.pi / 4]) {
      final d = Offset(math.cos(a), math.sin(a)) * (r * 0.85);
      canvas.drawLine(c - d, c + d, paint);
    }
    canvas.drawCircle(c, size.width * 0.09, paint);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.shape != shape;
}

/// Three-step pill pagination indicator used on the onboarding sheets.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key, required this.inactive, this.active = 0, this.activeWidth = 32});
  final Color inactive;
  final int active;
  final double activeWidth;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 6,
          width: i == active ? activeWidth : 8,
          decoration: BoxDecoration(
            color: i == active ? AeroColors.tangerine : inactive,
            borderRadius: BorderRadius.circular(99),
            boxShadow: i == active
                ? [BoxShadow(color: AeroColors.tangerine.withValues(alpha: 0.4), blurRadius: 4)]
                : null,
          ),
        ),
      ],
    ],
  );
}

/// White full-pill CTA with a tangerine leading emblem, centered label and a
/// trailing arrow (shared by the welcome and smart-setup screens).
class OnboardingPillCta extends StatelessWidget {
  const OnboardingPillCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emblemSize = 40,
    this.padding = const EdgeInsets.all(12),
    this.trailingCircle = true,
    this.shadowColor = const Color(0x4D000000),
    this.labelWeight = FontWeight.w800,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double emblemSize;
  final EdgeInsetsGeometry padding;
  final bool trailingCircle;
  final Color shadowColor;
  final FontWeight labelWeight;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(99);
    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: br,
          child: InkWell(
            borderRadius: br,
            onTap: onPressed,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  Container(
                    width: emblemSize,
                    height: emblemSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AeroColors.tangerine, AeroColors.tangerineLight],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AeroColors.tangerine.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: emblemSize * 0.5, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: AeroText.titleMd.copyWith(
                          color: AeroColors.charcoal,
                          fontWeight: labelWeight,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (trailingCircle)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AeroColors.surfaceContainer),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AeroColors.charcoal),
                    )
                  else
                    const SizedBox(
                      width: 24,
                      child: Icon(Icons.arrow_forward_rounded, size: 20, color: AeroColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact light/espresso preview toggle used in the onboarding headers.
class OnboardingThemeToggle extends ConsumerWidget {
  const OnboardingThemeToggle({super.key, this.background, this.foreground, this.label});
  final Color? background;
  final Color? foreground;

  /// When set, renders as a pill with this label (e.g. "Dark Edition").
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final dark = b == Brightness.dark;
    final fg = foreground ?? (dark ? const Color(0xFFE5DFDA) : AeroColors.charcoal);
    final bg = background ?? (dark ? const Color(0xFF241E1A) : Colors.white.withValues(alpha: 0.8));
    final icon = dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
    return Tooltip(
      message: dark ? 'Preview light mode' : 'Preview espresso dark mode',
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => ref.read(themeModeProvider.notifier).toggle(b),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label == null ? 7 : 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fg),
                if (label != null) ...[
                  const SizedBox(width: 5),
                  Text(label!, maxLines: 1, style: AeroText.labelCaps.copyWith(color: fg)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero runner photo with a graceful fallback while `assets/images/` is not
/// yet registered (or the file is missing): a warm gradient + runner glyph.
class HeroRunnerImage extends StatelessWidget {
  const HeroRunnerImage({
    super.key,
    required this.dark,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
  });
  final bool dark;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
    dark ? 'assets/images/hero_runner_dark.png' : 'assets/images/hero_runner_light.png',
    fit: fit,
    alignment: alignment,
    filterQuality: FilterQuality.medium,
    semanticLabel: 'AeroStep runner',
    errorBuilder: (_, _, _) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 0.8,
          colors: dark
              ? [const Color(0xFF3A2416), AeroColors.espresso.withValues(alpha: 0)]
              : [AeroColors.peachFixed, const Color(0x00FDE8D7)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_run_rounded,
          size: 120,
          color: dark ? AeroColors.tangerine.withValues(alpha: 0.6) : AeroColors.tangerine.withValues(alpha: 0.75),
        ),
      ),
    ),
  );
}

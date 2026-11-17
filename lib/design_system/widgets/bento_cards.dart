import 'package:flutter/material.dart';

import '../aero_colors.dart';
import '../aero_palette.dart';
import '../aero_typography.dart';

/// Frosted 28px Bento card that adapts to light / espresso-dark.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.color,
    this.gradient,
    this.onTap,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final br = BorderRadius.circular(radius);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? p.card) : null,
        gradient: gradient,
        borderRadius: br,
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Base for colored hero cards that force a readable foreground color
/// onto all descendant Text / Icon widgets.
class _ToneCard extends StatelessWidget {
  const _ToneCard({
    required this.child,
    required this.foreground,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.shadow,
    this.onTap,
    this.height,
  });

  final Widget child;
  final Color foreground;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: color, gradient: gradient, borderRadius: br, boxShadow: shadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sunset Tangerine gradient hero card (white foreground).
class TangerineCard extends StatelessWidget {
  const TangerineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.onTap,
    this.height,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double? height;

  @override
  Widget build(BuildContext context) => _ToneCard(
        gradient: AeroColors.tangerineGradient,
        foreground: Colors.white,
        padding: padding,
        radius: radius,
        onTap: onTap,
        height: height,
        shadow: const [BoxShadow(color: Color(0x33FF7A2F), blurRadius: 28, offset: Offset(0, 12))],
        child: child,
      );
}

/// Deep charcoal `#141416` card. CONTRAST FIX: all descendant text/icons default
/// to `#FFFFFF`; use [AeroColors.peachFixed] / [AeroColors.tangerine] for accents.
class CharcoalCard extends StatelessWidget {
  const CharcoalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.onTap,
    this.height,
    this.color = AeroColors.charcoal,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double? height;
  final Color color;

  @override
  Widget build(BuildContext context) => _ToneCard(
        color: color,
        foreground: Colors.white,
        padding: padding,
        radius: radius,
        onTap: onTap,
        height: height,
        shadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
        child: child,
      );
}

/// Sky-Cyan telemetry card (deep-ink foreground for contrast).
class CyanCard extends StatelessWidget {
  const CyanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.onTap,
    this.height,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double? height;

  @override
  Widget build(BuildContext context) => _ToneCard(
        gradient: AeroColors.cyanGradient,
        foreground: AeroColors.onCyanFixed,
        padding: padding,
        radius: radius,
        onTap: onTap,
        height: height,
        shadow: const [BoxShadow(color: Color(0x3338C6F4), blurRadius: 24, offset: Offset(0, 10))],
        child: child,
      );
}

/// Rounded-square icon tile used at the top of bento cards.
class AeroIconTile extends StatelessWidget {
  const AeroIconTile({
    super.key,
    required this.icon,
    this.background,
    this.foreground,
    this.size = 36,
  });
  final IconData icon;
  final Color? background;
  final Color? foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? (p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, size: size * 0.56, color: foreground ?? p.accentText),
    );
  }
}

/// Small rounded label badge, e.g. `+12%`, `BALANCED`, `VERIFIED`.
class AeroBadge extends StatelessWidget {
  const AeroBadge(
    this.label, {
    super.key,
    this.background,
    this.foreground,
    this.icon,
    this.caps = true,
  });
  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;
  final bool caps;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final fg = foreground ?? p.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background ?? p.chip, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              caps ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (caps ? AeroText.labelCaps.copyWith(fontSize: 10) : AeroText.caption)
                  .copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with optional trailing action.
class AeroSectionTitle extends StatelessWidget {
  const AeroSectionTitle(this.title, {super.key, this.trailing, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AeroText.headlineMd.copyWith(color: p.text)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: AeroText.caption.copyWith(color: p.textMuted)),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../aero_colors.dart';
import '../aero_palette.dart';
import '../aero_typography.dart';

enum AeroButtonTone { tangerine, charcoal, cyan, white, ghost }

/// Full-pill button in the Warm Bento style.
class AeroPillButton extends StatelessWidget {
  const AeroPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = AeroButtonTone.tangerine,
    this.height = 52,
    this.expand = false,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AeroButtonTone tone;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final (Color? bg, Gradient? grad, Color fg) = switch (tone) {
      AeroButtonTone.tangerine => (null, AeroColors.tangerineGradient, Colors.white),
      AeroButtonTone.charcoal => (p.isDark ? Colors.white : AeroColors.charcoal, null, p.isDark ? AeroColors.charcoal : Colors.white),
      AeroButtonTone.cyan => (AeroColors.skyCyan, null, AeroColors.onCyanFixed),
      AeroButtonTone.white => (Colors.white, null, AeroColors.charcoal),
      AeroButtonTone.ghost => (Colors.white.withValues(alpha: 0.12), null, Colors.white),
    };
    final br = BorderRadius.circular(99);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.bodyLg.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: height < 44 ? 13 : 15),
          ),
        ),
        if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 18, color: fg)],
      ],
    );
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          gradient: grad,
          borderRadius: br,
          boxShadow: tone == AeroButtonTone.tangerine
              ? const [BoxShadow(color: Color(0x4DFF7A2F), blurRadius: 18, offset: Offset(0, 8))]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            onTap: onPressed,
            child: Padding(padding: EdgeInsets.symmetric(horizontal: height < 44 ? 14 : 22), child: content),
          ),
        ),
      ),
    );
  }
}

/// Round icon button (e.g. mic, filter, bell).
class AeroCircleButton extends StatelessWidget {
  const AeroCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.background,
    this.foreground,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color? foreground;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final btn = Material(
      color: background ?? p.card,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.44, color: foreground ?? p.accentText),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Segmented pill bar (Day / Week / Month ...). The active pill is charcoal
/// `#141416` with crisp `#FFFFFF` text (Trends contrast fix).
class AeroSegmented<T> extends StatelessWidget {
  const AeroSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.activeTangerine = false,
    this.height = 44,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final bool activeTangerine;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o == selected
                        ? (activeTangerine ? AeroColors.tangerine : AeroColors.charcoal)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    labelOf(o),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: o == selected ? Colors.white : p.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal category chip (DAILY STEPS, VIRTUAL TRAILS ...).
class AeroCategoryChip extends StatelessWidget {
  const AeroCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final fg = selected ? Colors.white : p.text;
    return Material(
      color: selected ? AeroColors.tangerine : p.card,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : p.textMuted),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: AeroText.labelCaps.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing online dot (Sky-Cyan by default).
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.color = AeroColors.skyCyan, this.size = 12, this.ring});
  final Color color;
  final double size;
  final Color? ring;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2,
      height: s * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s * (1 + _c.value),
              height: s * (1 + _c.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                border: widget.ring == null ? null : Border.all(color: widget.ring!, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

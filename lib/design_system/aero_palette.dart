import 'package:flutter/material.dart';

import 'aero_colors.dart';

/// Theme-aware semantic palette. Read with `context.aero`.
@immutable
class AeroPalette extends ThemeExtension<AeroPalette> {
  const AeroPalette({
    required this.isDark,
    required this.canvas,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentText,
    required this.cyan,
    required this.chip,
    required this.track,
  });

  final bool isDark;
  final List<Color> canvas;

  /// Frosted bento card fill.
  final Color card;
  final Color cardBorder;
  final List<BoxShadow> cardShadow;
  final Color text;
  final Color textMuted;

  /// Tangerine brand accent.
  final Color accent;

  /// Accent used for text on neutral surfaces (deep tangerine in light, neon in dark).
  final Color accentText;
  final Color cyan;

  /// Neutral chip / pill background.
  final Color chip;

  /// Progress-ring / chart track color.
  final Color track;

  static const light = AeroPalette(
    isDark: false,
    canvas: AeroColors.canvasLight,
    card: Color(0xE6FFFFFF),
    cardBorder: Color(0x99FFFFFF),
    cardShadow: [BoxShadow(color: Color(0x14FF7A2F), blurRadius: 20, offset: Offset(0, 6))],
    text: AeroColors.onSurface,
    textMuted: AeroColors.onSurfaceVariant,
    accent: AeroColors.tangerine,
    accentText: AeroColors.tangerineDeep,
    cyan: AeroColors.cyanDeep,
    chip: AeroColors.surfaceHigh,
    track: AeroColors.surfaceHighest,
  );

  static const dark = AeroPalette(
    isDark: true,
    canvas: AeroColors.canvasDark,
    card: Color(0xF2221C18),
    cardBorder: Color(0x14FFFFFF),
    cardShadow: [BoxShadow(color: Color(0x8C000000), blurRadius: 36, offset: Offset(0, 16))],
    text: AeroColors.onSurfaceDark,
    textMuted: AeroColors.onSurfaceVariantDark,
    accent: AeroColors.tangerine,
    accentText: AeroColors.tangerine,
    cyan: AeroColors.skyCyan,
    chip: Color(0xFF2C241F),
    track: Color(0xFF2E2622),
  );

  @override
  AeroPalette copyWith() => this;

  @override
  AeroPalette lerp(ThemeExtension<AeroPalette>? other, double t) =>
      (other is AeroPalette && t > 0.5) ? other : this;
}

extension AeroContext on BuildContext {
  AeroPalette get aero => Theme.of(this).extension<AeroPalette>() ?? AeroPalette.light;
}

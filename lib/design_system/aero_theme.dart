import 'package:flutter/material.dart';

import 'aero_colors.dart';
import 'aero_palette.dart';
import 'aero_typography.dart';

abstract final class AeroTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AeroColors.tangerineDeep,
      onPrimary: Colors.white,
      primaryContainer: AeroColors.tangerine,
      onPrimaryContainer: Color(0xFF612400),
      secondary: AeroColors.cyanDeep,
      onSecondary: Colors.white,
      secondaryContainer: AeroColors.skyCyan,
      onSecondaryContainer: Color(0xFF00566D),
      tertiary: Color(0xFF934B13),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE48B4F),
      error: AeroColors.error,
      onError: Colors.white,
      surface: AeroColors.surfaceLight,
      onSurface: AeroColors.onSurface,
      onSurfaceVariant: AeroColors.onSurfaceVariant,
      surfaceContainerLowest: AeroColors.surfaceLowest,
      surfaceContainerLow: AeroColors.surfaceLow,
      surfaceContainer: AeroColors.surfaceContainer,
      surfaceContainerHigh: AeroColors.surfaceHigh,
      surfaceContainerHighest: AeroColors.surfaceHighest,
      outline: AeroColors.outline,
      outlineVariant: AeroColors.outlineVariant,
      inverseSurface: Color(0xFF303032),
      onInverseSurface: Color(0xFFF3F0F2),
      inversePrimary: AeroColors.peachFixedDim,
    );
    return _base(scheme, AeroPalette.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AeroColors.tangerine,
      onPrimary: Colors.white,
      primaryContainer: AeroColors.tangerine,
      onPrimaryContainer: Colors.white,
      secondary: AeroColors.skyCyan,
      onSecondary: AeroColors.onCyanFixed,
      secondaryContainer: AeroColors.skyCyan,
      onSecondaryContainer: AeroColors.onCyanFixed,
      tertiary: AeroColors.peachFixedDim,
      onTertiary: Color(0xFF351000),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: AeroColors.espresso,
      onSurface: AeroColors.onSurfaceDark,
      onSurfaceVariant: AeroColors.onSurfaceVariantDark,
      surfaceContainerLowest: AeroColors.espressoSubtle,
      surfaceContainerLow: AeroColors.espressoCard,
      surfaceContainer: AeroColors.espressoCard,
      surfaceContainerHigh: Color(0xFF2C241F),
      surfaceContainerHighest: Color(0xFF352C26),
      outline: Color(0xFF7A6E66),
      outlineVariant: Color(0xFF3A302A),
      inverseSurface: AeroColors.onSurfaceDark,
      onInverseSurface: AeroColors.charcoal,
      inversePrimary: AeroColors.tangerineDeep,
    );
    return _base(scheme, AeroPalette.dark);
  }

  static ThemeData _base(ColorScheme scheme, AeroPalette palette) {
    final text = AeroText.textTheme(palette.text, palette.textMuted);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas.first,
      textTheme: text,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AeroColors.charcoal,
        contentTextStyle: AeroText.bodyMd.copyWith(color: Colors.white),
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AeroColors.tangerine : palette.track,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AeroColors.tangerine,
        inactiveTrackColor: palette.track,
        thumbColor: Colors.white,
        overlayColor: AeroColors.tangerine.withValues(alpha: 0.15),
        trackHeight: 6,
      ),
    );
  }
}

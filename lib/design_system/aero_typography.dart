import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale from DESIGN.md.
/// `Plus Jakarta Sans` for text, `Space Grotesk` + tabular figures for every numeric readout.
abstract final class AeroText {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _jakarta(double size, FontWeight w, double height, [double ls = 0]) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, height: height / size, letterSpacing: ls);

  static TextStyle _grotesk(double size, FontWeight w, double height, [double ls = 0]) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: w,
        height: height / size,
        letterSpacing: ls,
        fontFeatures: _tabular,
      );

  // Numeric (Space Grotesk, tabular)
  static TextStyle get displayHero => _grotesk(56, FontWeight.w700, 60, -2.2);
  static TextStyle get displayHeroMobile => _grotesk(44, FontWeight.w700, 48, -1.3);
  static TextStyle get metricLg => _grotesk(32, FontWeight.w700, 36, -0.9);
  static TextStyle get metricSm => _grotesk(18, FontWeight.w600, 22, -0.3);
  static TextStyle get labelCaps => _grotesk(11, FontWeight.w700, 14, 0.66);

  /// Tabular numeric style at any size.
  static TextStyle numeric(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      _grotesk(size, weight, size * 1.1, size > 24 ? -size * 0.03 : 0).copyWith(color: color);

  // Text (Plus Jakarta Sans)
  static TextStyle get headlineLg => _jakarta(32, FontWeight.w800, 38, -0.6);
  static TextStyle get headlineLgMobile => _jakarta(26, FontWeight.w800, 32, -0.5);
  static TextStyle get headlineMd => _jakarta(22, FontWeight.w700, 28, -0.2);
  static TextStyle get titleMd => _jakarta(18, FontWeight.w700, 24);
  static TextStyle get bodyLg => _jakarta(16, FontWeight.w500, 24);
  static TextStyle get bodyMd => _jakarta(14, FontWeight.w400, 20);
  static TextStyle get caption => _jakarta(12, FontWeight.w500, 16);

  static TextTheme textTheme(Color onSurface, Color muted) => TextTheme(
        displayLarge: displayHero.copyWith(color: onSurface),
        displayMedium: displayHeroMobile.copyWith(color: onSurface),
        headlineLarge: headlineLg.copyWith(color: onSurface),
        headlineMedium: headlineLgMobile.copyWith(color: onSurface),
        headlineSmall: headlineMd.copyWith(color: onSurface),
        titleLarge: headlineMd.copyWith(color: onSurface),
        titleMedium: titleMd.copyWith(color: onSurface),
        titleSmall: bodyLg.copyWith(color: onSurface, fontWeight: FontWeight.w700),
        bodyLarge: bodyLg.copyWith(color: onSurface),
        bodyMedium: bodyMd.copyWith(color: onSurface),
        bodySmall: caption.copyWith(color: muted),
        labelLarge: bodyMd.copyWith(color: onSurface, fontWeight: FontWeight.w700),
        labelMedium: caption.copyWith(color: muted),
        labelSmall: labelCaps.copyWith(color: muted),
      );
}

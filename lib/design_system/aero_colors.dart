import 'package:flutter/material.dart';

/// Warm Bento Dynamic raw color tokens (see ui_ux_stitch_assets/aerostep_design_tokens.md).
abstract final class AeroColors {
  // Brand
  static const tangerine = Color(0xFFFF7A2F); // primary-container
  static const tangerineLight = Color(0xFFFFA163);
  static const tangerineDeep = Color(0xFFA04100); // primary (light)
  static const peachFixed = Color(0xFFFFDBCC); // primary-fixed
  static const peachFixedDim = Color(0xFFFFB693);
  static const skyCyan = Color(0xFF46CFFE); // secondary-container
  static const telemetryCyan = Color(0xFF38C6F4);
  static const cyanDeep = Color(0xFF006782); // secondary (light)
  static const cyanFixed = Color(0xFFBBE9FF);
  static const onCyanFixed = Color(0xFF001F29);
  static const charcoal = Color(0xFF141416); // deep charcoal anchor
  static const charcoalWarm = Color(0xFF1C1714);
  static const error = Color(0xFFBA1A1A);
  static const success = Color(0xFF2EAD6B);

  // Light surfaces
  static const canvasLight = [Color(0xFFFFFDFB), Color(0xFFFFF3EA), Color(0xFFFDE8D7)];
  static const surfaceLight = Color(0xFFFCF8FB);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F5);
  static const surfaceContainer = Color(0xFFF0EDEF);
  static const surfaceHigh = Color(0xFFEAE7EA);
  static const surfaceHighest = Color(0xFFE5E1E4);
  static const onSurface = Color(0xFF1B1B1D);
  static const onSurfaceVariant = Color(0xFF584238);
  static const outline = Color(0xFF8C7166);
  static const outlineVariant = Color(0xFFDFC0B2);

  // Dark (Warm Espresso Obsidian)
  static const canvasDark = [Color(0xFF12100E), Color(0xFF181310), Color(0xFF1C1714)];
  static const espresso = Color(0xFF12100E);
  static const espressoCard = Color(0xFF221C18);
  static const espressoSubtle = Color(0xFF181310);
  static const onSurfaceDark = Color(0xFFFCF8FB);
  static const onSurfaceVariantDark = Color(0xFFA89F99);

  static const tangerineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tangerine, Color(0xFFFF853A), tangerineLight],
  );

  static const cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [telemetryCyan, skyCyan],
  );
}

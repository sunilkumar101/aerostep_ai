import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/shell_state.dart';
import '../../../design_system/design_system.dart';

final NumberFormat _grouped = NumberFormat.decimalPattern('en_US');

/// `64280` -> `64,280`.
String fmtInt(num v) => _grouped.format(v.round());

/// `14230` -> `14.2k`, `830` -> `830`.
String fmtCompact(num v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '${v.round()}';

/// Shared header for the two Analysis-tab views: title + caps subtitle,
/// theme toggle, and the Calories / Trends sub-view switcher underneath.
class AnalysisHeader extends StatelessWidget {
  const AnalysisHeader({super.key, required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AeroIconTile(icon: icon, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.headlineLgMobile.copyWith(color: p.text),
                  ),
                  Text(
                    subtitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.labelCaps.copyWith(color: p.accentText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const ThemeToggleButton(),
          ],
        ),
        const SizedBox(height: 14),
        const SubViewSwitcher.analysis(),
      ],
    );
  }
}

/// Four-armed asterisk watermark (the Warm Bento motif) for card corners.
class AsteriskMark extends StatelessWidget {
  const AsteriskMark({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(size: Size.square(size), painter: _AsteriskPainter(color)));
}

class _AsteriskPainter extends CustomPainter {
  _AsteriskPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.9;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.shortestSide * 0.06;
    for (final d in const [Offset(1, 0), Offset(0, 1), Offset(0.7071, 0.7071), Offset(0.7071, -0.7071)]) {
      canvas.drawLine(c - d * r, c + d * r, paint);
    }
  }

  @override
  bool shouldRepaint(_AsteriskPainter old) => old.color != color;
}

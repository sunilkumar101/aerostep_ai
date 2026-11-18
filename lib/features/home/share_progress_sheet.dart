import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';
import 'home_common.dart';

/// Bottom sheet with a branded 4:5 progress card (Instagram / Facebook feed
/// size) and a Share button that sends it as a PNG through the system share
/// sheet, so the user can pick Instagram, Facebook, WhatsApp, etc.
Future<void> showShareProgressSheet(BuildContext context, ActivitySnapshot a, {String name = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.aero.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _ShareSheet(a: a, name: name),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.a, required this.name});
  final ActivitySnapshot a;
  final String name;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // Export at 1080 px wide whatever the preview size is.
      final image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      final a = widget.a;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'aerostep_${a.steps}_steps.png'),
          ],
          fileNameOverrides: ['aerostep_${a.steps}_steps.png'],
          text: '${fmtInt(a.steps)} steps today with AeroStep! #AeroStep #StepChallenge',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share the image: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: p.cardBorder, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 14),
            Text('Share your progress', style: AeroText.titleMd.copyWith(color: p.text, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Post it to Instagram, Facebook, WhatsApp or any app.',
              textAlign: TextAlign.center,
              style: AeroText.caption.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: RepaintBoundary(key: _cardKey, child: ShareProgressCard(a: widget.a, name: widget.name)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AeroColors.tangerine,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(_busy ? 'Preparing…' : 'Share image', style: AeroText.titleMd.copyWith(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The exported image: 4:5 tangerine card with today's numbers.
class ShareProgressCard extends StatelessWidget {
  const ShareProgressCard({super.key, required this.a, this.name = ''});
  final ActivitySnapshot a;
  final String name;

  @override
  Widget build(BuildContext context) {
    final white80 = Colors.white.withValues(alpha: 0.85);
    final date = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
    final who = name.trim().isEmpty ? 'My steps today' : "${name.trim()}'s steps today";
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(
        builder: (context, c) {
          final u = c.maxWidth / 300; // scale everything from a 300-wide design
          return Container(
            padding: EdgeInsets.all(20 * u),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AeroColors.tangerine, AeroColors.tangerineLight],
              ),
              borderRadius: BorderRadius.circular(24 * u),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_walk_rounded, color: Colors.white, size: 18 * u),
                    SizedBox(width: 6 * u),
                    Text(
                      'AEROSTEP',
                      style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 11 * u, letterSpacing: 2),
                    ),
                    const Spacer(),
                    Text(date, style: AeroText.caption.copyWith(color: white80, fontSize: 10 * u)),
                  ],
                ),
                const Spacer(),
                Text(
                  who.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.labelCaps.copyWith(color: white80, fontSize: 10 * u, letterSpacing: 1.4),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmtInt(a.steps),
                    style: AeroText.displayHeroMobile.copyWith(color: Colors.white, fontSize: 64 * u, height: 1.05),
                  ),
                ),
                Text(
                  a.remaining == 0 ? 'Goal of ${fmtInt(a.goal)} smashed!' : '${a.percent}% of my ${fmtInt(a.goal)} step goal',
                  style: AeroText.bodyMd.copyWith(color: Colors.white, fontSize: 13 * u, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 14 * u),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: a.progress,
                    minHeight: 8 * u,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10 * u),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14 * u),
                  ),
                  child: Row(
                    children: [
                      _stat('Distance', '${a.distanceKm.toStringAsFixed(1)} km', u),
                      _stat('Active', '${a.activeMinutes} min', u),
                      _stat('Burned', '${fmtInt(a.kcal)} kcal', u),
                    ],
                  ),
                ),
                SizedBox(height: 10 * u),
                Center(
                  child: Text(
                    'Counted with AeroStep • Zero-GPS pedometer',
                    style: AeroText.caption.copyWith(color: white80, fontSize: 9 * u),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _stat(String label, String value, double u) => Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AeroText.numeric(14 * u, color: Colors.white)),
            ),
            SizedBox(height: 2 * u),
            Text(label, style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 9 * u)),
          ],
        ),
      );
}

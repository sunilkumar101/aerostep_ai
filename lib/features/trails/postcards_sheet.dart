import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

class _Postcard {
  const _Postcard(this.name, this.region, this.icon, this.colors, {this.unlockKm, this.isNew = false});
  final String name;
  final String region;
  final IconData icon;
  final List<Color> colors;

  /// null = collected; otherwise the trail km at which it unlocks.
  final double? unlockKm;
  final bool isNew;
  bool get locked => unlockKm != null;
}

const _postcards = <_Postcard>[
  _Postcard('Sun Gate Stamp', 'Machu Picchu', Icons.wb_sunny, [
    AeroColors.tangerine,
    AeroColors.tangerineLight,
  ], isNew: true),
  _Postcard('Cusco Plaza', 'Peru', Icons.account_balance, [Color(0xFFFFB693), Color(0xFFFFDBCC)]),
  _Postcard('Ollantaytambo', 'Sacred Valley', Icons.castle, [Color(0xFF934B13), Color(0xFFE48B4F)]),
  _Postcard('Km 82 Trailhead', 'Piscacucho', Icons.signpost, [AeroColors.telemetryCyan, AeroColors.skyCyan]),
  _Postcard('Llactapata', 'Inca Ruins', Icons.terrain, [Color(0xFF6E8B4E), Color(0xFFA9C47F)]),
  _Postcard('Wayllabamba', 'Base Camp', Icons.holiday_village, [Color(0xFF006782), Color(0xFF46CFFE)]),
  _Postcard('Runkurakay', 'Andes Pass', Icons.filter_hdr, [Color(0xFF5E6C8A), Color(0xFF9AA8C7)]),
  _Postcard('Sayacmarca', 'Cloud Forest', Icons.forest, [Color(0xFF2E7D5B), Color(0xFF7CC8A1)]),
  _Postcard("Dead Woman's Pass", '4,215 m', Icons.landscape, [], unlockKm: 31.0),
  _Postcard('Wiñay Wayna', 'Terraces', Icons.grass, [], unlockKm: 36.5),
  _Postcard('Citadel at Dawn', 'Machu Picchu', Icons.temple_hindu, [], unlockKm: 40.0),
  _Postcard('Huayna Picchu', 'Summit', Icons.hiking, [], unlockKm: 42.0),
];

/// Opens the 12-postcard collectible gallery.
Future<void> showPostcardsSheet(BuildContext context) {
  final p = context.aero;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: p.isDark ? AeroColors.espressoCard : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const _PostcardsSheet(),
  );
}

class _PostcardsSheet extends StatelessWidget {
  const _PostcardsSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final collected = _postcards.where((c) => !c.locked).length;
    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.86),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const AeroIconTile(icon: Icons.loyalty),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collectible Postcards', style: AeroText.titleMd.copyWith(color: p.text)),
                        Text('Inca Trail to Machu Picchu', style: AeroText.caption.copyWith(color: p.textMuted)),
                      ],
                    ),
                  ),
                  AeroBadge(
                    '$collected / ${_postcards.length}',
                    background: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
                    foreground: p.accentText,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: _postcards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, i) => _PostcardTile(card: _postcards[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostcardTile extends StatelessWidget {
  const _PostcardTile({required this.card});
  final _Postcard card;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final locked = card.locked;
    final fg = locked ? p.textMuted : Colors.white;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: locked ? p.chip : null,
        gradient: locked
            ? null
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: card.colors),
        border: locked ? Border.all(color: p.cardBorder) : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(locked ? Icons.lock : card.icon, size: 20, color: fg),
              const Spacer(),
              if (card.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                  child: Text('NEW', style: AeroText.labelCaps.copyWith(fontSize: 9, color: AeroColors.tangerineDeep)),
                ),
            ],
          ),
          const Spacer(),
          Text(
            card.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AeroText.caption.copyWith(color: fg, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            locked ? 'AT ${card.unlockKm!.toStringAsFixed(1)} KM' : card.region.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.labelCaps.copyWith(fontSize: 9, color: fg.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

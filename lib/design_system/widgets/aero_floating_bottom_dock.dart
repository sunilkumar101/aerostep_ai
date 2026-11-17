import 'package:flutter/material.dart';

import '../aero_colors.dart';
import 'aero_controls.dart';

class AeroDockItem {
  const AeroDockItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Unified floating split-pill dock: a `#141416` capsule with 4 tabs plus a
/// detached 56x56 Sunset Tangerine AI Sparkle button (8px gap).
class AeroFloatingBottomDock extends StatelessWidget {
  const AeroFloatingBottomDock({
    super.key,
    required this.index,
    required this.onTap,
    required this.onAiTap,
  });

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAiTap;

  static const items = [
    AeroDockItem(Icons.directions_walk_rounded, 'Home'),
    AeroDockItem(Icons.query_stats_rounded, 'Analysis'),
    AeroDockItem(Icons.explore_rounded, 'Trails'),
    AeroDockItem(Icons.groups_rounded, 'Squads'),
  ];

  /// Vertical space content should leave free above the bottom safe area.
  static const clearance = 88.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AeroColors.charcoal,
            borderRadius: BorderRadius.circular(99),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) _DockTab(item: items[i], active: i == index, onTap: () => onTap(i)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _AiSparkButton(onTap: onAiTap),
      ],
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({required this.item, required this.active, required this.onTap});
  final AeroDockItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AeroColors.tangerine : Colors.transparent,
              boxShadow: active ? const [BoxShadow(color: Color(0x73FF7A2F), blurRadius: 14)] : null,
            ),
            child: Icon(item.icon, size: 24, color: active ? Colors.white : AeroColors.surfaceHighest),
          ),
        ),
      ),
    );
  }
}

class _AiSparkButton extends StatelessWidget {
  const _AiSparkButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open AI Coach',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [AeroColors.tangerine, AeroColors.tangerineLight],
                  ),
                  boxShadow: [BoxShadow(color: Color(0x66FF7A2F), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
              ),
              const Positioned(
                top: -4,
                right: -4,
                child: PulsingDot(size: 12, ring: AeroColors.charcoal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

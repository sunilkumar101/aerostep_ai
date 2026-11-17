import 'package:flutter/material.dart';

import 'aero_floating_bottom_dock.dart';

/// Standard scrollable page body: 16px side margins, 12px bento gutter between
/// children, top safe area and bottom clearance for the floating dock.
class AeroScrollPage extends StatelessWidget {
  const AeroScrollPage({
    super.key,
    required this.children,
    this.gap = 12,
    this.dockClearance = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.controller,
  });

  final List<Widget> children;
  final double gap;
  final bool dockClearance;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ListView.separated(
      controller: controller,
      padding: padding.copyWith(
        top: mq.padding.top + 12,
        bottom: mq.padding.bottom + (dockClearance ? AeroFloatingBottomDock.clearance + 24 : 24),
      ),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, i) => children[i],
    );
  }
}

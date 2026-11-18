import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Avatar fill for the current user (readable on light and espresso-dark).
const youAvatarColors = [Color(0xFF7A3000), AeroColors.tangerineDeep];

class BingoTile {
  const BingoTile({
    required this.label,
    required this.icon,
    required this.done,
    this.doneNote = 'Completed',
    this.progress = 0,
    this.progressLabel = '',
    this.locked = false,
    this.lockedLabel = '',
    this.style = BingoStyle.tangerine,
  });

  final String label;
  final IconData icon;
  final bool done;
  final String doneNote;
  final double progress;
  final String progressLabel;
  final bool locked;
  final String lockedLabel;
  final BingoStyle style;
}

enum BingoStyle { tangerine, cyan, hero }

/// Tile copy from the Stitch `aerostep_ai_squads_challenges` export.
const bingoTiles = <BingoTile>[
  BingoTile(label: '10k Noon', icon: Icons.alarm_on, done: true),
  BingoTile(label: 'Post-Dinner 2km', icon: Icons.nightlife, done: true, style: BingoStyle.cyan),
  BingoTile(label: '120 Cadence', icon: Icons.speed, done: false, progress: 11 / 15, progressLabel: '11/15m'),
  BingoTile(label: 'Trail Hiker', icon: Icons.terrain, done: true),
  BingoTile(label: 'Squad Anchor', icon: Icons.stars, done: true, doneNote: '30k Goal Reached', style: BingoStyle.hero),
  BingoTile(
    label: 'Zero Car Day',
    icon: Icons.directions_walk,
    done: false,
    progress: 3 / 5,
    progressLabel: '3/5 d',
    style: BingoStyle.cyan,
  ),
  BingoTile(label: 'Sunrise 7 AM', icon: Icons.wb_twilight, done: false, progress: 1 / 3, progressLabel: '1/3 d'),
  BingoTile(
    label: 'Hydration Walk',
    icon: Icons.water_drop,
    done: true,
    doneNote: '5x Complete',
    style: BingoStyle.cyan,
  ),
  BingoTile(label: '15k Sunday', icon: Icons.lock, done: false, locked: true, lockedLabel: 'SUN'),
];

/// All 8 winning lines of a 3x3 board with display names.
const bingoLines = <(String, List<int>)>[
  ('Row 1', [0, 1, 2]),
  ('Row 2', [3, 4, 5]),
  ('Row 3', [6, 7, 8]),
  ('Column 1', [0, 3, 6]),
  ('Column 2', [1, 4, 7]),
  ('Column 3', [2, 5, 8]),
  ('Diagonal', [0, 4, 8]),
  ('Anti-diagonal', [2, 4, 6]),
];

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.first.toUpperCase();
  if (parts.length == 1) return first;
  return first + parts.last.characters.first.toUpperCase();
}

/// "Updated today" style label for a friend's last manual entry.
String updatedLabel(DateTime updatedAtUtc, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(updatedAtUtc.toLocal());
  final days = (today.difference(day).inHours / 24).round(); // DST-safe
  if (days <= 0) return 'Updated today';
  if (days == 1) return 'Updated yesterday';
  if (days < 7) return 'Updated $days days ago';
  return 'Updated over a week ago';
}

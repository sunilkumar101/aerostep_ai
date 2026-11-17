import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

enum StandingMetric { steps, pace }

/// One leaderboard entry. Pace is stored as seconds per km (lower is better).
class SquadMember {
  const SquadMember({
    required this.id,
    required this.name,
    required this.steps,
    required this.paceSecPerKm,
    required this.stepsNote,
    required this.paceNote,
    required this.badge,
    required this.avatarColors,
    this.isYou = false,
  });

  final String id;
  final String name;
  final int steps;
  final int paceSecPerKm;
  final String stepsNote;
  final String paceNote;
  final IconData? badge;
  final List<Color> avatarColors;
  final bool isYou;

  String get pace => '${paceSecPerKm ~/ 60}:${(paceSecPerKm % 60).toString().padLeft(2, '0')}';
}

const squadRivals = <SquadMember>[
  SquadMember(
    id: 'priya',
    name: 'Priya Sharma',
    steps: 48210,
    paceSecPerKm: 605,
    stepsNote: '+18% brisk cadence pace',
    paceNote: 'Steady 122 spm cadence',
    badge: Icons.fitness_center,
    avatarColors: [AeroColors.tangerine, AeroColors.tangerineLight],
  ),
  SquadMember(
    id: 'marcus',
    name: 'Marcus Chen',
    steps: 42950,
    paceSecPerKm: 582,
    stepsNote: 'Daily avg: 14.3k steps',
    paceNote: 'Brisk 128 spm cadence',
    badge: Icons.monitor_heart,
    avatarColors: [AeroColors.telemetryCyan, AeroColors.cyanDeep],
  ),
  SquadMember(
    id: 'amina',
    name: 'Amina Diallo',
    steps: 39120,
    paceSecPerKm: 662,
    stepsNote: '4-day walking streak',
    paceNote: 'Endurance focus • 116 spm',
    badge: Icons.bolt,
    avatarColors: [Color(0xFF934B13), Color(0xFFE48B4F)],
  ),
];

/// Avatar fill for the current user (readable on light and espresso-dark).
const youAvatarColors = [Color(0xFF7A3000), AeroColors.tangerineDeep];

SquadMember squadYou(String name) => SquadMember(
  id: 'you',
  name: name,
  steps: 38420,
  paceSecPerKm: 618,
  stepsNote: '',
  paceNote: '',
  badge: null,
  avatarColors: youAvatarColors,
  isYou: true,
);

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

class PulseMessage {
  const PulseMessage({
    required this.author,
    required this.text,
    required this.at,
    required this.colors,
    this.isYou = false,
  });
  final String author;
  final String text;
  final DateTime at;
  final List<Color> colors;
  final bool isYou;
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String timeAgo(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  return '${d.inHours}h ago';
}

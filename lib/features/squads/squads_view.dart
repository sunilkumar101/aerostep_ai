import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/state/activity_state.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'friend_sheet.dart';
import 'friends_provider.dart';
import 'squad_data.dart';

const _bingoLineBonus = 300;

/// Squad weekly goal scales with the number of members (you + friends).
const _goalPerMember = 70000;
const _inviteText = 'Walk with me on AeroStep! https://play.google.com/store/apps/details?id=com.sunilkhatri.aerostep';
final _fmt = NumberFormat.decimalPattern('en_US');

/// One standings row: the user (real weekly steps) or a manually tracked friend.
class _Entry {
  const _Entry({required this.id, required this.name, required this.steps, required this.colors, this.friend});
  final String id;
  final String name;
  final int steps;
  final List<Color> colors;
  final Friend? friend;

  bool get isYou => friend == null;
}

/// Squads tab body — local friends standings + Kinetic Step Bingo.
class SquadsView extends ConsumerStatefulWidget {
  const SquadsView({super.key});

  @override
  ConsumerState<SquadsView> createState() => _SquadsViewState();
}

class _SquadsViewState extends ConsumerState<SquadsView> {
  static const _tabs = <(String, IconData)>[
    ('Friends', Icons.groups),
    ('Weekly Bingo', Icons.grid_view),
    ('Add Friend', Icons.person_add),
    ('Invite', Icons.ios_share),
  ];

  final _scroll = ScrollController();
  final _standingsKey = GlobalKey();
  final _bingoKey = GlobalKey();

  int _tab = 0;

  // Bingo state.
  late final List<bool> _done = [for (final t in bingoTiles) t.done];
  final Set<String> _claimed = {};
  int _points = 0;
  int _popIndex = -1;
  int _popTick = 0;
  int _burstTick = 0;
  List<int> _winTiles = const [];
  Timer? _winTimer;

  @override
  void dispose() {
    _winTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  void _toast(String message, {IconData icon = Icons.check_circle}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, AeroFloatingBottomDock.clearance + 12),
          content: Row(
            children: [
              Icon(icon, color: AeroColors.tangerine, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _reveal(GlobalKey key, double fallbackFraction) async {
    var ctx = key.currentContext;
    if (ctx == null && _scroll.hasClients) {
      // Item not built yet (lazy list): jump near it first.
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent * fallbackFraction,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      ctx = key.currentContext;
    }
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  void _onTab(int i) {
    switch (i) {
      case 0:
        setState(() => _tab = 0);
        if (_scroll.hasClients) {
          _scroll.animateTo(0, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
        }
      case 1:
        setState(() => _tab = 1);
        _reveal(_bingoKey, 0.6);
      case 2:
        _addFriend();
      case 3:
        _invite();
    }
  }

  Future<void> _invite() async {
    HapticFeedback.lightImpact();
    try {
      await SharePlus.instance.share(ShareParams(text: _inviteText, subject: 'Walk with me on AeroStep'));
    } catch (_) {
      if (mounted) _toast("Couldn't open the share sheet", icon: Icons.error_outline);
    }
  }

  Future<void> _addFriend() async {
    if (ref.read(friendsProvider).length >= kMaxFriends) {
      _toast('Your squad is full ($kMaxFriends friends max)', icon: Icons.info_outline);
      return;
    }
    final result = await showFriendSheet(context);
    if (!mounted || result is! FriendSheetSave) return;
    if (ref.read(friendsProvider.notifier).add(result.name, result.steps)) {
      HapticFeedback.mediumImpact();
      _toast('${result.name} joined your squad', icon: Icons.person_add);
    }
  }

  Future<void> _editFriend(Friend friend) async {
    final result = await showFriendSheet(context, friend: friend);
    if (!mounted || result == null) return;
    final notifier = ref.read(friendsProvider.notifier);
    switch (result) {
      case FriendSheetSave(:final name, :final steps):
        notifier.edit(friend.id, name: name, weeklySteps: steps);
        HapticFeedback.lightImpact();
        _toast('$name updated');
      case FriendSheetRemove():
        notifier.remove(friend.id);
        HapticFeedback.mediumImpact();
        _toast('${friend.name} removed', icon: Icons.person_remove);
    }
  }

  List<(String, List<int>)> get _completedLines => bingoLines.where((l) => l.$2.every((i) => _done[i])).toList();

  void _onBingoTap(int i) {
    final tile = bingoTiles[i];
    if (tile.locked) {
      HapticFeedback.selectionClick();
      _toast('${tile.label} unlocks on Sunday', icon: Icons.lock);
      return;
    }
    final before = _completedLines.map((l) => l.$1).toSet();
    setState(() {
      _done[i] = !_done[i];
      _popIndex = i;
      _popTick++;
    });
    if (!_done[i]) {
      HapticFeedback.selectionClick();
      return;
    }
    final fresh = _completedLines.where((l) => !before.contains(l.$1)).toList();
    if (fresh.isEmpty) {
      HapticFeedback.mediumImpact();
      return;
    }
    HapticFeedback.heavyImpact();
    _winTimer?.cancel();
    setState(() {
      _burstTick++;
      _winTiles = {for (final l in fresh) ...l.$2}.toList();
    });
    _winTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _winTiles = const []);
    });
    final names = fresh.map((l) => l.$1).join(' + ');
    _toast('BINGO! $names complete • +${_bingoLineBonus * fresh.length} pts to claim', icon: Icons.emoji_events);
  }

  void _claimBonus(List<String> lines) {
    if (lines.isEmpty) return;
    final pts = _bingoLineBonus * lines.length;
    setState(() {
      _claimed.addAll(lines);
      _points += pts;
    });
    HapticFeedback.mediumImpact();
    _toast('+$pts AeroPoints added • Squad Multiplier boosted', icon: Icons.auto_awesome);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final userName = ref.watch(userProfileProvider.select((u) => u.name)).trim();
    final mySteps = ref.watch(activityProvider.select((a) => a.weeklyTotal));
    final friends = ref.watch(friendsProvider);

    final ranked =
        <_Entry>[
          _Entry(id: 'you', name: userName.isEmpty ? 'You' : userName, steps: mySteps, colors: youAvatarColors),
          for (final f in friends)
            _Entry(id: f.id, name: f.name, steps: f.weeklySteps, colors: f.avatarColors, friend: f),
        ]..sort((a, b) {
          final c = b.steps.compareTo(a.steps);
          if (c != 0) return c;
          if (a.isYou != b.isYou) return a.isYou ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    return AeroScrollPage(
      controller: _scroll,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) =>
                AeroCategoryChip(label: _tabs[i].$1, icon: _tabs[i].$2, selected: i == _tab, onTap: () => _onTab(i)),
          ),
        ),
        _PrivacyBanner(palette: p, members: ranked.length),
        _SquadHeroCard(
          entries: ranked,
          onInvite: _invite,
          onAdd: _addFriend,
          onOpen: () => _reveal(_standingsKey, 0.25),
        ),
        const SizedBox(height: 4),
        KeyedSubtree(
          key: _standingsKey,
          child: _Standings(ranked: ranked, onAdd: _addFriend, onInvite: _invite, onEdit: _editFriend),
        ),
        const SizedBox(height: 4),
        KeyedSubtree(key: _bingoKey, child: _bingoSection(p)),
      ],
    );
  }

  Widget _bingoSection(AeroPalette p) {
    final doneCount = _done.where((d) => d).length;
    final completed = _completedLines;
    final unclaimed = completed.map((l) => l.$1).where((n) => !_claimed.contains(n)).toList();
    final String capsule;
    if (unclaimed.length == 1) {
      capsule = '${unclaimed.first} Completed (+$_bingoLineBonus pts)';
    } else if (unclaimed.length > 1) {
      capsule = '${unclaimed.length} Lines Completed (+${_bingoLineBonus * unclaimed.length} pts)';
    } else if (_points > 0) {
      capsule = 'Bonus claimed • ${_fmt.format(_points)} AeroPoints';
    } else {
      capsule = 'Complete any line for +$_bingoLineBonus pts';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 20, color: p.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('Kinetic Step Bingo', style: AeroText.headlineMd.copyWith(color: p.text)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete 3 in a row for 500 AeroPoints & Squad Multiplier',
                    style: AeroText.caption.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: AeroBadge(
                '$doneCount / 9 Done',
                key: ValueKey(doneCount),
                caps: false,
                background: p.isDark ? AeroColors.cyanDeep.withValues(alpha: 0.5) : AeroColors.cyanFixed,
                foreground: p.isDark ? AeroColors.cyanFixed : AeroColors.cyanDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bingoTiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                key: ValueKey(i == _popIndex ? 'pop$i-$_popTick' : 'tile$i'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                builder: (_, t, child) => Transform.scale(scale: 1 + 0.08 * math.sin(math.pi * t), child: child),
                child: _BingoTileView(
                  tile: bingoTiles[i],
                  done: _done[i],
                  winning: _winTiles.contains(i),
                  onTap: () => _onBingoTap(i),
                ),
              ),
            ),
            if (_burstTick > 0) Positioned.fill(child: _BingoBurst(key: ValueKey(_burstTick))),
          ],
        ),
        const SizedBox(height: 12),
        BentoCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  capsule,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.text, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: unclaimed.isEmpty ? null : () => _claimBonus(unclaimed),
                style: TextButton.styleFrom(foregroundColor: p.accentText, shape: const StadiumBorder()),
                child: Text(
                  'CLAIM BONUS',
                  style: AeroText.labelCaps.copyWith(color: unclaimed.isEmpty ? p.textMuted : p.accentText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =================================================================== widgets

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.colors, this.size = 44, this.border});
  final String name;
  final List<Color> colors;
  final double size;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      border: border == null ? null : Border.all(color: border!, width: 2),
    ),
    child: Text(initialsOf(name), style: AeroText.numeric(size * 0.34, color: Colors.white)),
  );
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.palette, required this.members});
  final AeroPalette palette;
  final int members;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 15, color: p.cyan),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Private squad • On this phone'.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.labelCaps.copyWith(color: p.text, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.groups, size: 16, color: p.cyan),
          const SizedBox(width: 4),
          Text(
            '$members ${members == 1 ? 'Member' : 'Members'}',
            style: AeroText.caption.copyWith(color: p.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SquadHeroCard extends StatelessWidget {
  const _SquadHeroCard({required this.entries, required this.onInvite, required this.onAdd, required this.onOpen});
  final List<_Entry> entries;
  final VoidCallback onInvite;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final total = entries.fold<int>(0, (s, e) => s + e.steps);
    final goal = _goalPerMember * entries.length;
    final progress = goal == 0 ? 0.0 : (total / goal).clamp(0.0, 1.0);
    final remaining = math.max(0, goal - total);
    return TangerineCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -36,
            child: Icon(Icons.emergency, size: 170, color: white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AeroBadge(
                          'Weekly Challenge',
                          icon: Icons.calendar_month,
                          background: white.withValues(alpha: 0.2),
                          foreground: white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Walking Squad',
                          style: AeroText.headlineLgMobile.copyWith(color: white, height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This week • ${_goalPerMember ~/ 1000}k steps per member',
                          style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TeamCluster(entries: entries),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(_fmt.format(total), style: AeroText.displayHeroMobile.copyWith(color: white)),
                          const SizedBox(width: 6),
                          Text(
                            '/ ${_fmt.format(goal ~/ 1000)}k',
                            style: AeroText.numeric(18, weight: FontWeight.w600, color: white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(progress * 100).floor()}%', style: AeroText.metricSm.copyWith(color: white)),
                      Text('Squad Goal', style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.85))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 12,
                child: LayoutBuilder(
                  builder: (_, c) => Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              width: c.maxWidth * v,
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.white, Color(0xFFFFF3EA)]),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            Positioned(
                              left: (c.maxWidth * v - 6).clamp(0, c.maxWidth - 12),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AeroColors.skyCyan,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Color(0x9946CFFE), blurRadius: 8)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(remaining > 0 ? Icons.flag : Icons.celebration, size: 16, color: white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      remaining > 0
                          ? '${_fmt.format(remaining)} steps to reach the squad goal'
                          : 'Squad goal reached this week! 🎉',
                      style: AeroText.caption.copyWith(color: white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AeroPillButton(
                          label: 'Invite friends',
                          icon: Icons.ios_share,
                          tone: AeroButtonTone.white,
                          height: 38,
                          onPressed: onInvite,
                        ),
                        AeroPillButton(
                          label: 'Add friend',
                          icon: Icons.person_add,
                          tone: AeroButtonTone.ghost,
                          height: 38,
                          onPressed: onAdd,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AeroCircleButton(
                    icon: Icons.arrow_forward,
                    size: 40,
                    tooltip: 'View squad standings',
                    background: white,
                    foreground: AeroColors.tangerine,
                    onPressed: onOpen,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overlapping avatars of the top squad members (real list, max 3 + overflow).
class _TeamCluster extends StatelessWidget {
  const _TeamCluster({required this.entries});
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    const d = 30.0;
    const step = 20.0;
    final shown = entries.take(3).toList();
    final extra = entries.length - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: d + step * (slots - 1),
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: _InitialsAvatar(name: shown[i].name, colors: shown[i].colors, size: d, border: Colors.white),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: d,
                height: d,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AeroColors.charcoal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text('+$extra', style: AeroText.numeric(10, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings({required this.ranked, required this.onAdd, required this.onInvite, required this.onEdit});
  final List<_Entry> ranked;
  final VoidCallback onAdd;
  final VoidCallback onInvite;
  final ValueChanged<Friend> onEdit;

  static const _rowH = 72.0;
  static const _gap = 10.0;

  String _youNote(int youRank) {
    if (ranked.length == 1) return 'Add friends to compare your week';
    final you = ranked[youRank];
    if (youRank == 0) {
      return ranked[1].steps == you.steps ? 'Tied for the lead' : 'Leading the squad! 👑';
    }
    final ahead = ranked[youRank - 1];
    final first = ahead.name.split(' ').first;
    final diff = ahead.steps - you.steps;
    return diff <= 0 ? 'Tied with $first' : '${_fmt.format(diff)} steps to pass $first! 🚀';
  }

  String _friendNote(Friend f) {
    final now = DateTime.now();
    final weekStart = DateUtils.dateOnly(now).subtract(Duration(days: now.weekday - DateTime.monday));
    if (f.updatedAt.toLocal().isBefore(weekStart)) return "Last week's entry • tap to update";
    return '${updatedLabel(f.updatedAt, now: now)} • tap to edit';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final youRank = ranked.indexWhere((e) => e.isYou);
    final byId = {for (var i = 0; i < ranked.length; i++) ranked[i].id: i};
    // Stable paint order so AnimatedPositioned can slide rows when ranks change.
    final stable = [...ranked]..sort((a, b) => a.id.compareTo(b.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Squad Standings', style: AeroText.headlineMd.copyWith(color: p.text)),
                  AeroBadge(
                    'This week',
                    background: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
                    foreground: p.accentText,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AeroPillButton(label: 'Add', icon: Icons.person_add, height: 38, onPressed: onAdd),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: ranked.length * _rowH + (ranked.length - 1) * _gap,
          child: Stack(
            children: [
              for (final e in stable)
                AnimatedPositioned(
                  key: ValueKey(e.id),
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeInOutCubic,
                  left: 0,
                  right: 0,
                  top: byId[e.id]! * (_rowH + _gap),
                  height: _rowH,
                  child: _StandingRow(
                    entry: e,
                    rank: byId[e.id]! + 1,
                    note: e.isYou ? _youNote(youRank) : _friendNote(e.friend!),
                    onTap: e.isYou ? null : () => onEdit(e.friend!),
                  ),
                ),
            ],
          ),
        ),
        if (ranked.length == 1) ...[const SizedBox(height: 12), _EmptyFriendsCard(onAdd: onAdd, onInvite: onInvite)],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline, size: 14, color: p.textMuted),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Friends' steps are entered by you and stored only on this phone.",
                style: AeroText.caption.copyWith(color: p.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyFriendsCard extends StatelessWidget {
  const _EmptyFriendsCard({required this.onAdd, required this.onInvite});
  final VoidCallback onAdd;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AeroIconTile(icon: Icons.group_add),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Walk together', style: AeroText.titleMd.copyWith(color: p.text)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Add a friend and their steps this week to see who's leading. Invite them to AeroStep so they can "
            'track their own walks.',
            style: AeroText.bodyMd.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AeroPillButton(label: 'Add a friend', icon: Icons.person_add, height: 44, onPressed: onAdd),
              AeroPillButton(
                label: 'Invite',
                icon: Icons.ios_share,
                tone: AeroButtonTone.charcoal,
                height: 44,
                onPressed: onInvite,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.entry, required this.rank, required this.note, this.onTap});
  final _Entry entry;
  final int rank;
  final String note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final you = entry.isYou;
    final valueColor = (you || rank == 1) ? p.accentText : p.text;
    final noteColor = you ? p.accentText : (rank == 1 ? p.cyan : p.textMuted);
    final br = BorderRadius.circular(24);
    final label = you ? (entry.name == 'You' ? 'You' : '${entry.name} (You)') : entry.name;

    return Semantics(
      button: onTap != null,
      label: 'Rank $rank, $label, ${_fmt.format(entry.steps)} steps',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: you
              ? (p.isDark ? AeroColors.tangerine.withValues(alpha: 0.16) : AeroColors.peachFixed.withValues(alpha: 0.9))
              : p.card,
          borderRadius: br,
          border: Border.all(color: you ? AeroColors.tangerine.withValues(alpha: p.isDark ? 0.45 : 0.3) : p.cardBorder),
          boxShadow: p.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _RankChip(rank: rank),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _InitialsAvatar(name: entry.name, colors: entry.colors, size: 42),
                      if (you)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AeroColors.tangerine,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.bodyLg.copyWith(
                                  color: p.text,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (rank == 1 && !you) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.star, size: 14, color: p.accent),
                            ],
                          ],
                        ),
                        Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.caption.copyWith(color: noteColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmt.format(entry.steps), style: AeroText.metricSm.copyWith(color: valueColor)),
                      Text('STEPS', style: AeroText.labelCaps.copyWith(color: p.textMuted, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final (Color bg, Color fg) = switch (rank) {
      1 => (p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed, p.accentText),
      2 => (AeroColors.skyCyan, AeroColors.onCyanFixed),
      3 => (p.isDark ? Colors.white : AeroColors.charcoal, p.isDark ? AeroColors.charcoal : Colors.white),
      _ => (AeroColors.tangerineDeep, Colors.white),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: rank == 1
          ? Icon(Icons.workspace_premium, size: 18, color: fg)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$rank', style: AeroText.numeric(14, color: fg)),
            ),
    );
  }
}

class _BingoTileView extends StatelessWidget {
  const _BingoTileView({required this.tile, required this.done, required this.winning, required this.onTap});
  final BingoTile tile;
  final bool done;
  final bool winning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final locked = tile.locked;

    final Color fg;
    Color? color;
    Gradient? gradient;
    if (done) {
      switch (tile.style) {
        case BingoStyle.tangerine:
          color = AeroColors.tangerine;
          fg = Colors.white;
        case BingoStyle.cyan:
          color = AeroColors.skyCyan;
          fg = AeroColors.onCyanFixed;
        case BingoStyle.hero:
          gradient = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AeroColors.tangerine, Color(0xFFB08C78), AeroColors.telemetryCyan],
          );
          fg = Colors.white;
      }
    } else if (locked) {
      color = p.chip;
      fg = p.textMuted;
    } else {
      color = p.card;
      fg = p.text;
    }

    final br = BorderRadius.circular(22);
    return Semantics(
      button: true,
      label:
          '${tile.label}, ${done
              ? 'completed'
              : locked
              ? 'locked'
              : 'in progress'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: br,
          border: Border.all(
            color: winning ? Colors.white : (done ? Colors.transparent : p.cardBorder),
            width: winning ? 2.5 : 1,
          ),
          boxShadow: winning
              ? const [BoxShadow(color: Color(0x99FF7A2F), blurRadius: 18, spreadRadius: 1)]
              : (done
                    ? const [BoxShadow(color: Color(0x26FF7A2F), blurRadius: 12, offset: Offset(0, 6))]
                    : p.cardShadow),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(tile.icon, size: 18, color: done || locked ? fg : p.accentText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: done
                                ? Container(
                                    key: const ValueKey('check'),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: tile.style == BingoStyle.cyan ? AeroColors.cyanDeep : AeroColors.tangerine,
                                    ),
                                  )
                                : Text(
                                    locked ? tile.lockedLabel : tile.progressLabel,
                                    key: const ValueKey('label'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AeroText.numeric(11, color: locked ? fg : p.accentText),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    tile.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.caption.copyWith(color: fg, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  if (done)
                    Text(
                      tile.doneNote.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.labelCaps.copyWith(color: fg.withValues(alpha: 0.85), fontSize: 8.5),
                    )
                  else if (locked)
                    Text('UPCOMING', style: AeroText.labelCaps.copyWith(color: fg, fontSize: 8.5))
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: tile.progress,
                        minHeight: 5,
                        backgroundColor: p.track,
                        color: tile.style == BingoStyle.cyan ? AeroColors.skyCyan : AeroColors.tangerine,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot "BINGO!" celebration drawn over the grid.
class _BingoBurst extends StatelessWidget {
  const _BingoBurst({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        builder: (_, t, _) {
          if (t >= 1) return const SizedBox.shrink();
          final opacity = t < 0.12 ? t / 0.12 : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
          final scale = Curves.elasticOut.transform((t * 1.8).clamp(0.0, 1.0));
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: CustomPaint(
              painter: _ConfettiPainter(t),
              child: Center(
                child: Transform.scale(
                  scale: 0.4 + 0.6 * scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: AeroColors.charcoal,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: const [BoxShadow(color: Color(0x80FF7A2F), blurRadius: 28)],
                    ),
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [AeroColors.tangerine, AeroColors.peachFixed, AeroColors.skyCyan],
                      ).createShader(r),
                      child: Text('BINGO!', style: AeroText.numeric(36, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.t);
  final double t;

  static const _colors = [AeroColors.tangerine, AeroColors.skyCyan, AeroColors.peachFixed, Colors.white];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.62;
    final eased = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 24; i++) {
      final a = i / 24 * math.pi * 2 + (i.isEven ? 0.12 : -0.08);
      final r = maxR * eased * (0.6 + 0.4 * ((i * 37) % 10) / 10);
      final pos = c + Offset(math.cos(a) * r, math.sin(a) * r + 40 * t * t);
      final paint = Paint()..color = _colors[i % _colors.length];
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a + t * 6);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

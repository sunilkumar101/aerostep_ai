import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'squad_data.dart';

const _inviteCode = 'AERO-88';
const _bingoLineBonus = 300;
final _fmt = NumberFormat.decimalPattern('en_US');

/// Squads tab body — "Squads & Kinetic Step Bingo".
class SquadsView extends ConsumerStatefulWidget {
  const SquadsView({super.key});

  @override
  ConsumerState<SquadsView> createState() => _SquadsViewState();
}

class _SquadsViewState extends ConsumerState<SquadsView> {
  static const _tabs = <(String, IconData)>[
    ('Active Squad', Icons.groups),
    ('Weekly Bingo', Icons.grid_view),
    ('Global Cups', Icons.emoji_events),
    ('Create', Icons.add_circle),
  ];

  final _scroll = ScrollController();
  final _standingsKey = GlobalKey();
  final _bingoKey = GlobalKey();
  final _chatCtrl = TextEditingController();

  int _tab = 0;
  StandingMetric _metric = StandingMetric.steps;

  // Bingo state.
  late final List<bool> _done = [for (final t in bingoTiles) t.done];
  final Set<String> _claimed = {};
  int _points = 0;
  int _popIndex = -1;
  int _popTick = 0;
  int _burstTick = 0;
  List<int> _winTiles = const [];
  Timer? _winTimer;

  // Live Team Pulse.
  late final List<PulseMessage> _messages = [
    PulseMessage(
      author: 'Priya Sharma',
      text: '"Just finished lunch interval strides! 4k in the bag 🏃‍♀️"',
      at: DateTime.now().subtract(const Duration(minutes: 4)),
      colors: const [AeroColors.tangerine, AeroColors.tangerineLight],
    ),
    PulseMessage(
      author: 'Marcus Chen',
      text: 'Took the stairs to the 9th-floor standup. Climb 3 floors ✅',
      at: DateTime.now().subtract(const Duration(minutes: 18)),
      colors: const [AeroColors.telemetryCyan, AeroColors.cyanDeep],
    ),
    PulseMessage(
      author: 'Amina Diallo',
      text: "Walk meeting at 3 PM around the lake loop — who's in?",
      at: DateTime.now().subtract(const Duration(minutes: 41)),
      colors: const [Color(0xFF934B13), Color(0xFFE48B4F)],
    ),
  ];
  final Set<PulseMessage> _cheered = {};

  @override
  void dispose() {
    _winTimer?.cancel();
    _scroll.dispose();
    _chatCtrl.dispose();
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
    setState(() => _tab = i);
    switch (i) {
      case 0:
        if (_scroll.hasClients) {
          _scroll.animateTo(0, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
        }
      case 1:
        _reveal(_bingoKey, 0.6);
      case 2:
        _toast('Global Cups open after Week 12', icon: Icons.emoji_events);
      case 3:
        _toast('Squad creation is coming soon', icon: Icons.add_circle);
    }
  }

  Future<void> _copyInvite() async {
    await Clipboard.setData(const ClipboardData(text: _inviteCode));
    HapticFeedback.lightImpact();
    if (mounted) _toast('Invite code copied');
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

  void _send() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    final name = ref.read(userProfileProvider).name;
    setState(() {
      _messages.insert(
        0,
        PulseMessage(author: name, text: text, at: DateTime.now(), colors: youAvatarColors, isYou: true),
      );
      _chatCtrl.clear();
    });
    HapticFeedback.lightImpact();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final userName = ref.watch(userProfileProvider.select((u) => u.name));

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
        _SyncBanner(palette: p),
        _SquadHeroCard(onInvite: _copyInvite, onOpen: () => _reveal(_standingsKey, 0.25)),
        const SizedBox(height: 4),
        KeyedSubtree(
          key: _standingsKey,
          child: _Standings(
            metric: _metric,
            userName: userName,
            onMetric: (m) {
              HapticFeedback.selectionClick();
              setState(() => _metric = m);
            },
          ),
        ),
        const SizedBox(height: 4),
        KeyedSubtree(key: _bingoKey, child: _bingoSection(p)),
        const SizedBox(height: 4),
        _pulseSection(p),
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

  Widget _pulseSection(AeroPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Live Team Pulse', style: AeroText.headlineMd.copyWith(color: p.text)),
            ),
            Text(
              'View Chat (${_messages.length + 5})',
              style: AeroText.caption.copyWith(color: p.accentText, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BentoCard(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            children: [
              for (var i = 0; i < _messages.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.track),
                _PulseRow(
                  key: ObjectKey(_messages[i]),
                  message: _messages[i],
                  cheered: _cheered.contains(_messages[i]),
                  onCheer: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      final m = _messages[i];
                      _cheered.contains(m) ? _cheered.remove(m) : _cheered.add(m);
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLength: 200,
                      cursorColor: p.accent,
                      style: AeroText.bodyMd.copyWith(color: p.text),
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Cheer your squad…',
                        hintStyle: AeroText.bodyMd.copyWith(color: p.textMuted),
                        filled: true,
                        fillColor: p.chip,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(color: p.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AeroCircleButton(
                    icon: Icons.send_rounded,
                    size: 44,
                    tooltip: 'Send',
                    background: AeroColors.tangerine,
                    foreground: Colors.white,
                    onPressed: _send,
                  ),
                ],
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

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.palette});
  final AeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        children: [
          PulsingDot(size: 8, color: p.cyan),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Anti-Cheat Step Sync: Active'.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.labelCaps.copyWith(color: p.text, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.verified_user, size: 15, color: p.cyan),
          const SizedBox(width: 4),
          Text(
            '14 Members',
            style: AeroText.caption.copyWith(color: p.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SquadHeroCard extends StatelessWidget {
  const _SquadHeroCard({required this.onInvite, required this.onOpen});
  final VoidCallback onInvite;
  final VoidCallback onOpen;

  static const _current = 312400;
  static const _goal = 400000;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const progress = _current / _goal;
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
                          'Enterprise Cohort',
                          icon: Icons.apartment,
                          background: white.withValues(alpha: 0.2),
                          foreground: white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Office Walkers Squad',
                          style: AeroText.headlineLgMobile.copyWith(color: white, height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weekly Corporate Challenge • Week 12',
                          style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _TeamCluster(),
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
                          Text(_fmt.format(_current), style: AeroText.displayHeroMobile.copyWith(color: white)),
                          const SizedBox(width: 6),
                          Text(
                            '/ 400k',
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
                      Text('${(progress * 100).round()}%', style: AeroText.metricSm.copyWith(color: white)),
                      Text('Weekly Goal', style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.85))),
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
                  const Icon(Icons.local_cafe, size: 16, color: white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '87.6k steps to unlock Team Coffee Reward!',
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
                        Material(
                          color: white,
                          shape: const StadiumBorder(),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: onInvite,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Invite: $_inviteCode',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AeroText.caption.copyWith(
                                        color: AeroColors.charcoal,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.content_copy, size: 15, color: AeroColors.charcoal),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AeroBadge(
                          'Verified ✓',
                          icon: Icons.shield,
                          background: white.withValues(alpha: 0.2),
                          foreground: white,
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

class _TeamCluster extends StatelessWidget {
  const _TeamCluster();

  @override
  Widget build(BuildContext context) {
    const d = 30.0;
    const step = 20.0;
    const people = [
      ('Priya Sharma', [Color(0xFFA04100), Color(0xFFFF7A2F)]),
      ('Marcus Chen', [AeroColors.cyanDeep, AeroColors.telemetryCyan]),
      ('Amina Diallo', [Color(0xFF743500), Color(0xFFE48B4F)]),
    ];
    return SizedBox(
      width: d + step * people.length,
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < people.length; i++)
            Positioned(
              left: i * step,
              child: _InitialsAvatar(name: people[i].$1, colors: people[i].$2, size: d, border: Colors.white),
            ),
          Positioned(
            left: people.length * step,
            child: Container(
              width: d,
              height: d,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AeroColors.charcoal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text('+11', style: AeroText.numeric(10, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings({required this.metric, required this.userName, required this.onMetric});
  final StandingMetric metric;
  final String userName;
  final ValueChanged<StandingMetric> onMetric;

  static const _rowH = 72.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final you = squadYou(userName);
    final members = [...squadRivals, you];
    final sorted = [...members]
      ..sort(
        (a, b) =>
            metric == StandingMetric.steps ? b.steps.compareTo(a.steps) : a.paceSecPerKm.compareTo(b.paceSecPerKm),
      );

    final youRank = sorted.indexOf(you);
    final String youNote;
    if (youRank == 0) {
      youNote = 'Leading the squad! 👑';
    } else {
      final ahead = sorted[youRank - 1];
      final first = ahead.name.split(' ').first;
      youNote = metric == StandingMetric.steps
          ? '${_fmt.format(ahead.steps - you.steps)} steps to pass $first! 🚀'
          : '${you.paceSecPerKm - ahead.paceSecPerKm}s/km to catch $first! 🚀';
    }

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
                  Container(
                    padding: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingDot(size: 6, color: AeroColors.tangerine),
                        Text('LIVE', style: AeroText.labelCaps.copyWith(color: p.accentText, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 128,
              child: AeroSegmented<StandingMetric>(
                options: StandingMetric.values,
                selected: metric,
                onChanged: onMetric,
                activeTangerine: true,
                height: 38,
                labelOf: (m) => m == StandingMetric.steps ? 'Steps' : 'Pace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: members.length * _rowH + (members.length - 1) * _gap,
          child: Stack(
            children: [
              for (final m in members)
                AnimatedPositioned(
                  key: ValueKey(m.id),
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeInOutCubic,
                  left: 0,
                  right: 0,
                  top: sorted.indexOf(m) * (_rowH + _gap),
                  height: _rowH,
                  child: _StandingRow(
                    member: m,
                    rank: sorted.indexOf(m) + 1,
                    metric: metric,
                    note: m.isYou ? youNote : (metric == StandingMetric.steps ? m.stepsNote : m.paceNote),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.member, required this.rank, required this.metric, required this.note});
  final SquadMember member;
  final int rank;
  final StandingMetric metric;
  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final you = member.isYou;
    final valueColor = (you || rank == 1) ? p.accentText : p.text;
    final noteColor = you ? p.accentText : (rank == 1 ? p.cyan : p.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: you
            ? (p.isDark ? AeroColors.tangerine.withValues(alpha: 0.16) : AeroColors.peachFixed.withValues(alpha: 0.9))
            : p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: you ? AeroColors.tangerine.withValues(alpha: p.isDark ? 0.45 : 0.3) : p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          _RankChip(rank: rank),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _InitialsAvatar(name: member.name, colors: member.avatarColors, size: 42),
              if (member.badge != null)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: p.isDark ? AeroColors.espressoCard : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(member.badge, size: 11, color: p.text),
                  ),
                ),
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
                        you ? '${member.name} (You)' : member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.bodyLg.copyWith(color: p.text, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    ),
                    if (rank == 1 && !you) ...[const SizedBox(width: 4), Icon(Icons.star, size: 14, color: p.accent)],
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Column(
              key: ValueKey(metric),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metric == StandingMetric.steps ? _fmt.format(member.steps) : member.pace,
                  style: AeroText.metricSm.copyWith(color: valueColor),
                ),
                Text(
                  metric == StandingMetric.steps ? 'STEPS' : 'MIN/KM',
                  style: AeroText.labelCaps.copyWith(color: p.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
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
          : Text('$rank', style: AeroText.numeric(14, color: fg)),
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

class _PulseRow extends StatelessWidget {
  const _PulseRow({super.key, required this.message, required this.cheered, required this.onCheer});
  final PulseMessage message;
  final bool cheered;
  final VoidCallback onCheer;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InitialsAvatar(name: message.author, colors: message.colors, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.isYou ? '${message.author} (You)' : message.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.bodyMd.copyWith(color: p.text, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(timeAgo(message.at), style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.bodyMd.copyWith(color: p.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (message.isYou)
              const SizedBox(width: 36)
            else
              AnimatedScale(
                scale: cheered ? 1.1 : 1,
                duration: const Duration(milliseconds: 200),
                child: AeroCircleButton(
                  icon: Icons.local_fire_department,
                  size: 36,
                  tooltip: 'Cheer ${message.author}',
                  background: cheered
                      ? AeroColors.tangerine
                      : (p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed),
                  foreground: cheered ? Colors.white : p.accentText,
                  onPressed: onCheer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

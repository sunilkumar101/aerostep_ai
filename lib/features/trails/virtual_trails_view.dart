import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes.dart';
import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';
import 'postcards_sheet.dart';
import 'trail_painters.dart';

// Active expedition (Stitch copy).
const _trailName = 'Inca Trail to Machu Picchu';
const _doneKm = 28.5;
const _totalKm = 42.0;
const _progress = _doneKm / _totalKm; // ≈ 0.68

/// Trails tab body — "Explore World Trails" (Virtual World Adventures).
class VirtualTrailsView extends ConsumerStatefulWidget {
  const VirtualTrailsView({super.key});

  @override
  ConsumerState<VirtualTrailsView> createState() => _VirtualTrailsViewState();
}

class _VirtualTrailsViewState extends ConsumerState<VirtualTrailsView> {
  static const _filters = <(String, IconData)>[
    ('Active Trail', Icons.directions_walk),
    ('Completed', Icons.task_alt),
    ('Asia & Europe', Icons.public),
    ('Free Passes', Icons.confirmation_number),
    ('Scenic Coastal', Icons.waves),
  ];
  int _filter = 0;

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

  Future<void> _share() async {
    final steps = ref.read(activityProvider).steps;
    final today = steps > 0 ? ' Today alone: ${NumberFormat.decimalPattern().format(steps)} steps.' : '';
    await SharePlus.instance.share(
      ShareParams(
        subject: 'My AeroStep AI expedition',
        text:
            "I'm ${(_progress * 100).round()}% through the $_trailName on AeroStep AI — "
            '${_doneKm.toStringAsFixed(1)} / ${_totalKm.toStringAsFixed(1)} km walked, one step at a time.$today '
            'Zero GPS • 100% pedometer synced. 🏔️ #AeroStepAI',
      ),
    );
  }

  void _onExpedition(String name) {
    if (ref.read(trailPassProvider) != null) {
      _toast('Expedition started: $name', icon: Icons.flag);
    } else {
      context.push(AeroRoutes.unlock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final pass = ref.watch(trailPassProvider);

    return AeroScrollPage(
      children: [
        _Header(palette: p),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => AeroCategoryChip(
              label: _filters[i].$1,
              icon: _filters[i].$2,
              selected: i == _filter,
              onTap: () => setState(() => _filter = i),
            ),
          ),
        ),
        _HeroTrailCard(onResume: () => context.push(AeroRoutes.liveWalk)),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _PostcardsCard(onTap: () => showPostcardsSheet(context))),
              const SizedBox(width: 12),
              Expanded(child: _ShareCard(onShare: _share)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        AeroSectionTitle(
          'Upcoming Expeditions',
          subtitle: pass == null
              ? 'Step challenges ready to explore next'
              : 'Trail Pass active • ${_hoursLeft(pass)}h left',
          trailing: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All (18)',
                  style: AeroText.caption.copyWith(color: p.accentText, fontWeight: FontWeight.w800),
                ),
                Icon(Icons.chevron_right, size: 18, color: p.accentText),
              ],
            ),
          ),
        ),
        _ExpeditionTile(
          scene: ExpeditionScene.fuji,
          km: 14.2,
          meta: 'JAPAN • ALPINE',
          tag: 'Level 3',
          title: 'Mount Fuji 5th Station',
          subtitle: 'Sunrise Walk • Snow & Torii Gates',
          unlocked: pass != null,
          onAction: () => _onExpedition('Mount Fuji 5th Station'),
        ),
        _ExpeditionTile(
          scene: ExpeditionScene.amalfi,
          km: 8.8,
          meta: 'ITALY • COASTAL',
          tag: 'Scenic Breeze',
          title: 'Amalfi Cliffside Pathway',
          subtitle: 'Path of the Gods • Lemon groves',
          unlocked: pass != null,
          onAction: () => _onExpedition('Amalfi Cliffside Pathway'),
        ),
        _Footnote(palette: p),
      ],
    );
  }

  static int _hoursLeft(DateTime expiryUtc) =>
      expiryUtc.difference(DateTime.now().toUtc()).inHours.clamp(0, 24).toInt();
}

class _Header extends StatelessWidget {
  const _Header({required this.palette});
  final AeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AeroBadge(
              'Virtual Expeditions',
              icon: Icons.public,
              background: p.isDark ? const Color(0xFF3A2416) : AeroColors.peachFixed,
              foreground: p.accentText,
            ),
            Container(
              padding: const EdgeInsets.only(left: 2, right: 10),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingDot(size: 7, color: p.cyan),
                  const SizedBox(width: 2),
                  Text('Pedometer Live Sync', style: AeroText.caption.copyWith(color: p.text)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Explore World Trails', style: AeroText.headlineLgMobile.copyWith(color: p.text)),
        const SizedBox(height: 4),
        Text(
          'Turn every daily step into real-world geographic mileage.',
          style: AeroText.bodyMd.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}

class _HeroTrailCard extends StatefulWidget {
  const _HeroTrailCard({required this.onResume});
  final VoidCallback onResume;

  @override
  State<_HeroTrailCard> createState() => _HeroTrailCardState();
}

class _HeroTrailCardState extends State<_HeroTrailCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 14))],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => CustomPaint(
                  painter: TopoTrailPainter(progress: _progress, pulse: _pulse.value),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlassChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _AvatarStack(initials: ['MR', 'KT', 'LA']),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '+1,420 hikers now',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AeroText.caption.copyWith(color: white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _GlassChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.landscape, size: 14, color: white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Elevation: 3,820m',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AeroText.caption.copyWith(color: white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: AeroColors.tangerine, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(_progress * 100).round()}% COMPLETE',
                            style: AeroText.labelCaps.copyWith(color: AeroColors.tangerineDeep),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 96),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'HISTORICAL HIGH PASS',
                        style: AeroText.labelCaps.copyWith(color: AeroColors.peachFixed),
                      ),
                      TextSpan(
                        text: '  •  Andes Range',
                        style: AeroText.caption.copyWith(color: white),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _trailName,
                  style: AeroText.headlineMd.copyWith(color: white, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Karakoram High Pass segment enabled',
                  style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.82)),
                ),
                const SizedBox(height: 12),
                const _TrailStatsPanel(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _GlassChip(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.battery_charging_full, size: 14, color: AeroColors.skyCyan),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Zero GPS • 100% Pedometer Synced',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AeroText.labelCaps.copyWith(color: white, fontSize: 10, letterSpacing: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Resume Inca Trail Trek',
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: Ink(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AeroColors.tangerineGradient,
                            boxShadow: [BoxShadow(color: Color(0x66FF7A2F), blurRadius: 16, offset: Offset(0, 6))],
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onResume,
                            child: const Icon(Icons.arrow_outward, color: white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailStatsPanel extends StatelessWidget {
  const _TrailStatsPanel();

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AeroColors.charcoal.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      Text(_doneKm.toStringAsFixed(1), style: AeroText.metricLg.copyWith(color: white)),
                      const SizedBox(width: 4),
                      Text(
                        '/ ${_totalKm.toStringAsFixed(1)} km Done',
                        style: AeroText.numeric(13, weight: FontWeight.w600, color: white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${(_totalKm - _doneKm).toStringAsFixed(1)} km Left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.numeric(13, weight: FontWeight.w700, color: AeroColors.skyCyan),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: white.withValues(alpha: 0.18))),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AeroColors.tangerine, AeroColors.skyCyan]),
                          boxShadow: [BoxShadow(color: Color(0x8046CFFE), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 14, color: white.withValues(alpha: 0.85)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Est. 3 days remaining',
                      style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
              Text(
                '11,400 STEPS/DAY PACE',
                style: AeroText.labelCaps.copyWith(color: white.withValues(alpha: 0.85), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: child,
  );
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.initials});
  final List<String> initials;

  static const _fills = [AeroColors.tangerine, AeroColors.telemetryCyan, Color(0xFF934B13)];

  @override
  Widget build(BuildContext context) {
    const d = 20.0;
    return SizedBox(
      width: d + (initials.length - 1) * 13,
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < initials.length; i++)
            Positioned(
              left: i * 13,
              child: Container(
                width: d,
                height: d,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _fills[i % _fills.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(initials[i], style: AeroText.labelCaps.copyWith(fontSize: 7, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostcardsCard extends StatelessWidget {
  const _PostcardsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return TangerineCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -26,
            bottom: -30,
            child: Icon(Icons.emergency, size: 110, color: white.withValues(alpha: 0.16)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AeroIconTile(icon: Icons.loyalty, background: white.withValues(alpha: 0.22), foreground: white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AeroBadge('Milestone', background: white.withValues(alpha: 0.22), foreground: white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('12', style: AeroText.displayHeroMobile.copyWith(color: white)),
                    const SizedBox(width: 4),
                    Text('cards', style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              Text(
                'Collectible Postcards',
                style: AeroText.titleMd.copyWith(color: white, fontWeight: FontWeight.w800, height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(
                'Machu Picchu Sun Gate stamp earned today! Tap to open.',
                style: AeroText.caption.copyWith(color: white.withValues(alpha: 0.9)),
              ),
              const Spacer(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'VIEW GALLERY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AeroText.labelCaps.copyWith(color: white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: white),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.onShare});
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final cyanSoft = p.isDark ? AeroColors.cyanDeep.withValues(alpha: 0.45) : AeroColors.cyanFixed;
    final cyanFg = p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep;
    return BentoCard(
      onTap: onShare,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.alphaBlend(AeroColors.skyCyan.withValues(alpha: p.isDark ? 0.14 : 0.16), p.card),
          p.card,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AeroIconTile(icon: Icons.share, background: cyanSoft, foreground: cyanFg),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AeroBadge('Story Ready', background: cyanSoft, foreground: cyanFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('1-Tap Share', style: AeroText.titleMd.copyWith(color: p.text)),
          const SizedBox(height: 6),
          Text(
            'Showcase milestone to WhatsApp & IG Story with live stats.',
            style: AeroText.caption.copyWith(color: p.textMuted),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          AeroPillButton(
            label: 'Share Card',
            icon: Icons.auto_awesome,
            tone: AeroButtonTone.cyan,
            height: 40,
            expand: true,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}

class _ExpeditionTile extends StatelessWidget {
  const _ExpeditionTile({
    required this.scene,
    required this.km,
    required this.meta,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.onAction,
  });

  final ExpeditionScene scene;
  final double km;
  final String meta;
  final String tag;
  final String title;
  final String subtitle;
  final bool unlocked;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      padding: const EdgeInsets.all(12),
      radius: 24,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: ExpeditionThumbPainter(scene))),
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AeroColors.charcoal.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${km.toStringAsFixed(1)} km', style: AeroText.numeric(10, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: meta,
                        style: AeroText.labelCaps.copyWith(color: p.accentText, fontSize: 10),
                      ),
                      TextSpan(
                        text: '  •  $tag',
                        style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.bodyLg.copyWith(color: p.text, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: unlocked
                ? AeroPillButton(
                    key: const ValueKey('start'),
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    height: 36,
                    onPressed: onAction,
                  )
                : _UnlockPill(key: const ValueKey('unlock'), onTap: onAction),
          ),
        ],
      ),
    );
  }
}

class _UnlockPill extends StatelessWidget {
  const _UnlockPill({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Material(
      color: p.chip,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_open, size: 15, color: p.text),
              const SizedBox(width: 4),
              Text(
                'Unlock',
                style: AeroText.caption.copyWith(color: p.text, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.palette});
  final AeroPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.isDark ? AeroColors.tangerine.withValues(alpha: 0.12) : AeroColors.peachFixed.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const AeroIconTile(icon: Icons.hiking, background: AeroColors.tangerine, foreground: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AeroText.caption.copyWith(color: p.text, fontSize: 13, height: 1.35),
                children: [
                  const TextSpan(text: "You're pacing faster than "),
                  TextSpan(
                    text: '78%',
                    style: AeroText.numeric(13, color: p.accentText),
                  ),
                  const TextSpan(text: " of Andean hikers today! Keep walking to reach Dead Woman's Pass."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

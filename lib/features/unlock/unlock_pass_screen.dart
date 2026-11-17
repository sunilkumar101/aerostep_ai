import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/state/activity_state.dart';
import '../../design_system/design_system.dart';
import 'reward_ad_gateway.dart';

enum _Reward { shield, trail }

enum _Plan { annual, monthly }

/// Ethical Unlock Pass & Pro VIP modal (Stitch `aerostep_ai_unlock_pass_pro_vip`).
/// Ads are only ever shown after an explicit tap on "Watch Video to Unlock".
class UnlockPassScreen extends ConsumerStatefulWidget {
  const UnlockPassScreen({super.key});

  @override
  ConsumerState<UnlockPassScreen> createState() => _UnlockPassScreenState();
}

class _UnlockPassScreenState extends ConsumerState<UnlockPassScreen> {
  _Reward _reward = _Reward.shield;
  _Plan _plan = _Plan.annual;
  bool _loading = false;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AeroRoutes.home);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _watchVideo() async {
    if (_loading) return;
    setState(() => _loading = true);
    var earned = false;
    try {
      earned = await ref.read(rewardAdGatewayProvider).showRewarded();
    } catch (_) {
      earned = false;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (!earned) {
      _snack("No video available right now — try again later (you're offline or no ad is ready).");
      return;
    }

    final reward = _reward;
    if (reward == _Reward.shield) {
      ref.read(streakShieldProvider.notifier).add(1);
    } else {
      ref.read(trailPassProvider.notifier).grant24h();
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _RewardDialog(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AeroCanvas(
        child: AeroScrollPage(
          dockClearance: false,
          gap: 14,
          children: [
            Row(
              children: [
                AeroCircleButton(icon: Icons.close_rounded, onPressed: _close, size: 44, tooltip: 'Close'),
                Expanded(
                  child: Text(
                    'Unlock Pass & Pro VIP',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.titleMd.copyWith(color: p.text),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            Row(
              children: [
                Flexible(
                  child: AeroBadge(
                    'No popup ads promise',
                    icon: Icons.verified_rounded,
                    background: p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed,
                    foreground: p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep,
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AeroColors.skyCyan, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('Daily Boost Ready', style: AeroText.caption.copyWith(color: p.textMuted)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unlock Pass & Upgrades', style: AeroText.headlineLgMobile.copyWith(color: p.text)),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to fuel your movement journey today.',
                  style: AeroText.bodyMd.copyWith(color: p.textMuted),
                ),
              ],
            ),
            _DailyRewardCard(
              reward: _reward,
              loading: _loading,
              onReward: (r) => setState(() => _reward = r),
              onWatch: _watchVideo,
            ),
            _ProVipSheet(
              plan: _plan,
              onPlan: (pl) => setState(() => _plan = pl),
              onStart: () => _snack('Subscriptions coming soon'),
              onRestore: () => _snack('Subscriptions coming soon — nothing to restore yet.'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Rewarded videos only play when you tap. No pop-ups, ever.',
                textAlign: TextAlign.center,
                style: AeroText.caption.copyWith(color: p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Free daily reward pass
// ---------------------------------------------------------------------------

class _DailyRewardCard extends ConsumerWidget {
  const _DailyRewardCard({
    required this.reward,
    required this.loading,
    required this.onReward,
    required this.onWatch,
  });

  final _Reward reward;
  final bool loading;
  final ValueChanged<_Reward> onReward;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.aero;
    final shields = ref.watch(streakShieldProvider);
    final trail = ref.watch(trailPassProvider);
    final cyanBg = p.isDark ? const Color(0xFF103542) : AeroColors.cyanFixed;
    final cyanFg = p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep;
    final ctaBg = p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep;
    final ctaFg = p.isDark ? AeroColors.onCyanFixed : Colors.white;

    String status;
    if (reward == _Reward.shield) {
      status = 'You own $shields Streak ${shields == 1 ? 'Shield' : 'Shields'}.';
    } else if (trail != null) {
      final left = trail.difference(DateTime.now().toUtc());
      final h = left.inHours;
      final m = left.inMinutes % 60;
      status = 'Trail Pass active • ${h}h ${m}m left (watching again resets to 24h).';
    } else {
      status = 'Unlocks every World Trail for 24 hours.';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: IgnorePointer(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AeroColors.skyCyan.withValues(alpha: 0.25), AeroColors.skyCyan.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: AeroBadge(
                        'Daily reward pass • 100% free',
                        icon: Icons.bolt_rounded,
                        background: cyanBg,
                        foreground: cyanFg,
                      ),
                    ),
                    const Spacer(),
                    AeroIconTile(icon: Icons.smart_display_outlined, size: 42, background: cyanBg, foreground: cyanFg),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Watch 1 Short Video (Free)', style: AeroText.titleMd.copyWith(color: p.text)),
                const SizedBox(height: 4),
                Text(
                  'Unlock Streak Shield or World Trail Pass instantly. Zero intrusive banners or popups.',
                  style: AeroText.bodyMd.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _RewardChip(
                        label: '1x Streak Shield',
                        icon: Icons.shield_rounded,
                        selected: reward == _Reward.shield,
                        onTap: loading ? null : () => onReward(_Reward.shield),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RewardChip(
                        label: '24h Trail Pass',
                        icon: Icons.map_rounded,
                        selected: reward == _Reward.trail,
                        onTap: loading ? null : () => onReward(_Reward.trail),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(status, style: AeroText.caption.copyWith(color: p.textMuted)),
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label: loading ? 'Loading video' : 'Watch video to unlock',
                  child: Material(
                    color: ctaBg.withValues(alpha: loading ? 0.75 : 1),
                    shape: const StadiumBorder(),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: loading ? null : onWatch,
                      child: SizedBox(
                        height: 54,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (loading)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: ctaFg),
                              )
                            else
                              Icon(Icons.play_arrow_rounded, color: ctaFg),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                loading ? 'Loading video…' : 'Watch Video to Unlock (30s)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.bodyLg.copyWith(color: ctaFg, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final fg = selected ? (p.isDark ? AeroColors.skyCyan : AeroColors.cyanDeep) : p.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AeroColors.skyCyan.withValues(alpha: p.isDark ? 0.18 : 0.22) : p.chip,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AeroColors.skyCyan.withValues(alpha: 0.6) : Colors.transparent),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.caption.copyWith(
                      color: selected ? p.text : p.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardDialog extends StatelessWidget {
  const _RewardDialog({required this.reward});
  final _Reward reward;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final shield = reward == _Reward.shield;
    return Dialog(
      backgroundColor: p.isDark ? AeroColors.espressoCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AeroColors.tangerineGradient),
              child: Icon(shield ? Icons.shield_rounded : Icons.map_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Reward Unlocked!',
              textAlign: TextAlign.center,
              style: AeroText.headlineMd.copyWith(color: p.text),
            ),
            const SizedBox(height: 6),
            Text(
              shield
                  ? '1x Streak Shield added. It auto-deploys on a rest day so your streak stays safe.'
                  : '24h World Trail Pass active. Every virtual trail is open until this time tomorrow.',
              textAlign: TextAlign.center,
              style: AeroText.bodyMd.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: 20),
            AeroPillButton(
              label: 'Awesome',
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pro VIP (#141416 + Tangerine)
// ---------------------------------------------------------------------------

class _ProVipSheet extends StatelessWidget {
  const _ProVipSheet({
    required this.plan,
    required this.onPlan,
    required this.onStart,
    required this.onRestore,
  });

  final _Plan plan;
  final ValueChanged<_Plan> onPlan;
  final VoidCallback onStart;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final white70 = Colors.white.withValues(alpha: 0.72);
    final annual = plan == _Plan.annual;
    return CharcoalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingDot(color: AeroColors.tangerine, size: 7),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'UNLIMITED KINETIC POWER',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.all_inclusive_rounded, size: 16, color: AeroColors.peachFixed),
                const SizedBox(width: 4),
                Text('Lifetime Sync', style: AeroText.caption.copyWith(color: white70)),
              ],
            ),
          ),
          TangerineCard(
            padding: EdgeInsets.zero,
            radius: 24,
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  bottom: 40,
                  child: IgnorePointer(
                    child: Icon(Icons.star_rounded, size: 200, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          AeroBadge(
                            'AeroStep Pro VIP',
                            icon: Icons.stars_rounded,
                            background: Colors.white.withValues(alpha: 0.22),
                            foreground: Colors.white,
                          ),
                          const AeroBadge(
                            'Best value • 7-day trial',
                            background: Colors.white,
                            foreground: AeroColors.charcoal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unlimited AI Coach, All World Trails & Cloud Backup',
                        style: AeroText.headlineMd.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Unlock real-time biomechanics voice telemetry and 3D kinetic maps.',
                        style: AeroText.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 14),
                      _PlanRow(
                        selected: annual,
                        title: 'Annual Pass',
                        save: 'SAVE 37%',
                        subtitle: r'Billed at $14.99/yr ($1.25/mo)',
                        price: r'$14.99',
                        per: 'PER YEAR',
                        onTap: () => onPlan(_Plan.annual),
                      ),
                      const SizedBox(height: 8),
                      _PlanRow(
                        selected: !annual,
                        title: 'Monthly Flexibility',
                        subtitle: 'Cancel anytime, auto-renews',
                        price: r'$1.99',
                        per: 'PER MO',
                        onTap: () => onPlan(_Plan.monthly),
                      ),
                      const SizedBox(height: 14),
                      for (final f in const [
                        'Unlimited Stride AI Voice Cadence Coaching',
                        'All 24+ Global 3D Virtual World Trails (Inca, Fuji, Alps)',
                        'Automatic Rest-Day Streak Shields & Cloud Sync',
                        'Zero Advertisements Forever & Gyro Telemetry Core',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(f, style: AeroText.bodyMd.copyWith(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Expanded(
                            child: _TrailThumb(
                              label: 'Inca Trail',
                              icon: Icons.terrain_rounded,
                              colors: [Color(0xFF2F6B3A), Color(0xFF9CBF6A)],
                            ),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: _TrailThumb(
                              label: 'Mt. Fuji 3D',
                              icon: Icons.filter_hdr_rounded,
                              colors: [Color(0xFF4A6FA5), Color(0xFFF4B6C2)],
                            ),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: _TrailThumb(
                              label: 'Swiss Pass',
                              icon: Icons.landscape_rounded,
                              colors: [Color(0xFF2D4A3E), Color(0xFFE89A5B)],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.white,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: onStart,
                          child: SizedBox(
                            height: 54,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    annual ? 'Start 7-Day Free Trial' : r'Unlock Monthly Pass ($1.99)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AeroText.bodyLg.copyWith(
                                      color: AeroColors.tangerineDeep,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, color: AeroColors.tangerineDeep, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        annual
                            ? r'Then $14.99/year. Cancel anytime in 1-tap with Google Play / App Store.'
                            : r'Renews at $1.99/month until cancelled. Pause anytime.',
                        textAlign: TextAlign.center,
                        style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.88)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 15, color: AeroColors.peachFixed),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'On-device privacy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.caption.copyWith(color: white70),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: onRestore,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restore_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Restore', style: AeroText.caption.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.per,
    required this.onTap,
    this.save,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String price;
  final String per;
  final String? save;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected row is a white card: force dark text (TangerineCard defaults to white).
    final fg = selected ? AeroColors.onSurface : Colors.white;
    final muted = selected ? AeroColors.onSurfaceVariant : Colors.white.withValues(alpha: 0.8);
    final priceColor = selected ? AeroColors.tangerineDeep : Colors.white;
    final br = BorderRadius.circular(18);
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: br,
          boxShadow: selected ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4))] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AeroColors.tangerineDeep : Colors.white.withValues(alpha: 0.3),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(title, style: AeroText.bodyLg.copyWith(color: fg, fontWeight: FontWeight.w800)),
                            if (save != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AeroColors.peachFixed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  save!,
                                  style: AeroText.labelCaps.copyWith(color: AeroColors.tangerineDeep, fontSize: 9),
                                ),
                              ),
                          ],
                        ),
                        Text(subtitle, style: AeroText.caption.copyWith(color: muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: AeroText.numeric(20, color: priceColor)),
                      Text(per, style: AeroText.labelCaps.copyWith(color: muted, fontSize: 8)),
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

class _TrailThumb extends StatelessWidget {
  const _TrailThumb({required this.label, required this.icon, required this.colors});
  final String label;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
        height: 62,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: colors),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: -4,
              child: Icon(icon, size: 46, color: Colors.white.withValues(alpha: 0.35)),
            ),
            Positioned(
              left: 6,
              right: 4,
              bottom: 5,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AeroText.caption.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

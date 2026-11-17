import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'onboarding_widgets.dart';

/// Onboarding step 1. Renders the Stitch light (`aerostep_ai_onboarding_welcome_light`)
/// or espresso-dark (`aerostep_ai_onboarding_welcome_dark_mode`) variant from the
/// current theme brightness.
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    void getStarted() {
      HapticFeedback.lightImpact();
      context.push(AeroRoutes.setup);
    }

    // Skip the intro entirely: keep defaults (10k goal, auto-pause on) and launch.
    void skip() {
      ref.read(userProfileProvider.notifier).completeOnboarding();
      context.go(AeroRoutes.home);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? AeroColors.espresso : AeroColors.surfaceLight,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: dark
              ? _DarkWelcome(key: const ValueKey('dark'), onGetStarted: getStarted, onSkip: skip)
              : _LightWelcome(key: const ValueKey('light'), onGetStarted: getStarted, onSkip: skip),
        ),
      ),
    );
  }
}

const _headline1 = 'Step Today,';
const _body = 'Accurate offline step tracking, zero GPS battery drain, and smart vehicle auto-pause.';

// ───────────────────────────── LIGHT ─────────────────────────────

class _LightWelcome extends StatelessWidget {
  const _LightWelcome({super.key, required this.onGetStarted, required this.onSkip});
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: OnboardingFillScroll(
        child: Column(
          children: [
            Expanded(child: _LightHero(onSkip: onSkip)),
            Transform.translate(
              offset: const Offset(0, -24),
              child: _LightSheet(onGetStarted: onGetStarted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightHero extends StatelessWidget {
  const _LightHero({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    // NOTE: no LayoutBuilder here — the onboarding scroll wrapper measures
    // intrinsic heights, which LayoutBuilder does not support.
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Establishes the hero's minimum (intrinsic) height on short screens.
        const SizedBox(height: 260, width: double.infinity),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDFB), Color(0xFFFFF1E6), Color(0xFFFDE8D7)],
              ),
            ),
          ),
        ),
        const Positioned(top: -64, right: -64, child: GlowOrb(color: AeroColors.tangerine, size: 320, opacity: 0.22)),
        const Positioned(
          top: 0,
          bottom: 0,
          left: -80,
          child: Align(
            alignment: Alignment(0, -0.2),
            child: GlowOrb(color: AeroColors.skyCyan, size: 288, opacity: 0.16),
          ),
        ),
        Positioned(
          top: 48,
          left: 24,
          child: DecoMark(color: AeroColors.tangerineDeep.withValues(alpha: 0.25), size: 28, rotation: 0.21),
        ),
        Positioned(
          top: 112,
          right: 32,
          child: DecoMark(color: const Color(0xFF934B13).withValues(alpha: 0.2), size: 20, rotation: -0.6),
        ),
        Positioned(
          bottom: 96,
          left: 32,
          child: DecoMark(color: AeroColors.tangerineDeep.withValues(alpha: 0.15), size: 18),
        ),
        Positioned.fill(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Flexible(child: _BrandPill()),
                    const SizedBox(width: 8),
                    const OnboardingThemeToggle(),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.white.withValues(alpha: 0.4),
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onSkip,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          child: Text(
                            'Skip',
                            style: AeroText.caption.copyWith(color: AeroColors.onSurfaceVariant, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  // Bottom inset = the 24px the sheet overlaps the hero.
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          const Positioned.fill(child: HeroRunnerImage(dark: false)),
                          Positioned(
                            left: -12,
                            right: -12,
                            bottom: -1,
                            height: 112,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      const Color(0xFFFDE8D7),
                                      const Color(0xFFFDE8D7).withValues(alpha: 0.6),
                                      const Color(0x00FDE8D7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Positioned(right: -8, bottom: 12, child: _PrecisionCapsule()),
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
    );
  }
}

class _BrandPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PulsingDot(color: AeroColors.tangerine, size: 8),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'AEROSTEP AI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.labelCaps.copyWith(color: AeroColors.onSurface, fontSize: 12, letterSpacing: 1.2),
          ),
        ),
      ],
    ),
  );
}

class _PrecisionCapsule extends StatelessWidget {
  const _PrecisionCapsule();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -2 * math.pi / 180,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingDot(color: AeroColors.cyanDeep, size: 7),
          const SizedBox(width: 2),
          Text(
            'ZERO BATTERY DRAIN • 99.4% PRECISION',
            style: AeroText.labelCaps.copyWith(color: AeroColors.cyanDeep, fontSize: 10, letterSpacing: 0.2),
          ),
        ],
      ),
    ),
  );
}

class _LightSheet extends StatelessWidget {
  const _LightSheet({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: AeroColors.charcoal,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(color: AeroColors.charcoal.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 18)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingDots(inactive: Color(0xFF303032)),
            const SizedBox(height: 18),
            Text('$_headline1\nShine Tomorrow.', style: AeroText.headlineLgMobile.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(_body, style: AeroText.bodyMd.copyWith(color: const Color(0xFFE5E1E4), height: 1.6)),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  icon: Icons.bolt_rounded,
                  iconColor: Color(0xFFFFC233),
                  label: '0% GPS DRAIN',
                  labelColor: AeroColors.peachFixed,
                ),
                _FeatureChip(
                  icon: Icons.directions_car_rounded,
                  iconColor: Color(0xFFFF5A4E),
                  label: 'AUTO-PAUSE IN TRANSIT',
                  labelColor: AeroColors.cyanFixed,
                ),
              ],
            ),
            const SizedBox(height: 20),
            OnboardingPillCta(label: 'Get Started', icon: Icons.directions_run_rounded, onPressed: onGetStarted),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'No account needed to start tracking • Privacy first',
                textAlign: TextAlign.center,
                style: AeroText.caption.copyWith(color: const Color(0xFFEAE7EA).withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.iconColor, required this.label, required this.labelColor});
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE5E1E4).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AeroText.labelCaps.copyWith(color: labelColor),
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────────── DARK ─────────────────────────────

const _darkCanvas = Color(0xFF12100E);
const _darkCard = Color(0xFF1C1714);
const _darkMuted = Color(0xFFA89F99);
const _darkTile = Color(0xFF251F1A);
const _darkTileIcon = Color(0xFF332A23);

class _DarkWelcome extends StatelessWidget {
  const _DarkWelcome({super.key, required this.onGetStarted, required this.onSkip});
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _darkCanvas,
      child: Stack(
        children: [
          const Positioned(top: -96, left: -80, child: GlowOrb(color: AeroColors.tangerine, size: 320, opacity: 0.18)),
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(child: GlowOrb(color: AeroColors.tangerineDeep, size: 384, opacity: 0.18)),
          ),
          SafeArea(
            child: OnboardingFillScroll(
              child: Column(
                children: [
                  Expanded(child: _DarkHero(onSkip: onSkip)),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: _DarkCard(onGetStarted: onGetStarted),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkHero extends StatelessWidget {
  const _DarkHero({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const SizedBox(height: 280, width: double.infinity),
        Positioned.fill(
          child: Opacity(
            opacity: 0.92,
            child: Transform.scale(
              scale: 1.05,
              child: const HeroRunnerImage(dark: true, fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
          ),
        ),
        // Cinematic vignettes.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_darkCanvas, _darkCanvas.withValues(alpha: 0.4), _darkCanvas.withValues(alpha: 0)],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkCanvas.withValues(alpha: 0.7), _darkCanvas.withValues(alpha: 0)],
                  stops: const [0, 0.45],
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          bottom: 0,
          right: -96,
          child: Align(
            alignment: Alignment(0, -0.33),
            child: GlowOrb(color: AeroColors.skyCyan, size: 288, opacity: 0.12),
          ),
        ),
        Positioned(
          top: 64,
          right: 40,
          child: DecoMark(color: AeroColors.peachFixed.withValues(alpha: 0.3), size: 18, shape: MarkShape.sparkle),
        ),
        Positioned(
          top: 176,
          left: 24,
          child: DecoMark(color: AeroColors.cyanFixed.withValues(alpha: 0.2), size: 14, shape: MarkShape.sparkle),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 14,
          child: Row(
            children: [
              const Expanded(child: _DarkBrand()),
              const SizedBox(width: 8),
              const OnboardingThemeToggle(label: 'Dark Edition'),
              const SizedBox(width: 2),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: _darkMuted,
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: const StadiumBorder(),
                ),
                child: Text('Skip', style: AeroText.caption.copyWith(color: _darkMuted, fontSize: 13)),
              ),
            ],
          ),
        ),
        // Bottom inset = the 16px the card overlaps the hero.
        const Positioned(left: 16, right: 16, bottom: 28, child: Center(child: _BiomechanicalBadge())),
      ],
    );
  }
}

class _DarkBrand extends StatelessWidget {
  const _DarkBrand();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _darkCard,
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color.alphaBlend(AeroColors.tangerine.withValues(alpha: 0.4), _darkCard),
              Color.alphaBlend(AeroColors.skyCyan.withValues(alpha: 0.4), _darkCard),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AeroColors.tangerineDeep.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.directions_run_rounded, size: 20, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'AeroStep'),
                  const TextSpan(
                    text: '.ai',
                    style: TextStyle(color: AeroColors.tangerine),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.titleMd.copyWith(color: Colors.white, height: 1.1, letterSpacing: -0.3),
            ),
            const SizedBox(height: 2),
            Text(
              'KINETIC OS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroText.labelCaps.copyWith(color: _darkMuted, fontSize: 9, letterSpacing: 1.6),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BiomechanicalBadge extends StatelessWidget {
  const _BiomechanicalBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: _darkCard.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(99),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingDot(color: AeroColors.skyCyan, size: 8),
          const SizedBox(width: 4),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'BIOMECHANICAL HUB • '),
                TextSpan(
                  text: '0.02% BATTERY/HR',
                  style: TextStyle(color: AeroColors.cyanFixed),
                ),
              ],
            ),
            style: AeroText.labelCaps.copyWith(color: const Color(0xFFE5DFDA), letterSpacing: 1.1),
          ),
        ],
      ),
    ),
  );
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final headline = AeroText.headlineLgMobile.copyWith(color: Colors.white);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: _darkCard.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 48, offset: const Offset(0, 24)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const OnboardingDots(inactive: Color(0xFF38312B), activeWidth: 28),
            const SizedBox(height: 20),
            Text(_headline1, style: headline),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [Colors.white, AeroColors.peachFixed, AeroColors.tangerine],
              ).createShader(r),
              child: Text('Shine Tomorrow', style: headline),
            ),
            const SizedBox(height: 10),
            Text(_body, style: AeroText.bodyMd.copyWith(color: _darkMuted, height: 1.6)),
            const SizedBox(height: 20),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TelemetryTile(
                    icon: Icons.battery_charging_full_rounded,
                    iconColor: AeroColors.tangerine,
                    title: 'Zero GPS Drain',
                    subtitle: 'Passive Hardware',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _TelemetryTile(
                    icon: Icons.directions_car_rounded,
                    iconColor: AeroColors.skyCyan,
                    title: 'Auto-Pause Transit',
                    subtitle: 'AI Velocity Gate',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OnboardingPillCta(
              label: 'Get Started',
              icon: Icons.directions_walk_rounded,
              emblemSize: 48,
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
              labelWeight: FontWeight.w700,
              shadowColor: AeroColors.tangerine.withValues(alpha: 0.2),
              onPressed: onGetStarted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryTile extends StatelessWidget {
  const _TelemetryTile({required this.icon, required this.iconColor, required this.title, required this.subtitle});
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final iconBubble = Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _darkTileIcon),
      child: Icon(icon, size: 18, color: iconColor),
    );
    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AeroText.numeric(12, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AeroText.caption.copyWith(color: _darkMuted, fontSize: 10, height: 1.3),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _darkTile, borderRadius: BorderRadius.circular(16)),
      // Stack icon above the text on narrow phones so titles don't truncate
      // (MediaQuery instead of LayoutBuilder: this subtree is intrinsically measured).
      child: MediaQuery.sizeOf(context).width < 380
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [iconBubble, const SizedBox(height: 8), texts],
            )
          : Row(
              children: [
                iconBubble,
                const SizedBox(width: 10),
                Expanded(child: texts),
              ],
            ),
    );
  }
}

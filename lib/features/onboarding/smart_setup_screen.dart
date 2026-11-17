import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'oem_battery_hooks.dart';
import 'onboarding_widgets.dart';

/// Onboarding step 2 — Stitch `aerostep_ai_smart_setup_battery_protection_light`:
/// interactive step-goal dial + slider, 1-Tap OEM battery protection selector,
/// vehicle auto-pause switch and "Complete Setup & Launch".
class SmartSetupScreen extends ConsumerStatefulWidget {
  const SmartSetupScreen({super.key});

  @override
  ConsumerState<SmartSetupScreen> createState() => _SmartSetupScreenState();
}

const _minGoal = 4000;
const _maxGoal = 16000;
const _goalStep = 500;
const _recommendedGoal = 10000;

/// ~0.042 kcal per step (420 kcal @ 10,000 steps, matching the Stitch mock).
const _kcalPerStep = 0.042;

class _SmartSetupScreenState extends ConsumerState<SmartSetupScreen> {
  late int _goal;
  String? selectedOem;

  @override
  void initState() {
    super.initState();
    _goal = _snap(ref.read(userProfileProvider).stepGoal);
  }

  static int _snap(num v) => ((v.clamp(_minGoal, _maxGoal) / _goalStep).round() * _goalStep).toInt();

  void _setGoal(num v) {
    final next = _snap(v);
    if (next == _goal) return;
    HapticFeedback.selectionClick();
    setState(() => _goal = next);
  }

  Future<void> onOemSelected(String oem) async {
    HapticFeedback.selectionClick();
    setState(() => selectedOem = oem);
    await requestOemBatteryProtection(oem);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AeroRoutes.onboarding);
    }
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    final profile = ref.read(userProfileProvider.notifier);
    profile.setStepGoal(_goal);
    profile.completeOnboarding();
    context.go(AeroRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final profile = ref.watch(userProfileProvider);
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.isDark ? AeroColors.espresso : AeroColors.surfaceLight,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              _GoalPanel(
                topInset: pad.top,
                goal: _goal,
                strideM: profile.strideLengthM,
                onBack: _back,
                onReset: () => _setGoal(_recommendedGoal),
                onGoalChanged: _setGoal,
              ),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProtectionSheet(
                    selectedOem: selectedOem,
                    onOemSelected: onOemSelected,
                    autoPause: profile.autoPauseVehicles,
                    onAutoPauseChanged: ref.read(userProfileProvider.notifier).setAutoPause,
                    onComplete: _complete,
                  ),
                ),
              ),
              SizedBox(height: pad.bottom + 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Top: goal calibration panel ─────────────────────────

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({
    required this.topInset,
    required this.goal,
    required this.strideM,
    required this.onBack,
    required this.onReset,
    required this.onGoalChanged,
  });

  final double topInset;
  final int goal;
  final double strideM;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final ValueChanged<num> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final dark = p.isDark;
    final width = MediaQuery.sizeOf(context).width;
    final dialSize = (width * 0.62).clamp(176.0, 240.0);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF12100E), Color(0xFF1A1411), Color(0xFF2A1D15)]
              : const [Color(0xFFFFFDFB), Color(0xFFFFF5ED), Color(0xFFFDE8D7)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -64,
            right: -48,
            child: GlowOrb(color: dark ? AeroColors.tangerine : AeroColors.peachFixedDim, size: 256, opacity: 0.35),
          ),
          Positioned(
            top: 176,
            left: -64,
            child: GlowOrb(color: AeroColors.cyanFixed, size: 224, opacity: dark ? 0.08 : 0.4),
          ),
          Positioned(
            top: topInset + 64,
            left: 24,
            child: DecoMark(
              color: AeroColors.peachFixedDim.withValues(alpha: 0.4),
              size: 22,
              shape: MarkShape.sparkle,
              rotation: 0.2,
            ),
          ),
          Positioned(
            top: topInset + 140,
            right: 32,
            child: DecoMark(color: AeroColors.peachFixedDim.withValues(alpha: 0.4), size: 20, rotation: -0.8),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: DecoMark(
              color: AeroColors.tangerine.withValues(alpha: 0.2),
              size: 26,
              shape: MarkShape.sparkle,
              rotation: 0.78,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 28),
            child: Column(
              children: [
                _Header(onBack: onBack, onReset: onReset),
                const SizedBox(height: 16),
                SizedBox.square(
                  dimension: dialSize,
                  child: FittedBox(child: _GoalDial(goal: goal)),
                ),
                const SizedBox(height: 10),
                _MetabolismPill(goal: goal, strideM: strideM),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _GoalSlider(goal: goal, onChanged: onGoalChanged),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onReset});
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final pillBg = p.isDark ? p.card : Colors.white.withValues(alpha: 0.9);
    return Row(
      children: [
        AeroCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          size: 40,
          tooltip: 'Back',
          background: p.isDark ? p.card : Colors.white.withValues(alpha: 0.85),
          foreground: p.text,
          onPressed: onBack,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulsingDot(color: p.accentText, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      'STEP 2 OF 2 • SMART SETUP',
                      style: AeroText.labelCaps.copyWith(color: p.textMuted, letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AeroCircleButton(
          icon: Icons.tune_rounded,
          size: 40,
          tooltip: 'Reset to recommended 10,000',
          background: AeroColors.tangerine.withValues(alpha: p.isDark ? 0.18 : 0.12),
          foreground: p.accentText,
          onPressed: onReset,
        ),
      ],
    );
  }
}

/// Circular goal gauge, laid out at a fixed 224px and scaled by the parent.
class _GoalDial extends StatelessWidget {
  const _GoalDial({required this.goal});
  final int goal;

  static const _size = 224.0;
  static const _stroke = 13.0;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final dark = p.isDark;
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProgressRing(
            value: (goal / 12500).clamp(0.1, 1.0),
            size: _size,
            stroke: _stroke,
            gradient: const [AeroColors.tangerine, AeroColors.tangerineLight, AeroColors.tangerine],
            track: dark ? p.track : AeroColors.surfaceContainer,
          ),
          Container(
            width: _size - (_stroke + 10) * 2,
            height: _size - (_stroke + 10) * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? AeroColors.espressoCard : Colors.white.withValues(alpha: 0.96),
              boxShadow: [
                BoxShadow(
                  color: dark ? Colors.black.withValues(alpha: 0.45) : AeroColors.tangerine.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF3A2416) : AeroColors.peachFixed.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: p.accentText),
                        const SizedBox(width: 3),
                        Text(
                          'DAILY TARGET',
                          style: AeroText.labelCaps.copyWith(
                            color: dark ? AeroColors.peachFixed : const Color(0xFF351000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_fmt(goal), maxLines: 1, style: AeroText.displayHeroMobile.copyWith(color: p.text)),
                ),
                Text('STEPS / DAY', style: AeroText.caption.copyWith(color: p.textMuted, letterSpacing: 0.4)),
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 18,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AeroColors.tangerine,
                boxShadow: [
                  BoxShadow(
                    color: AeroColors.tangerine.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.local_fire_department_rounded, size: 17, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetabolismPill extends StatelessWidget {
  const _MetabolismPill({required this.goal, required this.strideM});
  final int goal;
  final double strideM;

  static String _profileFor(int goal) => switch (goal) {
    < 7000 => 'Light Activity',
    < 10000 => 'Steady Metabolism',
    < 13000 => 'Active Metabolism',
    _ => 'Athletic Endurance',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final kcal = (goal * _kcalPerStep).round();
    final km = goal * strideM / 1000;
    final metricStyle = AeroText.numeric(12, weight: FontWeight.w600, color: p.textMuted).copyWith(letterSpacing: 0.4);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Recommended for '),
                TextSpan(
                  text: _profileFor(goal),
                  style: TextStyle(color: p.accentText, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AeroText.caption.copyWith(color: p.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 14,
                  color: p.isDark ? AeroColors.tangerine : const Color(0xFF934B13),
                ),
                const SizedBox(width: 3),
                Text('$kcal kcal', style: metricStyle),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('•', style: metricStyle),
                ),
                Icon(Icons.location_on_outlined, size: 14, color: p.cyan),
                const SizedBox(width: 3),
                Text('${km.toStringAsFixed(1)} km', style: metricStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSlider extends StatelessWidget {
  const _GoalSlider({required this.goal, required this.onChanged});
  final int goal;
  final ValueChanged<num> onChanged;

  static const _milestones = [6000, 8000, 10000, 12000, 15000];

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            activeTrackColor: AeroColors.tangerine,
            inactiveTrackColor: p.isDark ? p.track : AeroColors.surfaceHigh,
            thumbColor: AeroColors.tangerine,
            overlayColor: AeroColors.tangerine.withValues(alpha: 0.14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 3),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            trackShape: const RoundedRectSliderTrackShape(),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: goal.toDouble(),
            min: _minGoal.toDouble(),
            max: _maxGoal.toDouble(),
            divisions: (_maxGoal - _minGoal) ~/ _goalStep,
            label: '${_fmt(goal)} steps',
            semanticFormatterCallback: (v) => '${_fmt(v.round())} steps per day',
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in _milestones)
                _Milestone(label: '${m ~/ 1000}k', active: goal == m, onTap: () => onChanged(m)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Semantics(
      button: true,
      selected: active,
      label: '$label steps',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AeroColors.tangerine : (p.isDark ? p.track : AeroColors.surfaceHighest),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AeroText.numeric(
                  13,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? p.accentText : p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Bottom: OEM battery protection sheet ─────────────────────────

const _mint = Color(0xFFA6E6B8);
const _sheetMuted = Color(0xFFE5E1E4);

class _ProtectionSheet extends StatelessWidget {
  const _ProtectionSheet({
    required this.selectedOem,
    required this.onOemSelected,
    required this.autoPause,
    required this.onAutoPauseChanged,
    required this.onComplete,
  });

  final String? selectedOem;
  final ValueChanged<String> onOemSelected;
  final bool autoPause;
  final ValueChanged<bool> onAutoPauseChanged;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final dark = context.aero.isDark;
    return CharcoalCard(
      radius: 36,
      color: dark ? AeroColors.charcoalWarm : AeroColors.charcoal,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: -68, right: -68, child: GlowOrb(color: AeroColors.skyCyan, size: 176, opacity: 0.14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AeroColors.cyanDeep.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 15, color: AeroColors.cyanFixed),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'HARDWARE SYNC & ACCURACY',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AeroText.labelCaps.copyWith(color: AeroColors.cyanFixed, letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D63).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Zero-Kill AI',
                      style: AeroText.caption.copyWith(color: AeroColors.cyanFixed, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('1-Tap OEM Battery Protection', style: AeroText.headlineMd.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                'Xiaomi, Samsung & Realme verified. Whitelist background pedometer sensor to prevent '
                'aggressive Android memory killing.',
                style: AeroText.bodyMd.copyWith(color: _sheetMuted.withValues(alpha: 0.8), height: 1.55),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, o) in _oems.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _OemCard(option: o, selected: selectedOem == o.id, onTap: () => onOemSelected(o.id)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _AutoPauseTile(value: autoPause, onChanged: onAutoPauseChanged),
              const SizedBox(height: 20),
              OnboardingPillCta(
                label: 'Complete Setup & Launch',
                icon: Icons.check_rounded,
                emblemSize: 32,
                trailingCircle: false,
                labelWeight: FontWeight.w700,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                onPressed: onComplete,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security_rounded, size: 13, color: _mint),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Local on-device inference • No raw GPS exported',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AeroText.caption.copyWith(color: _sheetMuted.withValues(alpha: 0.6), fontSize: 11),
                    ),
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

class _OemOption {
  const _OemOption(this.id, this.name, this.status, this.icon);
  final String id;
  final String name;
  final String status;
  final IconData icon;
}

const _oems = [
  _OemOption(kOemSamsung, 'Samsung', 'OneUI Ready', Icons.smartphone_rounded),
  _OemOption(kOemXiaomi, 'Xiaomi', 'AutoStart OK', Icons.sensors_rounded),
  _OemOption(kOemRealmePixel, 'Realme/Pixel', 'Unrestricted', Icons.memory_rounded),
];

class _OemCard extends StatelessWidget {
  const _OemCard({required this.option, required this.selected, required this.onTap});
  final _OemOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.name} battery protection, ${option.status}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AeroColors.tangerine.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          borderRadius: br,
          border: Border.all(color: selected ? AeroColors.tangerine.withValues(alpha: 0.55) : Colors.transparent),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AeroColors.tangerine : Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Icon(option.icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      option.name,
                      maxLines: 1,
                      style: AeroText.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                          size: 11,
                          color: _mint,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          option.status,
                          maxLines: 1,
                          style: AeroText.labelCaps.copyWith(color: _mint, fontSize: 9.5, letterSpacing: 0.2),
                        ),
                      ],
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

class _AutoPauseTile extends StatelessWidget {
  const _AutoPauseTile({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AeroColors.tangerine.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car_rounded, size: 20, color: AeroColors.tangerine),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Auto-Pause Vehicle Rides',
                          style: AeroText.bodyMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            height: 1.25,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AeroColors.tangerine.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AI Accel',
                            style: AeroText.caption.copyWith(
                              color: AeroColors.peachFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ignores commute bumps & subway vibration',
                      style: AeroText.caption.copyWith(color: _sheetMuted.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AeroColors.tangerine,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

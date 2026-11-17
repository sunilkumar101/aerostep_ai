import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state/activity_state.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'widgets/route_map.dart';

final NumberFormat _grouped = NumberFormat.decimalPattern('en_US');

/// Planned loop length drawn on the vector map (1 km / 2 km pins at thirds).
const double _routeKm = 3.0;

/// Live Walk & Stride Pace Coach — `aerostep_ai_live_walk_pace_coach`.
///
/// Runs a real session: a [Stopwatch] drives Duration every second (paused by
/// Pause), and session steps accumulate from [activityProvider] deltas while
/// the session is running. Distance = session steps × stride length.
class LiveWalkScreen extends ConsumerStatefulWidget {
  const LiveWalkScreen({super.key});

  @override
  ConsumerState<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends ConsumerState<LiveWalkScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  /// Pre-elapsed time (demo mode seeds the Stitch mockup's 34:12).
  Duration _offset = Duration.zero;
  int _sessionSteps = 0;
  bool _paused = false;
  bool _locked = false;
  bool _outdoor = false;
  bool _voice = true;
  double _demoCarry = 0;

  /// Briefly highlights the lock caption when a locked control is touched
  /// (inline instead of a SnackBar, which would cover the control sheet).
  bool _hint = false;
  Timer? _hintTimer;

  /// Rolling (elapsedSeconds, sessionSteps) samples for live cadence.
  final List<(int, int)> _samples = [];

  Duration get _elapsed => _offset + _stopwatch.elapsed;
  double get _strideM => ref.read(userProfileProvider).strideLengthM;
  double get _distanceKm => _sessionSteps * _strideM / 1000;

  @override
  void initState() {
    super.initState();
    if (kAeroDemoMode) {
      _offset = const Duration(minutes: 34, seconds: 12);
      _sessionSteps = 4097; // 2.95 km at 0.72 m stride
    }
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.listenManual<int>(activityProvider.select((a) => a.steps), (prev, next) {
      if (_paused || prev == null) return;
      final delta = next - prev;
      // Negative delta = midnight ledger rollover; ignore rather than subtract.
      if (delta > 0 && mounted) setState(() => _sessionSteps += delta);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hintTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _paused) return;
    setState(() {
      if (kAeroDemoMode) {
        // Demo builds have no live sensor feed: simulate a 118 SPM stride.
        _demoCarry += 118 / 60;
        final whole = _demoCarry.floor();
        _demoCarry -= whole;
        _sessionSteps += whole;
      }
      final sec = _elapsed.inSeconds;
      _samples.add((sec, _sessionSteps));
      _samples.removeWhere((s) => sec - s.$1 > 30);
    });
  }

  int _cadence(ActivitySnapshot a) {
    if (_paused) return 0;
    if (_samples.length >= 2) {
      final span = _samples.last.$1 - _samples.first.$1;
      if (span >= 10) return ((_samples.last.$2 - _samples.first.$2) * 60 / span).round();
    }
    return kAeroDemoMode ? 118 : a.cadenceSpm;
  }

  String _paceLabel() {
    if (kAeroDemoMode) return '5:14';
    final km = _distanceKm;
    if (km < 0.02) return '--:--';
    final secPerKm = (_elapsed.inSeconds / km).round();
    if (secPerKm >= 60 * 60) return '--:--';
    return '${secPerKm ~/ 60}:${(secPerKm % 60).toString().padLeft(2, '0')}';
  }

  int get _kcal => (_sessionSteps * 0.04 * ref.read(userProfileProvider).weightKg / 70).round();

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // --- Controls -------------------------------------------------------------

  void _lockedHint() {
    HapticFeedback.selectionClick();
    _hintTimer?.cancel();
    setState(() => _hint = true);
    _hintTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  void _toggleLock() {
    if (_locked) return _lockedHint();
    HapticFeedback.mediumImpact();
    setState(() => _locked = true);
  }

  void _unlock() {
    if (!_locked) return;
    HapticFeedback.heavyImpact();
    setState(() => _locked = false);
  }

  void _togglePause() {
    if (_locked) return _lockedHint();
    HapticFeedback.lightImpact();
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
      _samples.clear();
    });
  }

  void _setOutdoor(bool v) {
    if (_locked) return _lockedHint();
    if (v == _outdoor) return;
    HapticFeedback.selectionClick();
    setState(() => _outdoor = v);
  }

  Future<void> _finish() async {
    if (_locked) return _lockedHint();
    final wasPaused = _paused;
    setState(() {
      _paused = true;
      _stopwatch.stop();
    });
    final done = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SummarySheet(
        duration: _fmtDuration(_elapsed),
        distanceKm: _distanceKm,
        steps: _sessionSteps,
        kcal: _kcal,
        pace: _paceLabel(),
      ),
    );
    if (!mounted) return;
    if (done ?? false) {
      _ticker?.cancel();
      context.pop();
    } else if (!wasPaused) {
      setState(() {
        _paused = false;
        _stopwatch.start();
        _samples.clear();
      });
    }
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(activityProvider);
    final profile = ref.watch(userProfileProvider);
    final cadence = _cadence(a);
    final p = context.aero;

    return PopScope(
      canPop: !_locked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _lockedHint();
      },
      child: Scaffold(
        backgroundColor: p.canvas.first,
        body: AeroCanvas(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  paused: _paused,
                  voice: _voice,
                  onBack: _locked ? _lockedHint : () => context.pop(),
                  onVoice: () => _locked ? _lockedHint() : setState(() => _voice = !_voice),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      _ModeSwitcher(outdoor: _outdoor, onChanged: _setOutdoor),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 240,
                        child: RouteMapCard(
                          progress: (_distanceKm / _routeKm).clamp(0.0, 1.0),
                          pace: _paceLabel(),
                          tag: _outdoor ? 'GPS ASSIST • LIVE' : 'GYRO SYNCED • 120Hz',
                          live: !_paused,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CadenceHud(
                        cadence: cadence,
                        paused: _paused,
                        voice: _voice,
                        tick: _elapsed.inSeconds,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              label: 'Duration',
                              value: _fmtDuration(_elapsed),
                              caption: _paused ? 'Paused' : 'Active Walking',
                              icon: Icons.timer_outlined,
                              capsule: p.isDark
                                  ? AeroColors.skyCyan.withValues(alpha: 0.18)
                                  : AeroColors.cyanFixed,
                              iconColor: p.cyan,
                              dot: p.cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStatCard(
                              label: 'Distance',
                              value: _distanceKm.toStringAsFixed(2),
                              unit: 'km',
                              caption: '${_grouped.format(_sessionSteps)} steps',
                              icon: Icons.pin_drop_outlined,
                              capsule: AeroColors.charcoal,
                              iconColor: Colors.white,
                              dot: AeroColors.tangerine,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticsStrip(kcal: _kcal, strideCm: (profile.strideLengthM * 100).round()),
                    ],
                  ),
                ),
                _ControlSheet(
                  paused: _paused,
                  locked: _locked,
                  hint: _hint,
                  outdoor: _outdoor,
                  autoPause: profile.autoPauseVehicles,
                  vehicle: a.isVehicleDetected,
                  onLock: _toggleLock,
                  onUnlock: _unlock,
                  onPause: _togglePause,
                  onFinish: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header & mode switcher
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.paused, required this.voice, required this.onBack, required this.onVoice});
  final bool paused;
  final bool voice;
  final VoidCallback onBack;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          AeroCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 44,
            foreground: p.text,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (paused)
                        const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.pause_circle_filled_rounded, size: 14, color: AeroColors.tangerine),
                        )
                      else
                        const PulsingDot(color: AeroColors.tangerine, size: 8),
                      const SizedBox(width: 2),
                      Text('Live Walk & Stride', style: AeroText.headlineMd.copyWith(color: p.text)),
                    ],
                  ),
                ),
                Text(
                  paused ? 'Session Paused' : 'Kinetic Pacing Session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AeroCircleButton(
            icon: voice ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 44,
            foreground: voice ? AeroColors.tangerine : p.textMuted,
            tooltip: voice ? 'Mute voice coach' : 'Unmute voice coach',
            onPressed: onVoice,
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.outdoor, required this.onChanged});
  final bool outdoor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    Widget pill(bool isOutdoor, IconData icon, String label) {
      final active = outdoor == isOutdoor;
      final fg = active ? Colors.white : p.textMuted;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(isOutdoor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: active ? AeroColors.tangerine : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
              boxShadow: active
                  ? const [BoxShadow(color: Color(0x4DFF7A2F), blurRadius: 12, offset: Offset(0, 4))]
                  : null,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(label, style: AeroText.labelCaps.copyWith(color: fg, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.isDark ? p.chip : AeroColors.surfaceContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          pill(false, Icons.bolt_rounded, 'Indoor Sensor (0% GPS)'),
          const SizedBox(width: 4),
          pill(true, Icons.map_outlined, 'Outdoor Route'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tangerine cadence HUD
// ---------------------------------------------------------------------------

class _CadenceHud extends StatelessWidget {
  const _CadenceHud({required this.cadence, required this.paused, required this.voice, required this.tick});
  final int cadence;
  final bool paused;
  final bool voice;
  final int tick;

  (String, String) get _zone {
    if (paused) return ('PAUSED', 'Session paused — hydrate, breathe, and resume when ready.');
    if (cadence < 90) return ('WARM-UP ZONE', 'Ease in — relax your shoulders and find a steady rhythm.');
    if (cadence < 130) return ('FAT-BURN ZONE', 'Pace steady — lean 2° forward into your stride to protect calves.');
    return ('CARDIO ZONE', 'Strong tempo — keep strides short and quick, land under your hips.');
  }

  @override
  Widget build(BuildContext context) {
    final (zone, quote) = _zone;
    final white20 = Colors.white.withValues(alpha: 0.2);
    const eq = [0.5, 0.75, 1.0, 0.875, 0.625];
    return TangerineCard(
      radius: 26,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -40,
            child: Icon(Icons.flare_rounded, size: 170, color: Colors.white.withValues(alpha: 0.13)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: white20, borderRadius: BorderRadius.circular(99)),
                        child: Text(
                          'REAL-TIME CADENCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(voice ? Icons.graphic_eq_rounded : Icons.volume_off_rounded, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                voice ? 'Voice Coach Active' : 'Voice Coach Muted',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroText.caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                            Text(
                              cadence > 0 ? '$cadence' : '--',
                              style: AeroText.displayHeroMobile.copyWith(color: Colors.white, fontSize: 56, height: 1),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SPM',
                              style: AeroText.titleMd.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AeroBadge(zone, background: AeroColors.cyanFixed, foreground: AeroColors.onCyanFixed),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < eq.length; i++) ...[
                                if (i > 0) const SizedBox(width: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 450),
                                  width: 4,
                                  height: 16 * (paused ? 0.25 : eq[(i + tick) % eq.length]),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.45 + 0.11 * i),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: white20, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.smart_toy_outlined, size: 17, color: AeroColors.tangerine),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '“$quote”',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AeroText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Duration / Distance bento cards & diagnostics strip
// ---------------------------------------------------------------------------

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.capsule,
    required this.iconColor,
    required this.dot,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final String caption;
  final IconData icon;
  final Color capsule;
  final Color iconColor;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return BentoCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      color: p.isDark ? p.card : Colors.white.withValues(alpha: 0.92),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 62,
            decoration: BoxDecoration(
              color: capsule,
              borderRadius: BorderRadius.circular(99),
              border: p.isDark && capsule == AeroColors.charcoal
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: iconColor),
                const SizedBox(height: 5),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.labelCaps.copyWith(color: p.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(value, style: AeroText.numeric(22, color: p.text)),
                      if (unit != null) ...[
                        const SizedBox(width: 2),
                        Text(unit!, style: AeroText.caption.copyWith(color: p.textMuted)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsStrip extends StatelessWidget {
  const _DiagnosticsStrip({required this.kcal, required this.strideCm});
  final int kcal;
  final int strideCm;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    Widget divider() => Container(
          width: 1,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: p.textMuted.withValues(alpha: 0.2),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: p.isDark ? p.chip : AeroColors.surfaceLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _DiagItem(icon: Icons.local_fire_department_outlined, label: 'Metabolic Burn', value: '$kcal kcal')),
          divider(),
          Expanded(child: _DiagItem(icon: Icons.straighten_rounded, label: 'Stride Length', value: '$strideCm cm')),
          divider(),
          Expanded(
            child: _DiagItem(
              icon: Icons.sensors_rounded,
              label: 'Balance',
              value: '49.8% L',
              valueColor: p.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagItem extends StatelessWidget {
  const _DiagItem({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: p.isDark ? p.track : AeroColors.surfaceHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: p.textMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AeroText.caption.copyWith(color: p.textMuted, fontSize: 10.5),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: AeroText.numeric(15, color: valueColor ?? p.text)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// #141416 bottom control sheet
// ---------------------------------------------------------------------------

class _ControlSheet extends StatelessWidget {
  const _ControlSheet({
    required this.paused,
    required this.locked,
    required this.hint,
    required this.outdoor,
    required this.autoPause,
    required this.vehicle,
    required this.onLock,
    required this.onUnlock,
    required this.onPause,
    required this.onFinish,
  });

  final bool paused;
  final bool locked;
  final bool hint;
  final bool outdoor;
  final bool autoPause;
  final bool vehicle;
  final VoidCallback onLock;
  final VoidCallback onUnlock;
  final VoidCallback onPause;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final filterLabel = !autoPause
        ? 'Auto-Pause Drive Filter: Off'
        : vehicle
            ? 'Vehicle detected • steps paused'
            : 'Auto-Pause Drive Filter: Active';
    return Container(
      margin: EdgeInsets.fromLTRB(8, 0, 8, 8 + bottom),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AeroColors.charcoal,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car_outlined, size: 16, color: autoPause ? AeroColors.cyanFixed : Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.labelCaps.copyWith(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
                const PulsingDot(color: AeroColors.skyCyan, size: 7),
                Text('ONLINE', style: AeroText.labelCaps.copyWith(color: AeroColors.cyanFixed, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Tooltip(
                message: locked ? 'Long-press to unlock' : 'Lock controls',
                child: Material(
                  color: locked ? AeroColors.tangerine : Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onLock,
                    onLongPress: onUnlock,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: locked ? 0.4 : 1,
                  child: AeroPillButton(
                    label: paused ? 'Resume' : 'Pause',
                    icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    tone: AeroButtonTone.cyan,
                    height: 56,
                    expand: true,
                    onPressed: onPause,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: locked ? 0.4 : 1,
                  child: AeroPillButton(
                    label: 'Finish',
                    trailingIcon: Icons.check_circle_outline_rounded,
                    height: 56,
                    expand: true,
                    onPressed: onFinish,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                locked ? Icons.touch_app_outlined : Icons.shield_outlined,
                size: 13,
                color: hint ? AeroColors.peachFixed : Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  locked
                      ? 'Controls locked • long-press the lock to unlock'
                      : outdoor
                          ? 'GPS active only during this session • Local telemetry'
                          : 'Zero GPS background drain active • Local on-device telemetry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(
                    color: hint ? AeroColors.peachFixed : Colors.white.withValues(alpha: 0.6),
                    fontWeight: hint ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Finish summary sheet
// ---------------------------------------------------------------------------

class _SummarySheet extends StatelessWidget {
  const _SummarySheet({
    required this.duration,
    required this.distanceKm,
    required this.steps,
    required this.kcal,
    required this.pace,
  });

  final String duration;
  final double distanceKm;
  final int steps;
  final int kcal;
  final String pace;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget stat(String label, String value, String unit, Color accent) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AeroText.labelCaps.copyWith(color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: AeroText.numeric(26, color: accent)),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(unit, style: AeroText.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AeroColors.charcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(gradient: AeroColors.tangerineGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Walk Complete', style: AeroText.headlineMd.copyWith(color: Colors.white)),
                      Text(
                        "Every step is already in today's on-device ledger",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroText.caption.copyWith(color: AeroColors.peachFixed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: stat('DURATION', duration, '', Colors.white)),
                const SizedBox(width: 10),
                Expanded(child: stat('DISTANCE', distanceKm.toStringAsFixed(2), 'km', AeroColors.skyCyan)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: stat('STEPS', _grouped.format(steps), '', AeroColors.tangerine)),
                const SizedBox(width: 10),
                Expanded(child: stat('BURN', '$kcal', 'kcal', AeroColors.peachFixed)),
              ],
            ),
            const SizedBox(height: 10),
            stat('AVG PACE', pace, '/km', Colors.white),
            const SizedBox(height: 18),
            AeroPillButton(
              label: 'Done',
              trailingIcon: Icons.check_rounded,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Walking',
                style: AeroText.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

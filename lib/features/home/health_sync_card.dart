import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

import '../../core/pedometer/pedometer_controller.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';

enum _HealthState { checking, notInstalled, disconnected, connected, unavailable }

/// "Sync watch steps" card: connects Google Health Connect (Android) or Apple
/// Health (iOS) so smartwatch + phone steps merge without double-counting.
class HealthSyncCard extends ConsumerStatefulWidget {
  const HealthSyncCard({super.key});

  @override
  ConsumerState<HealthSyncCard> createState() => _HealthSyncCardState();
}

class _HealthSyncCardState extends ConsumerState<HealthSyncCard> with WidgetsBindingObserver {
  _HealthState _state = _HealthState.checking;
  bool _busy = false;
  final _health = Health();

  String get _store => Platform.isIOS ? 'Apple Health' : 'Health Connect';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Returning from the Play Store / Health Connect permission screen.
    if (s == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (kAeroDemoMode) {
      setState(() => _state = _HealthState.connected);
      return;
    }
    _HealthState next;
    try {
      await _health.configure();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          next = status == HealthConnectSdkStatus.sdkUnavailable ? _HealthState.unavailable : _HealthState.notInstalled;
          if (mounted) setState(() => _state = next);
          return;
        }
      }
      final ok = await _health.hasPermissions(const [HealthDataType.STEPS], permissions: const [HealthDataAccess.READ]);
      next = ok == true ? _HealthState.connected : _HealthState.disconnected;
    } catch (_) {
      next = _HealthState.unavailable;
    }
    if (mounted) setState(() => _state = next);
  }

  Future<void> _act() async {
    setState(() => _busy = true);
    try {
      switch (_state) {
        case _HealthState.notInstalled:
          await _health.installHealthConnect();
        case _HealthState.disconnected:
          final ok = await ref.read(pedometerControllerProvider).requestHealthAccess();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? '$_store connected • watch + phone steps merged' : '$_store access not granted'),
            ));
          }
          await _refresh();
        default:
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final (String subtitle, String? cta) = switch (_state) {
      _HealthState.checking => ('Checking $_store…', null),
      _HealthState.notInstalled => ('Install Health Connect to merge smartwatch steps.', 'Install'),
      _HealthState.disconnected => ('Merge watch + phone steps with zero double-counting.', 'Connect'),
      _HealthState.connected => ('Connected • synced every 15 min in UTC buckets.', null),
      _HealthState.unavailable => ('$_store isn\'t available on this device.', null),
    };
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AeroIconTile(
            icon: _state == _HealthState.connected ? Icons.verified_rounded : Icons.watch_rounded,
            background: p.isDark ? const Color(0xFF14313C) : AeroColors.cyanFixed,
            foreground: p.cyan,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync watch steps', style: AeroText.titleMd.copyWith(color: p.text, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AeroText.caption.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          if (cta != null) ...[
            const SizedBox(width: 8),
            AeroPillButton(label: cta, height: 40, tone: AeroButtonTone.cyan, onPressed: _busy ? null : _act),
          ] else if (_state == _HealthState.connected)
            Icon(Icons.check_circle_rounded, color: p.cyan),
        ],
      ),
    );
  }
}

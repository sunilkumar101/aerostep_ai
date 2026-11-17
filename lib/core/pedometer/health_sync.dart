import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../data/aero_database.dart';
import 'health_dedup.dart';

/// Pulls step samples from Google Health Connect (Android) / Apple HealthKit
/// (iOS), folds them into 15-minute UTC buckets and stores them next to the
/// phone-sensor counts. The ledger then takes max(phone, health) per bucket.
class HealthSync {
  HealthSync(this.db, {Health? health}) : _health = health ?? Health();

  final AeroDatabase db;
  final Health _health;
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];

  Future<bool> isAvailable() async {
    try {
      await _ensureConfigured();
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      debugPrint('HealthSync.isAvailable: $e');
      return false;
    }
  }

  /// Ask for read access to steps. Safe to call repeatedly.
  Future<bool> requestPermission() async {
    try {
      await _ensureConfigured();
      if (!await _health.isHealthConnectAvailable()) return false;
      return await _health.requestAuthorization(_types, permissions: const [HealthDataAccess.READ]);
    } catch (e) {
      debugPrint('HealthSync.requestPermission: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      await _ensureConfigured();
      return await _health.hasPermissions(_types, permissions: const [HealthDataAccess.READ]) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Re-sync the last [lookback] of health steps. Idempotent.
  Future<int> sync({Duration lookback = const Duration(days: 2)}) async {
    try {
      if (!await hasPermission()) return 0;
      final end = DateTime.now();
      final start = bucketStart(end.subtract(lookback));
      final points = await _health.getHealthDataFromTypes(types: _types, startTime: start, endTime: end);
      final samples = <StepSample>[
        for (final p in _health.removeDuplicates(points))
          if (p.value is NumericHealthValue)
            StepSample(p.dateFrom, p.dateTo, (p.value as NumericHealthValue).numericValue.round()),
      ];
      final buckets = bucketize(samples);
      await db.upsertHealthBuckets(buckets);
      return buckets.length;
    } catch (e) {
      debugPrint('HealthSync.sync: $e');
      return 0;
    }
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }
}

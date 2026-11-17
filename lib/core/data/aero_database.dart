import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../pedometer/health_dedup.dart';
import '../pedometer/streak.dart';

part 'aero_database.g.dart';

/// 15-minute UTC step buckets. Phone (hardware sensor, after the anti-shake
/// gate) and health-store counts are kept separately and merged with max().
class StepBuckets extends Table {
  IntColumn get bucketStartUtc => integer()();
  IntColumn get phoneSteps => integer().withDefault(const Constant(0))();
  IntColumn get healthSteps => integer().withDefault(const Constant(0))();

  /// Device UTC offset (minutes) when the bucket was first written.
  IntColumn get offsetMinutes => integer()();

  @override
  Set<Column> get primaryKey => {bucketStartUtc};
}

class HydrationLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get atUtc => integer()();
  IntColumn get offsetMinutes => integer()();
  IntColumn get ml => integer()();
}

/// Local days covered by an auto-deployed Streak Shield.
class ShieldedDays extends Table {
  TextColumn get day => text()();

  @override
  Set<Column> get primaryKey => {day};
}

@DriftDatabase(tables: [StepBuckets, HydrationLogs, ShieldedDays])
class AeroDatabase extends _$AeroDatabase {
  AeroDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'aerostep',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ));

  @override
  int get schemaVersion => 1;

  static int _offsetNow() => DateTime.now().timeZoneOffset.inMinutes;

  /// Add gate-approved phone steps at instant [at].
  Future<void> addPhoneSteps(DateTime at, int steps) async {
    if (steps <= 0) return;
    final b = bucketStartMs(at);
    await customStatement(
      'INSERT INTO step_buckets (bucket_start_utc, phone_steps, health_steps, offset_minutes) '
      'VALUES (?, ?, 0, ?) '
      'ON CONFLICT(bucket_start_utc) DO UPDATE SET phone_steps = phone_steps + excluded.phone_steps',
      [b, steps, _offsetNow()],
    );
  }

  /// Replace health-store counts for the given buckets (idempotent re-sync).
  Future<void> upsertHealthBuckets(Map<int, int> buckets) async {
    await batch((b) {
      for (final e in buckets.entries) {
        b.customStatement(
          'INSERT INTO step_buckets (bucket_start_utc, phone_steps, health_steps, offset_minutes) '
          'VALUES (?, 0, ?, ?) '
          'ON CONFLICT(bucket_start_utc) DO UPDATE SET health_steps = excluded.health_steps',
          [e.key, e.value, _offsetNow()],
        );
      }
    });
  }

  /// Deduplicated ledger entries since [fromUtc].
  Future<List<LedgerEntry>> entriesSince(DateTime fromUtc) async {
    final rows = await (select(stepBuckets)
          ..where((t) => t.bucketStartUtc.isBiggerOrEqualValue(fromUtc.toUtc().millisecondsSinceEpoch)))
        .get();
    return [
      for (final r in rows)
        LedgerEntry(
          utc: DateTime.fromMillisecondsSinceEpoch(r.bucketStartUtc, isUtc: true),
          offsetMinutes: r.offsetMinutes,
          steps: r.phoneSteps > r.healthSteps ? r.phoneSteps : r.healthSteps,
        ),
    ];
  }

  Future<void> logHydration(int ml) => into(hydrationLogs).insert(HydrationLogsCompanion.insert(
        atUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
        offsetMinutes: _offsetNow(),
        ml: ml,
      ));

  Future<Set<String>> loadShieldedDays() async => (await select(shieldedDays).get()).map((r) => r.day).toSet();

  Future<void> markShielded(Iterable<String> days) async {
    await batch((b) {
      for (final d in days) {
        b.insert(shieldedDays, ShieldedDaysCompanion.insert(day: d), mode: InsertMode.insertOrIgnore);
      }
    });
  }
}

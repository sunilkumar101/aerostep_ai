// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aero_database.dart';

// ignore_for_file: type=lint
class $StepBucketsTable extends StepBuckets
    with TableInfo<$StepBucketsTable, StepBucket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepBucketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bucketStartUtcMeta = const VerificationMeta(
    'bucketStartUtc',
  );
  @override
  late final GeneratedColumn<int> bucketStartUtc = GeneratedColumn<int>(
    'bucket_start_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneStepsMeta = const VerificationMeta(
    'phoneSteps',
  );
  @override
  late final GeneratedColumn<int> phoneSteps = GeneratedColumn<int>(
    'phone_steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _healthStepsMeta = const VerificationMeta(
    'healthSteps',
  );
  @override
  late final GeneratedColumn<int> healthSteps = GeneratedColumn<int>(
    'health_steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bucketStartUtc,
    phoneSteps,
    healthSteps,
    offsetMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_buckets';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepBucket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bucket_start_utc')) {
      context.handle(
        _bucketStartUtcMeta,
        bucketStartUtc.isAcceptableOrUnknown(
          data['bucket_start_utc']!,
          _bucketStartUtcMeta,
        ),
      );
    }
    if (data.containsKey('phone_steps')) {
      context.handle(
        _phoneStepsMeta,
        phoneSteps.isAcceptableOrUnknown(data['phone_steps']!, _phoneStepsMeta),
      );
    }
    if (data.containsKey('health_steps')) {
      context.handle(
        _healthStepsMeta,
        healthSteps.isAcceptableOrUnknown(
          data['health_steps']!,
          _healthStepsMeta,
        ),
      );
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bucketStartUtc};
  @override
  StepBucket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepBucket(
      bucketStartUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bucket_start_utc'],
      )!,
      phoneSteps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phone_steps'],
      )!,
      healthSteps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_steps'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
    );
  }

  @override
  $StepBucketsTable createAlias(String alias) {
    return $StepBucketsTable(attachedDatabase, alias);
  }
}

class StepBucket extends DataClass implements Insertable<StepBucket> {
  final int bucketStartUtc;
  final int phoneSteps;
  final int healthSteps;

  /// Device UTC offset (minutes) when the bucket was first written.
  final int offsetMinutes;
  const StepBucket({
    required this.bucketStartUtc,
    required this.phoneSteps,
    required this.healthSteps,
    required this.offsetMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bucket_start_utc'] = Variable<int>(bucketStartUtc);
    map['phone_steps'] = Variable<int>(phoneSteps);
    map['health_steps'] = Variable<int>(healthSteps);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    return map;
  }

  StepBucketsCompanion toCompanion(bool nullToAbsent) {
    return StepBucketsCompanion(
      bucketStartUtc: Value(bucketStartUtc),
      phoneSteps: Value(phoneSteps),
      healthSteps: Value(healthSteps),
      offsetMinutes: Value(offsetMinutes),
    );
  }

  factory StepBucket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepBucket(
      bucketStartUtc: serializer.fromJson<int>(json['bucketStartUtc']),
      phoneSteps: serializer.fromJson<int>(json['phoneSteps']),
      healthSteps: serializer.fromJson<int>(json['healthSteps']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bucketStartUtc': serializer.toJson<int>(bucketStartUtc),
      'phoneSteps': serializer.toJson<int>(phoneSteps),
      'healthSteps': serializer.toJson<int>(healthSteps),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
    };
  }

  StepBucket copyWith({
    int? bucketStartUtc,
    int? phoneSteps,
    int? healthSteps,
    int? offsetMinutes,
  }) => StepBucket(
    bucketStartUtc: bucketStartUtc ?? this.bucketStartUtc,
    phoneSteps: phoneSteps ?? this.phoneSteps,
    healthSteps: healthSteps ?? this.healthSteps,
    offsetMinutes: offsetMinutes ?? this.offsetMinutes,
  );
  StepBucket copyWithCompanion(StepBucketsCompanion data) {
    return StepBucket(
      bucketStartUtc: data.bucketStartUtc.present
          ? data.bucketStartUtc.value
          : this.bucketStartUtc,
      phoneSteps: data.phoneSteps.present
          ? data.phoneSteps.value
          : this.phoneSteps,
      healthSteps: data.healthSteps.present
          ? data.healthSteps.value
          : this.healthSteps,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepBucket(')
          ..write('bucketStartUtc: $bucketStartUtc, ')
          ..write('phoneSteps: $phoneSteps, ')
          ..write('healthSteps: $healthSteps, ')
          ..write('offsetMinutes: $offsetMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bucketStartUtc, phoneSteps, healthSteps, offsetMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepBucket &&
          other.bucketStartUtc == this.bucketStartUtc &&
          other.phoneSteps == this.phoneSteps &&
          other.healthSteps == this.healthSteps &&
          other.offsetMinutes == this.offsetMinutes);
}

class StepBucketsCompanion extends UpdateCompanion<StepBucket> {
  final Value<int> bucketStartUtc;
  final Value<int> phoneSteps;
  final Value<int> healthSteps;
  final Value<int> offsetMinutes;
  const StepBucketsCompanion({
    this.bucketStartUtc = const Value.absent(),
    this.phoneSteps = const Value.absent(),
    this.healthSteps = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
  });
  StepBucketsCompanion.insert({
    this.bucketStartUtc = const Value.absent(),
    this.phoneSteps = const Value.absent(),
    this.healthSteps = const Value.absent(),
    required int offsetMinutes,
  }) : offsetMinutes = Value(offsetMinutes);
  static Insertable<StepBucket> custom({
    Expression<int>? bucketStartUtc,
    Expression<int>? phoneSteps,
    Expression<int>? healthSteps,
    Expression<int>? offsetMinutes,
  }) {
    return RawValuesInsertable({
      if (bucketStartUtc != null) 'bucket_start_utc': bucketStartUtc,
      if (phoneSteps != null) 'phone_steps': phoneSteps,
      if (healthSteps != null) 'health_steps': healthSteps,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
    });
  }

  StepBucketsCompanion copyWith({
    Value<int>? bucketStartUtc,
    Value<int>? phoneSteps,
    Value<int>? healthSteps,
    Value<int>? offsetMinutes,
  }) {
    return StepBucketsCompanion(
      bucketStartUtc: bucketStartUtc ?? this.bucketStartUtc,
      phoneSteps: phoneSteps ?? this.phoneSteps,
      healthSteps: healthSteps ?? this.healthSteps,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bucketStartUtc.present) {
      map['bucket_start_utc'] = Variable<int>(bucketStartUtc.value);
    }
    if (phoneSteps.present) {
      map['phone_steps'] = Variable<int>(phoneSteps.value);
    }
    if (healthSteps.present) {
      map['health_steps'] = Variable<int>(healthSteps.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepBucketsCompanion(')
          ..write('bucketStartUtc: $bucketStartUtc, ')
          ..write('phoneSteps: $phoneSteps, ')
          ..write('healthSteps: $healthSteps, ')
          ..write('offsetMinutes: $offsetMinutes')
          ..write(')'))
        .toString();
  }
}

class $HydrationLogsTable extends HydrationLogs
    with TableInfo<$HydrationLogsTable, HydrationLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HydrationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atUtcMeta = const VerificationMeta('atUtc');
  @override
  late final GeneratedColumn<int> atUtc = GeneratedColumn<int>(
    'at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<int> ml = GeneratedColumn<int>(
    'ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, atUtc, offsetMinutes, ml];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hydration_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HydrationLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at_utc')) {
      context.handle(
        _atUtcMeta,
        atUtc.isAcceptableOrUnknown(data['at_utc']!, _atUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_atUtcMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HydrationLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HydrationLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      atUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_utc'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      )!,
      ml: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ml'],
      )!,
    );
  }

  @override
  $HydrationLogsTable createAlias(String alias) {
    return $HydrationLogsTable(attachedDatabase, alias);
  }
}

class HydrationLog extends DataClass implements Insertable<HydrationLog> {
  final int id;
  final int atUtc;
  final int offsetMinutes;
  final int ml;
  const HydrationLog({
    required this.id,
    required this.atUtc,
    required this.offsetMinutes,
    required this.ml,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at_utc'] = Variable<int>(atUtc);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    map['ml'] = Variable<int>(ml);
    return map;
  }

  HydrationLogsCompanion toCompanion(bool nullToAbsent) {
    return HydrationLogsCompanion(
      id: Value(id),
      atUtc: Value(atUtc),
      offsetMinutes: Value(offsetMinutes),
      ml: Value(ml),
    );
  }

  factory HydrationLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HydrationLog(
      id: serializer.fromJson<int>(json['id']),
      atUtc: serializer.fromJson<int>(json['atUtc']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      ml: serializer.fromJson<int>(json['ml']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'atUtc': serializer.toJson<int>(atUtc),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'ml': serializer.toJson<int>(ml),
    };
  }

  HydrationLog copyWith({int? id, int? atUtc, int? offsetMinutes, int? ml}) =>
      HydrationLog(
        id: id ?? this.id,
        atUtc: atUtc ?? this.atUtc,
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
        ml: ml ?? this.ml,
      );
  HydrationLog copyWithCompanion(HydrationLogsCompanion data) {
    return HydrationLog(
      id: data.id.present ? data.id.value : this.id,
      atUtc: data.atUtc.present ? data.atUtc.value : this.atUtc,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      ml: data.ml.present ? data.ml.value : this.ml,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HydrationLog(')
          ..write('id: $id, ')
          ..write('atUtc: $atUtc, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, atUtc, offsetMinutes, ml);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HydrationLog &&
          other.id == this.id &&
          other.atUtc == this.atUtc &&
          other.offsetMinutes == this.offsetMinutes &&
          other.ml == this.ml);
}

class HydrationLogsCompanion extends UpdateCompanion<HydrationLog> {
  final Value<int> id;
  final Value<int> atUtc;
  final Value<int> offsetMinutes;
  final Value<int> ml;
  const HydrationLogsCompanion({
    this.id = const Value.absent(),
    this.atUtc = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.ml = const Value.absent(),
  });
  HydrationLogsCompanion.insert({
    this.id = const Value.absent(),
    required int atUtc,
    required int offsetMinutes,
    required int ml,
  }) : atUtc = Value(atUtc),
       offsetMinutes = Value(offsetMinutes),
       ml = Value(ml);
  static Insertable<HydrationLog> custom({
    Expression<int>? id,
    Expression<int>? atUtc,
    Expression<int>? offsetMinutes,
    Expression<int>? ml,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atUtc != null) 'at_utc': atUtc,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (ml != null) 'ml': ml,
    });
  }

  HydrationLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? atUtc,
    Value<int>? offsetMinutes,
    Value<int>? ml,
  }) {
    return HydrationLogsCompanion(
      id: id ?? this.id,
      atUtc: atUtc ?? this.atUtc,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      ml: ml ?? this.ml,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (atUtc.present) {
      map['at_utc'] = Variable<int>(atUtc.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (ml.present) {
      map['ml'] = Variable<int>(ml.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HydrationLogsCompanion(')
          ..write('id: $id, ')
          ..write('atUtc: $atUtc, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }
}

class $ShieldedDaysTable extends ShieldedDays
    with TableInfo<$ShieldedDaysTable, ShieldedDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShieldedDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shielded_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShieldedDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  ShieldedDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShieldedDay(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
    );
  }

  @override
  $ShieldedDaysTable createAlias(String alias) {
    return $ShieldedDaysTable(attachedDatabase, alias);
  }
}

class ShieldedDay extends DataClass implements Insertable<ShieldedDay> {
  final String day;
  const ShieldedDay({required this.day});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    return map;
  }

  ShieldedDaysCompanion toCompanion(bool nullToAbsent) {
    return ShieldedDaysCompanion(day: Value(day));
  }

  factory ShieldedDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShieldedDay(day: serializer.fromJson<String>(json['day']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'day': serializer.toJson<String>(day)};
  }

  ShieldedDay copyWith({String? day}) => ShieldedDay(day: day ?? this.day);
  ShieldedDay copyWithCompanion(ShieldedDaysCompanion data) {
    return ShieldedDay(day: data.day.present ? data.day.value : this.day);
  }

  @override
  String toString() {
    return (StringBuffer('ShieldedDay(')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => day.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ShieldedDay && other.day == this.day);
}

class ShieldedDaysCompanion extends UpdateCompanion<ShieldedDay> {
  final Value<String> day;
  final Value<int> rowid;
  const ShieldedDaysCompanion({
    this.day = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShieldedDaysCompanion.insert({
    required String day,
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<ShieldedDay> custom({
    Expression<String>? day,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShieldedDaysCompanion copyWith({Value<String>? day, Value<int>? rowid}) {
    return ShieldedDaysCompanion(
      day: day ?? this.day,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShieldedDaysCompanion(')
          ..write('day: $day, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AeroDatabase extends GeneratedDatabase {
  _$AeroDatabase(QueryExecutor e) : super(e);
  $AeroDatabaseManager get managers => $AeroDatabaseManager(this);
  late final $StepBucketsTable stepBuckets = $StepBucketsTable(this);
  late final $HydrationLogsTable hydrationLogs = $HydrationLogsTable(this);
  late final $ShieldedDaysTable shieldedDays = $ShieldedDaysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stepBuckets,
    hydrationLogs,
    shieldedDays,
  ];
}

typedef $$StepBucketsTableCreateCompanionBuilder =
    StepBucketsCompanion Function({
      Value<int> bucketStartUtc,
      Value<int> phoneSteps,
      Value<int> healthSteps,
      required int offsetMinutes,
    });
typedef $$StepBucketsTableUpdateCompanionBuilder =
    StepBucketsCompanion Function({
      Value<int> bucketStartUtc,
      Value<int> phoneSteps,
      Value<int> healthSteps,
      Value<int> offsetMinutes,
    });

class $$StepBucketsTableFilterComposer
    extends Composer<_$AeroDatabase, $StepBucketsTable> {
  $$StepBucketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get bucketStartUtc => $composableBuilder(
    column: $table.bucketStartUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phoneSteps => $composableBuilder(
    column: $table.phoneSteps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthSteps => $composableBuilder(
    column: $table.healthSteps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StepBucketsTableOrderingComposer
    extends Composer<_$AeroDatabase, $StepBucketsTable> {
  $$StepBucketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get bucketStartUtc => $composableBuilder(
    column: $table.bucketStartUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phoneSteps => $composableBuilder(
    column: $table.phoneSteps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthSteps => $composableBuilder(
    column: $table.healthSteps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StepBucketsTableAnnotationComposer
    extends Composer<_$AeroDatabase, $StepBucketsTable> {
  $$StepBucketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get bucketStartUtc => $composableBuilder(
    column: $table.bucketStartUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phoneSteps => $composableBuilder(
    column: $table.phoneSteps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get healthSteps => $composableBuilder(
    column: $table.healthSteps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );
}

class $$StepBucketsTableTableManager
    extends
        RootTableManager<
          _$AeroDatabase,
          $StepBucketsTable,
          StepBucket,
          $$StepBucketsTableFilterComposer,
          $$StepBucketsTableOrderingComposer,
          $$StepBucketsTableAnnotationComposer,
          $$StepBucketsTableCreateCompanionBuilder,
          $$StepBucketsTableUpdateCompanionBuilder,
          (
            StepBucket,
            BaseReferences<_$AeroDatabase, $StepBucketsTable, StepBucket>,
          ),
          StepBucket,
          PrefetchHooks Function()
        > {
  $$StepBucketsTableTableManager(_$AeroDatabase db, $StepBucketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepBucketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepBucketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepBucketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bucketStartUtc = const Value.absent(),
                Value<int> phoneSteps = const Value.absent(),
                Value<int> healthSteps = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
              }) => StepBucketsCompanion(
                bucketStartUtc: bucketStartUtc,
                phoneSteps: phoneSteps,
                healthSteps: healthSteps,
                offsetMinutes: offsetMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> bucketStartUtc = const Value.absent(),
                Value<int> phoneSteps = const Value.absent(),
                Value<int> healthSteps = const Value.absent(),
                required int offsetMinutes,
              }) => StepBucketsCompanion.insert(
                bucketStartUtc: bucketStartUtc,
                phoneSteps: phoneSteps,
                healthSteps: healthSteps,
                offsetMinutes: offsetMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StepBucketsTable, StepBucket>(table),
                  BaseReferences<_$AeroDatabase, $StepBucketsTable, StepBucket>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StepBucketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AeroDatabase,
      $StepBucketsTable,
      StepBucket,
      $$StepBucketsTableFilterComposer,
      $$StepBucketsTableOrderingComposer,
      $$StepBucketsTableAnnotationComposer,
      $$StepBucketsTableCreateCompanionBuilder,
      $$StepBucketsTableUpdateCompanionBuilder,
      (
        StepBucket,
        BaseReferences<_$AeroDatabase, $StepBucketsTable, StepBucket>,
      ),
      StepBucket,
      PrefetchHooks Function()
    >;
typedef $$HydrationLogsTableCreateCompanionBuilder =
    HydrationLogsCompanion Function({
      Value<int> id,
      required int atUtc,
      required int offsetMinutes,
      required int ml,
    });
typedef $$HydrationLogsTableUpdateCompanionBuilder =
    HydrationLogsCompanion Function({
      Value<int> id,
      Value<int> atUtc,
      Value<int> offsetMinutes,
      Value<int> ml,
    });

class $$HydrationLogsTableFilterComposer
    extends Composer<_$AeroDatabase, $HydrationLogsTable> {
  $$HydrationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atUtc => $composableBuilder(
    column: $table.atUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HydrationLogsTableOrderingComposer
    extends Composer<_$AeroDatabase, $HydrationLogsTable> {
  $$HydrationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atUtc => $composableBuilder(
    column: $table.atUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HydrationLogsTableAnnotationComposer
    extends Composer<_$AeroDatabase, $HydrationLogsTable> {
  $$HydrationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get atUtc =>
      $composableBuilder(column: $table.atUtc, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);
}

class $$HydrationLogsTableTableManager
    extends
        RootTableManager<
          _$AeroDatabase,
          $HydrationLogsTable,
          HydrationLog,
          $$HydrationLogsTableFilterComposer,
          $$HydrationLogsTableOrderingComposer,
          $$HydrationLogsTableAnnotationComposer,
          $$HydrationLogsTableCreateCompanionBuilder,
          $$HydrationLogsTableUpdateCompanionBuilder,
          (
            HydrationLog,
            BaseReferences<_$AeroDatabase, $HydrationLogsTable, HydrationLog>,
          ),
          HydrationLog,
          PrefetchHooks Function()
        > {
  $$HydrationLogsTableTableManager(_$AeroDatabase db, $HydrationLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HydrationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HydrationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HydrationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> atUtc = const Value.absent(),
                Value<int> offsetMinutes = const Value.absent(),
                Value<int> ml = const Value.absent(),
              }) => HydrationLogsCompanion(
                id: id,
                atUtc: atUtc,
                offsetMinutes: offsetMinutes,
                ml: ml,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int atUtc,
                required int offsetMinutes,
                required int ml,
              }) => HydrationLogsCompanion.insert(
                id: id,
                atUtc: atUtc,
                offsetMinutes: offsetMinutes,
                ml: ml,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HydrationLogsTable, HydrationLog>(table),
                  BaseReferences<
                    _$AeroDatabase,
                    $HydrationLogsTable,
                    HydrationLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HydrationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AeroDatabase,
      $HydrationLogsTable,
      HydrationLog,
      $$HydrationLogsTableFilterComposer,
      $$HydrationLogsTableOrderingComposer,
      $$HydrationLogsTableAnnotationComposer,
      $$HydrationLogsTableCreateCompanionBuilder,
      $$HydrationLogsTableUpdateCompanionBuilder,
      (
        HydrationLog,
        BaseReferences<_$AeroDatabase, $HydrationLogsTable, HydrationLog>,
      ),
      HydrationLog,
      PrefetchHooks Function()
    >;
typedef $$ShieldedDaysTableCreateCompanionBuilder =
    ShieldedDaysCompanion Function({required String day, Value<int> rowid});
typedef $$ShieldedDaysTableUpdateCompanionBuilder =
    ShieldedDaysCompanion Function({Value<String> day, Value<int> rowid});

class $$ShieldedDaysTableFilterComposer
    extends Composer<_$AeroDatabase, $ShieldedDaysTable> {
  $$ShieldedDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShieldedDaysTableOrderingComposer
    extends Composer<_$AeroDatabase, $ShieldedDaysTable> {
  $$ShieldedDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShieldedDaysTableAnnotationComposer
    extends Composer<_$AeroDatabase, $ShieldedDaysTable> {
  $$ShieldedDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);
}

class $$ShieldedDaysTableTableManager
    extends
        RootTableManager<
          _$AeroDatabase,
          $ShieldedDaysTable,
          ShieldedDay,
          $$ShieldedDaysTableFilterComposer,
          $$ShieldedDaysTableOrderingComposer,
          $$ShieldedDaysTableAnnotationComposer,
          $$ShieldedDaysTableCreateCompanionBuilder,
          $$ShieldedDaysTableUpdateCompanionBuilder,
          (
            ShieldedDay,
            BaseReferences<_$AeroDatabase, $ShieldedDaysTable, ShieldedDay>,
          ),
          ShieldedDay,
          PrefetchHooks Function()
        > {
  $$ShieldedDaysTableTableManager(_$AeroDatabase db, $ShieldedDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShieldedDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShieldedDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShieldedDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShieldedDaysCompanion(day: day, rowid: rowid),
          createCompanionCallback:
              ({
                required String day,
                Value<int> rowid = const Value.absent(),
              }) => ShieldedDaysCompanion.insert(day: day, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShieldedDaysTable, ShieldedDay>(table),
                  BaseReferences<
                    _$AeroDatabase,
                    $ShieldedDaysTable,
                    ShieldedDay
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShieldedDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AeroDatabase,
      $ShieldedDaysTable,
      ShieldedDay,
      $$ShieldedDaysTableFilterComposer,
      $$ShieldedDaysTableOrderingComposer,
      $$ShieldedDaysTableAnnotationComposer,
      $$ShieldedDaysTableCreateCompanionBuilder,
      $$ShieldedDaysTableUpdateCompanionBuilder,
      (
        ShieldedDay,
        BaseReferences<_$AeroDatabase, $ShieldedDaysTable, ShieldedDay>,
      ),
      ShieldedDay,
      PrefetchHooks Function()
    >;

class $AeroDatabaseManager {
  final _$AeroDatabase _db;
  $AeroDatabaseManager(this._db);
  $$StepBucketsTableTableManager get stepBuckets =>
      $$StepBucketsTableTableManager(_db, _db.stepBuckets);
  $$HydrationLogsTableTableManager get hydrationLogs =>
      $$HydrationLogsTableTableManager(_db, _db.hydrationLogs);
  $$ShieldedDaysTableTableManager get shieldedDays =>
      $$ShieldedDaysTableTableManager(_db, _db.shieldedDays);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxSpeedMeta = const VerificationMeta(
    'maxSpeed',
  );
  @override
  late final GeneratedColumn<double> maxSpeed = GeneratedColumn<double>(
    'max_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avgSpeedMeta = const VerificationMeta(
    'avgSpeed',
  );
  @override
  late final GeneratedColumn<double> avgSpeed = GeneratedColumn<double>(
    'avg_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _elevationGainMeta = const VerificationMeta(
    'elevationGain',
  );
  @override
  late final GeneratedColumn<double> elevationGain = GeneratedColumn<double>(
    'elevation_gain',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _zeroToHundredSecondsMeta =
      const VerificationMeta('zeroToHundredSeconds');
  @override
  late final GeneratedColumn<double> zeroToHundredSeconds =
      GeneratedColumn<double>(
        'zero_to_hundred_seconds',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keptMeta = const VerificationMeta('kept');
  @override
  late final GeneratedColumn<bool> kept = GeneratedColumn<bool>(
    'kept',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kept" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heatFoldedAtMeta = const VerificationMeta(
    'heatFoldedAt',
  );
  @override
  late final GeneratedColumn<DateTime> heatFoldedAt = GeneratedColumn<DateTime>(
    'heat_folded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudVehicleIdMeta = const VerificationMeta(
    'cloudVehicleId',
  );
  @override
  late final GeneratedColumn<int> cloudVehicleId = GeneratedColumn<int>(
    'cloud_vehicle_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTime,
    endTime,
    maxSpeed,
    avgSpeed,
    distance,
    elevationGain,
    durationSeconds,
    zeroToHundredSeconds,
    kept,
    clientUuid,
    syncedAt,
    heatFoldedAt,
    cloudVehicleId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('max_speed')) {
      context.handle(
        _maxSpeedMeta,
        maxSpeed.isAcceptableOrUnknown(data['max_speed']!, _maxSpeedMeta),
      );
    }
    if (data.containsKey('avg_speed')) {
      context.handle(
        _avgSpeedMeta,
        avgSpeed.isAcceptableOrUnknown(data['avg_speed']!, _avgSpeedMeta),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    if (data.containsKey('elevation_gain')) {
      context.handle(
        _elevationGainMeta,
        elevationGain.isAcceptableOrUnknown(
          data['elevation_gain']!,
          _elevationGainMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('zero_to_hundred_seconds')) {
      context.handle(
        _zeroToHundredSecondsMeta,
        zeroToHundredSeconds.isAcceptableOrUnknown(
          data['zero_to_hundred_seconds']!,
          _zeroToHundredSecondsMeta,
        ),
      );
    }
    if (data.containsKey('kept')) {
      context.handle(
        _keptMeta,
        kept.isAcceptableOrUnknown(data['kept']!, _keptMeta),
      );
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('heat_folded_at')) {
      context.handle(
        _heatFoldedAtMeta,
        heatFoldedAt.isAcceptableOrUnknown(
          data['heat_folded_at']!,
          _heatFoldedAtMeta,
        ),
      );
    }
    if (data.containsKey('cloud_vehicle_id')) {
      context.handle(
        _cloudVehicleIdMeta,
        cloudVehicleId.isAcceptableOrUnknown(
          data['cloud_vehicle_id']!,
          _cloudVehicleIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      maxSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed'],
      )!,
      avgSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_speed'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      )!,
      elevationGain: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      zeroToHundredSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zero_to_hundred_seconds'],
      ),
      kept: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kept'],
      )!,
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      heatFoldedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}heat_folded_at'],
      ),
      cloudVehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_vehicle_id'],
      ),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final double maxSpeed;
  final double avgSpeed;
  final double distance;
  final double elevationGain;
  final int durationSeconds;
  final double? zeroToHundredSeconds;
  final bool kept;
  final String clientUuid;
  final DateTime? syncedAt;
  final DateTime? heatFoldedAt;

  /// Das Fahrzeug in der Cloud, in dem diese Fahrt zurueckgelegt wurde.
  ///
  /// Die Kennung der Cloud, nicht eine eigene: die Garage wird dort
  /// gefuehrt, und beim Hochladen muss genau diese Zahl mitgehen.
  ///
  /// Beim Fahrtende gesetzt, nicht beim Hochladen -- wer zwischendurch das
  /// Standardfahrzeug wechselt, saehe seine alten Fahrten sonst am neuen
  /// Auto haengen.
  final int? cloudVehicleId;
  const Trip({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.distance,
    required this.elevationGain,
    required this.durationSeconds,
    this.zeroToHundredSeconds,
    required this.kept,
    required this.clientUuid,
    this.syncedAt,
    this.heatFoldedAt,
    this.cloudVehicleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['max_speed'] = Variable<double>(maxSpeed);
    map['avg_speed'] = Variable<double>(avgSpeed);
    map['distance'] = Variable<double>(distance);
    map['elevation_gain'] = Variable<double>(elevationGain);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || zeroToHundredSeconds != null) {
      map['zero_to_hundred_seconds'] = Variable<double>(zeroToHundredSeconds);
    }
    map['kept'] = Variable<bool>(kept);
    map['client_uuid'] = Variable<String>(clientUuid);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || heatFoldedAt != null) {
      map['heat_folded_at'] = Variable<DateTime>(heatFoldedAt);
    }
    if (!nullToAbsent || cloudVehicleId != null) {
      map['cloud_vehicle_id'] = Variable<int>(cloudVehicleId);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      maxSpeed: Value(maxSpeed),
      avgSpeed: Value(avgSpeed),
      distance: Value(distance),
      elevationGain: Value(elevationGain),
      durationSeconds: Value(durationSeconds),
      zeroToHundredSeconds: zeroToHundredSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(zeroToHundredSeconds),
      kept: Value(kept),
      clientUuid: Value(clientUuid),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      heatFoldedAt: heatFoldedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(heatFoldedAt),
      cloudVehicleId: cloudVehicleId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudVehicleId),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<int>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      maxSpeed: serializer.fromJson<double>(json['maxSpeed']),
      avgSpeed: serializer.fromJson<double>(json['avgSpeed']),
      distance: serializer.fromJson<double>(json['distance']),
      elevationGain: serializer.fromJson<double>(json['elevationGain']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      zeroToHundredSeconds: serializer.fromJson<double?>(
        json['zeroToHundredSeconds'],
      ),
      kept: serializer.fromJson<bool>(json['kept']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      heatFoldedAt: serializer.fromJson<DateTime?>(json['heatFoldedAt']),
      cloudVehicleId: serializer.fromJson<int?>(json['cloudVehicleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'maxSpeed': serializer.toJson<double>(maxSpeed),
      'avgSpeed': serializer.toJson<double>(avgSpeed),
      'distance': serializer.toJson<double>(distance),
      'elevationGain': serializer.toJson<double>(elevationGain),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'zeroToHundredSeconds': serializer.toJson<double?>(zeroToHundredSeconds),
      'kept': serializer.toJson<bool>(kept),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'heatFoldedAt': serializer.toJson<DateTime?>(heatFoldedAt),
      'cloudVehicleId': serializer.toJson<int?>(cloudVehicleId),
    };
  }

  Trip copyWith({
    int? id,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    double? maxSpeed,
    double? avgSpeed,
    double? distance,
    double? elevationGain,
    int? durationSeconds,
    Value<double?> zeroToHundredSeconds = const Value.absent(),
    bool? kept,
    String? clientUuid,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> heatFoldedAt = const Value.absent(),
    Value<int?> cloudVehicleId = const Value.absent(),
  }) => Trip(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    maxSpeed: maxSpeed ?? this.maxSpeed,
    avgSpeed: avgSpeed ?? this.avgSpeed,
    distance: distance ?? this.distance,
    elevationGain: elevationGain ?? this.elevationGain,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    zeroToHundredSeconds: zeroToHundredSeconds.present
        ? zeroToHundredSeconds.value
        : this.zeroToHundredSeconds,
    kept: kept ?? this.kept,
    clientUuid: clientUuid ?? this.clientUuid,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    heatFoldedAt: heatFoldedAt.present ? heatFoldedAt.value : this.heatFoldedAt,
    cloudVehicleId: cloudVehicleId.present
        ? cloudVehicleId.value
        : this.cloudVehicleId,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      maxSpeed: data.maxSpeed.present ? data.maxSpeed.value : this.maxSpeed,
      avgSpeed: data.avgSpeed.present ? data.avgSpeed.value : this.avgSpeed,
      distance: data.distance.present ? data.distance.value : this.distance,
      elevationGain: data.elevationGain.present
          ? data.elevationGain.value
          : this.elevationGain,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      zeroToHundredSeconds: data.zeroToHundredSeconds.present
          ? data.zeroToHundredSeconds.value
          : this.zeroToHundredSeconds,
      kept: data.kept.present ? data.kept.value : this.kept,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      heatFoldedAt: data.heatFoldedAt.present
          ? data.heatFoldedAt.value
          : this.heatFoldedAt,
      cloudVehicleId: data.cloudVehicleId.present
          ? data.cloudVehicleId.value
          : this.cloudVehicleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('avgSpeed: $avgSpeed, ')
          ..write('distance: $distance, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('zeroToHundredSeconds: $zeroToHundredSeconds, ')
          ..write('kept: $kept, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('heatFoldedAt: $heatFoldedAt, ')
          ..write('cloudVehicleId: $cloudVehicleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startTime,
    endTime,
    maxSpeed,
    avgSpeed,
    distance,
    elevationGain,
    durationSeconds,
    zeroToHundredSeconds,
    kept,
    clientUuid,
    syncedAt,
    heatFoldedAt,
    cloudVehicleId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.maxSpeed == this.maxSpeed &&
          other.avgSpeed == this.avgSpeed &&
          other.distance == this.distance &&
          other.elevationGain == this.elevationGain &&
          other.durationSeconds == this.durationSeconds &&
          other.zeroToHundredSeconds == this.zeroToHundredSeconds &&
          other.kept == this.kept &&
          other.clientUuid == this.clientUuid &&
          other.syncedAt == this.syncedAt &&
          other.heatFoldedAt == this.heatFoldedAt &&
          other.cloudVehicleId == this.cloudVehicleId);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> id;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<double> maxSpeed;
  final Value<double> avgSpeed;
  final Value<double> distance;
  final Value<double> elevationGain;
  final Value<int> durationSeconds;
  final Value<double?> zeroToHundredSeconds;
  final Value<bool> kept;
  final Value<String> clientUuid;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> heatFoldedAt;
  final Value<int?> cloudVehicleId;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.maxSpeed = const Value.absent(),
    this.avgSpeed = const Value.absent(),
    this.distance = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.zeroToHundredSeconds = const Value.absent(),
    this.kept = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.heatFoldedAt = const Value.absent(),
    this.cloudVehicleId = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.maxSpeed = const Value.absent(),
    this.avgSpeed = const Value.absent(),
    this.distance = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.zeroToHundredSeconds = const Value.absent(),
    this.kept = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.heatFoldedAt = const Value.absent(),
    this.cloudVehicleId = const Value.absent(),
  }) : startTime = Value(startTime);
  static Insertable<Trip> custom({
    Expression<int>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<double>? maxSpeed,
    Expression<double>? avgSpeed,
    Expression<double>? distance,
    Expression<double>? elevationGain,
    Expression<int>? durationSeconds,
    Expression<double>? zeroToHundredSeconds,
    Expression<bool>? kept,
    Expression<String>? clientUuid,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? heatFoldedAt,
    Expression<int>? cloudVehicleId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (maxSpeed != null) 'max_speed': maxSpeed,
      if (avgSpeed != null) 'avg_speed': avgSpeed,
      if (distance != null) 'distance': distance,
      if (elevationGain != null) 'elevation_gain': elevationGain,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (zeroToHundredSeconds != null)
        'zero_to_hundred_seconds': zeroToHundredSeconds,
      if (kept != null) 'kept': kept,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (heatFoldedAt != null) 'heat_folded_at': heatFoldedAt,
      if (cloudVehicleId != null) 'cloud_vehicle_id': cloudVehicleId,
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<double>? maxSpeed,
    Value<double>? avgSpeed,
    Value<double>? distance,
    Value<double>? elevationGain,
    Value<int>? durationSeconds,
    Value<double?>? zeroToHundredSeconds,
    Value<bool>? kept,
    Value<String>? clientUuid,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? heatFoldedAt,
    Value<int?>? cloudVehicleId,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      zeroToHundredSeconds: zeroToHundredSeconds ?? this.zeroToHundredSeconds,
      kept: kept ?? this.kept,
      clientUuid: clientUuid ?? this.clientUuid,
      syncedAt: syncedAt ?? this.syncedAt,
      heatFoldedAt: heatFoldedAt ?? this.heatFoldedAt,
      cloudVehicleId: cloudVehicleId ?? this.cloudVehicleId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (maxSpeed.present) {
      map['max_speed'] = Variable<double>(maxSpeed.value);
    }
    if (avgSpeed.present) {
      map['avg_speed'] = Variable<double>(avgSpeed.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (elevationGain.present) {
      map['elevation_gain'] = Variable<double>(elevationGain.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (zeroToHundredSeconds.present) {
      map['zero_to_hundred_seconds'] = Variable<double>(
        zeroToHundredSeconds.value,
      );
    }
    if (kept.present) {
      map['kept'] = Variable<bool>(kept.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (heatFoldedAt.present) {
      map['heat_folded_at'] = Variable<DateTime>(heatFoldedAt.value);
    }
    if (cloudVehicleId.present) {
      map['cloud_vehicle_id'] = Variable<int>(cloudVehicleId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('avgSpeed: $avgSpeed, ')
          ..write('distance: $distance, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('zeroToHundredSeconds: $zeroToHundredSeconds, ')
          ..write('kept: $kept, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('heatFoldedAt: $heatFoldedAt, ')
          ..write('cloudVehicleId: $cloudVehicleId')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    lat,
    lng,
    speed,
    altitude,
    accuracy,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_altitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPoint extends DataClass implements Insertable<TrackPoint> {
  final int id;
  final int tripId;
  final double lat;
  final double lng;
  final double speed;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
  const TrackPoint({
    required this.id,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['speed'] = Variable<double>(speed);
    map['altitude'] = Variable<double>(altitude);
    map['accuracy'] = Variable<double>(accuracy);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      lat: Value(lat),
      lng: Value(lng),
      speed: Value(speed),
      altitude: Value(altitude),
      accuracy: Value(accuracy),
      timestamp: Value(timestamp),
    );
  }

  factory TrackPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPoint(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      speed: serializer.fromJson<double>(json['speed']),
      altitude: serializer.fromJson<double>(json['altitude']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'speed': serializer.toJson<double>(speed),
      'altitude': serializer.toJson<double>(altitude),
      'accuracy': serializer.toJson<double>(accuracy),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  TrackPoint copyWith({
    int? id,
    int? tripId,
    double? lat,
    double? lng,
    double? speed,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
  }) => TrackPoint(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    speed: speed ?? this.speed,
    altitude: altitude ?? this.altitude,
    accuracy: accuracy ?? this.accuracy,
    timestamp: timestamp ?? this.timestamp,
  );
  TrackPoint copyWithCompanion(TrackPointsCompanion data) {
    return TrackPoint(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      speed: data.speed.present ? data.speed.value : this.speed,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPoint(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speed: $speed, ')
          ..write('altitude: $altitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tripId, lat, lng, speed, altitude, accuracy, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPoint &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.speed == this.speed &&
          other.altitude == this.altitude &&
          other.accuracy == this.accuracy &&
          other.timestamp == this.timestamp);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPoint> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> speed;
  final Value<double> altitude;
  final Value<double> accuracy;
  final Value<DateTime> timestamp;
  const TrackPointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.speed = const Value.absent(),
    this.altitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required double lat,
    required double lng,
    required double speed,
    required double altitude,
    required double accuracy,
    required DateTime timestamp,
  }) : tripId = Value(tripId),
       lat = Value(lat),
       lng = Value(lng),
       speed = Value(speed),
       altitude = Value(altitude),
       accuracy = Value(accuracy),
       timestamp = Value(timestamp);
  static Insertable<TrackPoint> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? speed,
    Expression<double>? altitude,
    Expression<double>? accuracy,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (speed != null) 'speed': speed,
      if (altitude != null) 'altitude': altitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  TrackPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? tripId,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? speed,
    Value<double>? altitude,
    Value<double>? accuracy,
    Value<DateTime>? timestamp,
  }) {
    return TrackPointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speed: $speed, ')
          ..write('altitude: $altitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $HeatCellsTable extends HeatCells
    with TableInfo<$HeatCellsTable, HeatCellRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeatCellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cellRowMeta = const VerificationMeta(
    'cellRow',
  );
  @override
  late final GeneratedColumn<int> cellRow = GeneratedColumn<int>(
    'cell_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cellColMeta = const VerificationMeta(
    'cellCol',
  );
  @override
  late final GeneratedColumn<int> cellCol = GeneratedColumn<int>(
    'cell_col',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latSumMeta = const VerificationMeta('latSum');
  @override
  late final GeneratedColumn<double> latSum = GeneratedColumn<double>(
    'lat_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lngSumMeta = const VerificationMeta('lngSum');
  @override
  late final GeneratedColumn<double> lngSum = GeneratedColumn<double>(
    'lng_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nMeta = const VerificationMeta('n');
  @override
  late final GeneratedColumn<int> n = GeneratedColumn<int>(
    'n',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _speedSumMeta = const VerificationMeta(
    'speedSum',
  );
  @override
  late final GeneratedColumn<double> speedSum = GeneratedColumn<double>(
    'speed_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    level,
    cellRow,
    cellCol,
    latSum,
    lngSum,
    n,
    speedSum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heat_cells';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeatCellRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('cell_row')) {
      context.handle(
        _cellRowMeta,
        cellRow.isAcceptableOrUnknown(data['cell_row']!, _cellRowMeta),
      );
    } else if (isInserting) {
      context.missing(_cellRowMeta);
    }
    if (data.containsKey('cell_col')) {
      context.handle(
        _cellColMeta,
        cellCol.isAcceptableOrUnknown(data['cell_col']!, _cellColMeta),
      );
    } else if (isInserting) {
      context.missing(_cellColMeta);
    }
    if (data.containsKey('lat_sum')) {
      context.handle(
        _latSumMeta,
        latSum.isAcceptableOrUnknown(data['lat_sum']!, _latSumMeta),
      );
    }
    if (data.containsKey('lng_sum')) {
      context.handle(
        _lngSumMeta,
        lngSum.isAcceptableOrUnknown(data['lng_sum']!, _lngSumMeta),
      );
    }
    if (data.containsKey('n')) {
      context.handle(_nMeta, n.isAcceptableOrUnknown(data['n']!, _nMeta));
    }
    if (data.containsKey('speed_sum')) {
      context.handle(
        _speedSumMeta,
        speedSum.isAcceptableOrUnknown(data['speed_sum']!, _speedSumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {level, cellRow, cellCol};
  @override
  HeatCellRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeatCellRow(
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      cellRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cell_row'],
      )!,
      cellCol: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cell_col'],
      )!,
      latSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat_sum'],
      )!,
      lngSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng_sum'],
      )!,
      n: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}n'],
      )!,
      speedSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_sum'],
      )!,
    );
  }

  @override
  $HeatCellsTable createAlias(String alias) {
    return $HeatCellsTable(attachedDatabase, alias);
  }
}

class HeatCellRow extends DataClass implements Insertable<HeatCellRow> {
  final int level;
  final int cellRow;
  final int cellCol;
  final double latSum;
  final double lngSum;
  final int n;

  /// Summe der gemessenen Geschwindigkeiten in dieser Zelle, in m/s.
  ///
  /// Geteilt durch [n] ergibt sie, wie schnell hier ueblicherweise
  /// gefahren wird -- die Bezugsgroesse fuer "zu schnell" auf dem
  /// Sperrbildschirm. Die App kennt keine Tempolimits, und es gibt dafuer
  /// keine brauchbare freie Quelle; verglichen wird deshalb mit der
  /// eigenen Gewohnheit.
  ///
  /// Bewusst **nicht** Teil von `HeatGrid`: jenes ist der zeilengetreue
  /// Spiegel von `HeatGrid.php`, und eine zusaetzliche Spalte hier duerfte
  /// die Rasterparitaet zwischen Dart und PHP nicht beruehren.
  final double speedSum;
  const HeatCellRow({
    required this.level,
    required this.cellRow,
    required this.cellCol,
    required this.latSum,
    required this.lngSum,
    required this.n,
    required this.speedSum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level'] = Variable<int>(level);
    map['cell_row'] = Variable<int>(cellRow);
    map['cell_col'] = Variable<int>(cellCol);
    map['lat_sum'] = Variable<double>(latSum);
    map['lng_sum'] = Variable<double>(lngSum);
    map['n'] = Variable<int>(n);
    map['speed_sum'] = Variable<double>(speedSum);
    return map;
  }

  HeatCellsCompanion toCompanion(bool nullToAbsent) {
    return HeatCellsCompanion(
      level: Value(level),
      cellRow: Value(cellRow),
      cellCol: Value(cellCol),
      latSum: Value(latSum),
      lngSum: Value(lngSum),
      n: Value(n),
      speedSum: Value(speedSum),
    );
  }

  factory HeatCellRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeatCellRow(
      level: serializer.fromJson<int>(json['level']),
      cellRow: serializer.fromJson<int>(json['cellRow']),
      cellCol: serializer.fromJson<int>(json['cellCol']),
      latSum: serializer.fromJson<double>(json['latSum']),
      lngSum: serializer.fromJson<double>(json['lngSum']),
      n: serializer.fromJson<int>(json['n']),
      speedSum: serializer.fromJson<double>(json['speedSum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'level': serializer.toJson<int>(level),
      'cellRow': serializer.toJson<int>(cellRow),
      'cellCol': serializer.toJson<int>(cellCol),
      'latSum': serializer.toJson<double>(latSum),
      'lngSum': serializer.toJson<double>(lngSum),
      'n': serializer.toJson<int>(n),
      'speedSum': serializer.toJson<double>(speedSum),
    };
  }

  HeatCellRow copyWith({
    int? level,
    int? cellRow,
    int? cellCol,
    double? latSum,
    double? lngSum,
    int? n,
    double? speedSum,
  }) => HeatCellRow(
    level: level ?? this.level,
    cellRow: cellRow ?? this.cellRow,
    cellCol: cellCol ?? this.cellCol,
    latSum: latSum ?? this.latSum,
    lngSum: lngSum ?? this.lngSum,
    n: n ?? this.n,
    speedSum: speedSum ?? this.speedSum,
  );
  HeatCellRow copyWithCompanion(HeatCellsCompanion data) {
    return HeatCellRow(
      level: data.level.present ? data.level.value : this.level,
      cellRow: data.cellRow.present ? data.cellRow.value : this.cellRow,
      cellCol: data.cellCol.present ? data.cellCol.value : this.cellCol,
      latSum: data.latSum.present ? data.latSum.value : this.latSum,
      lngSum: data.lngSum.present ? data.lngSum.value : this.lngSum,
      n: data.n.present ? data.n.value : this.n,
      speedSum: data.speedSum.present ? data.speedSum.value : this.speedSum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeatCellRow(')
          ..write('level: $level, ')
          ..write('cellRow: $cellRow, ')
          ..write('cellCol: $cellCol, ')
          ..write('latSum: $latSum, ')
          ..write('lngSum: $lngSum, ')
          ..write('n: $n, ')
          ..write('speedSum: $speedSum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(level, cellRow, cellCol, latSum, lngSum, n, speedSum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeatCellRow &&
          other.level == this.level &&
          other.cellRow == this.cellRow &&
          other.cellCol == this.cellCol &&
          other.latSum == this.latSum &&
          other.lngSum == this.lngSum &&
          other.n == this.n &&
          other.speedSum == this.speedSum);
}

class HeatCellsCompanion extends UpdateCompanion<HeatCellRow> {
  final Value<int> level;
  final Value<int> cellRow;
  final Value<int> cellCol;
  final Value<double> latSum;
  final Value<double> lngSum;
  final Value<int> n;
  final Value<double> speedSum;
  final Value<int> rowid;
  const HeatCellsCompanion({
    this.level = const Value.absent(),
    this.cellRow = const Value.absent(),
    this.cellCol = const Value.absent(),
    this.latSum = const Value.absent(),
    this.lngSum = const Value.absent(),
    this.n = const Value.absent(),
    this.speedSum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeatCellsCompanion.insert({
    required int level,
    required int cellRow,
    required int cellCol,
    this.latSum = const Value.absent(),
    this.lngSum = const Value.absent(),
    this.n = const Value.absent(),
    this.speedSum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : level = Value(level),
       cellRow = Value(cellRow),
       cellCol = Value(cellCol);
  static Insertable<HeatCellRow> custom({
    Expression<int>? level,
    Expression<int>? cellRow,
    Expression<int>? cellCol,
    Expression<double>? latSum,
    Expression<double>? lngSum,
    Expression<int>? n,
    Expression<double>? speedSum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (level != null) 'level': level,
      if (cellRow != null) 'cell_row': cellRow,
      if (cellCol != null) 'cell_col': cellCol,
      if (latSum != null) 'lat_sum': latSum,
      if (lngSum != null) 'lng_sum': lngSum,
      if (n != null) 'n': n,
      if (speedSum != null) 'speed_sum': speedSum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeatCellsCompanion copyWith({
    Value<int>? level,
    Value<int>? cellRow,
    Value<int>? cellCol,
    Value<double>? latSum,
    Value<double>? lngSum,
    Value<int>? n,
    Value<double>? speedSum,
    Value<int>? rowid,
  }) {
    return HeatCellsCompanion(
      level: level ?? this.level,
      cellRow: cellRow ?? this.cellRow,
      cellCol: cellCol ?? this.cellCol,
      latSum: latSum ?? this.latSum,
      lngSum: lngSum ?? this.lngSum,
      n: n ?? this.n,
      speedSum: speedSum ?? this.speedSum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (cellRow.present) {
      map['cell_row'] = Variable<int>(cellRow.value);
    }
    if (cellCol.present) {
      map['cell_col'] = Variable<int>(cellCol.value);
    }
    if (latSum.present) {
      map['lat_sum'] = Variable<double>(latSum.value);
    }
    if (lngSum.present) {
      map['lng_sum'] = Variable<double>(lngSum.value);
    }
    if (n.present) {
      map['n'] = Variable<int>(n.value);
    }
    if (speedSum.present) {
      map['speed_sum'] = Variable<double>(speedSum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeatCellsCompanion(')
          ..write('level: $level, ')
          ..write('cellRow: $cellRow, ')
          ..write('cellCol: $cellCol, ')
          ..write('latSum: $latSum, ')
          ..write('lngSum: $lngSum, ')
          ..write('n: $n, ')
          ..write('speedSum: $speedSum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeatEdgesTable extends HeatEdges
    with TableInfo<$HeatEdgesTable, HeatEdgeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeatEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aRowMeta = const VerificationMeta('aRow');
  @override
  late final GeneratedColumn<int> aRow = GeneratedColumn<int>(
    'a_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aColMeta = const VerificationMeta('aCol');
  @override
  late final GeneratedColumn<int> aCol = GeneratedColumn<int>(
    'a_col',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bRowMeta = const VerificationMeta('bRow');
  @override
  late final GeneratedColumn<int> bRow = GeneratedColumn<int>(
    'b_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bColMeta = const VerificationMeta('bCol');
  @override
  late final GeneratedColumn<int> bCol = GeneratedColumn<int>(
    'b_col',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [level, aRow, aCol, bRow, bCol, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heat_edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeatEdgeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('a_row')) {
      context.handle(
        _aRowMeta,
        aRow.isAcceptableOrUnknown(data['a_row']!, _aRowMeta),
      );
    } else if (isInserting) {
      context.missing(_aRowMeta);
    }
    if (data.containsKey('a_col')) {
      context.handle(
        _aColMeta,
        aCol.isAcceptableOrUnknown(data['a_col']!, _aColMeta),
      );
    } else if (isInserting) {
      context.missing(_aColMeta);
    }
    if (data.containsKey('b_row')) {
      context.handle(
        _bRowMeta,
        bRow.isAcceptableOrUnknown(data['b_row']!, _bRowMeta),
      );
    } else if (isInserting) {
      context.missing(_bRowMeta);
    }
    if (data.containsKey('b_col')) {
      context.handle(
        _bColMeta,
        bCol.isAcceptableOrUnknown(data['b_col']!, _bColMeta),
      );
    } else if (isInserting) {
      context.missing(_bColMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {level, aRow, aCol, bRow, bCol};
  @override
  HeatEdgeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeatEdgeRow(
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      aRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}a_row'],
      )!,
      aCol: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}a_col'],
      )!,
      bRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b_row'],
      )!,
      bCol: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b_col'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $HeatEdgesTable createAlias(String alias) {
    return $HeatEdgesTable(attachedDatabase, alias);
  }
}

class HeatEdgeRow extends DataClass implements Insertable<HeatEdgeRow> {
  final int level;
  final int aRow;
  final int aCol;
  final int bRow;
  final int bCol;
  final int count;
  const HeatEdgeRow({
    required this.level,
    required this.aRow,
    required this.aCol,
    required this.bRow,
    required this.bCol,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level'] = Variable<int>(level);
    map['a_row'] = Variable<int>(aRow);
    map['a_col'] = Variable<int>(aCol);
    map['b_row'] = Variable<int>(bRow);
    map['b_col'] = Variable<int>(bCol);
    map['count'] = Variable<int>(count);
    return map;
  }

  HeatEdgesCompanion toCompanion(bool nullToAbsent) {
    return HeatEdgesCompanion(
      level: Value(level),
      aRow: Value(aRow),
      aCol: Value(aCol),
      bRow: Value(bRow),
      bCol: Value(bCol),
      count: Value(count),
    );
  }

  factory HeatEdgeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeatEdgeRow(
      level: serializer.fromJson<int>(json['level']),
      aRow: serializer.fromJson<int>(json['aRow']),
      aCol: serializer.fromJson<int>(json['aCol']),
      bRow: serializer.fromJson<int>(json['bRow']),
      bCol: serializer.fromJson<int>(json['bCol']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'level': serializer.toJson<int>(level),
      'aRow': serializer.toJson<int>(aRow),
      'aCol': serializer.toJson<int>(aCol),
      'bRow': serializer.toJson<int>(bRow),
      'bCol': serializer.toJson<int>(bCol),
      'count': serializer.toJson<int>(count),
    };
  }

  HeatEdgeRow copyWith({
    int? level,
    int? aRow,
    int? aCol,
    int? bRow,
    int? bCol,
    int? count,
  }) => HeatEdgeRow(
    level: level ?? this.level,
    aRow: aRow ?? this.aRow,
    aCol: aCol ?? this.aCol,
    bRow: bRow ?? this.bRow,
    bCol: bCol ?? this.bCol,
    count: count ?? this.count,
  );
  HeatEdgeRow copyWithCompanion(HeatEdgesCompanion data) {
    return HeatEdgeRow(
      level: data.level.present ? data.level.value : this.level,
      aRow: data.aRow.present ? data.aRow.value : this.aRow,
      aCol: data.aCol.present ? data.aCol.value : this.aCol,
      bRow: data.bRow.present ? data.bRow.value : this.bRow,
      bCol: data.bCol.present ? data.bCol.value : this.bCol,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeatEdgeRow(')
          ..write('level: $level, ')
          ..write('aRow: $aRow, ')
          ..write('aCol: $aCol, ')
          ..write('bRow: $bRow, ')
          ..write('bCol: $bCol, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(level, aRow, aCol, bRow, bCol, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeatEdgeRow &&
          other.level == this.level &&
          other.aRow == this.aRow &&
          other.aCol == this.aCol &&
          other.bRow == this.bRow &&
          other.bCol == this.bCol &&
          other.count == this.count);
}

class HeatEdgesCompanion extends UpdateCompanion<HeatEdgeRow> {
  final Value<int> level;
  final Value<int> aRow;
  final Value<int> aCol;
  final Value<int> bRow;
  final Value<int> bCol;
  final Value<int> count;
  final Value<int> rowid;
  const HeatEdgesCompanion({
    this.level = const Value.absent(),
    this.aRow = const Value.absent(),
    this.aCol = const Value.absent(),
    this.bRow = const Value.absent(),
    this.bCol = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeatEdgesCompanion.insert({
    required int level,
    required int aRow,
    required int aCol,
    required int bRow,
    required int bCol,
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : level = Value(level),
       aRow = Value(aRow),
       aCol = Value(aCol),
       bRow = Value(bRow),
       bCol = Value(bCol);
  static Insertable<HeatEdgeRow> custom({
    Expression<int>? level,
    Expression<int>? aRow,
    Expression<int>? aCol,
    Expression<int>? bRow,
    Expression<int>? bCol,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (level != null) 'level': level,
      if (aRow != null) 'a_row': aRow,
      if (aCol != null) 'a_col': aCol,
      if (bRow != null) 'b_row': bRow,
      if (bCol != null) 'b_col': bCol,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeatEdgesCompanion copyWith({
    Value<int>? level,
    Value<int>? aRow,
    Value<int>? aCol,
    Value<int>? bRow,
    Value<int>? bCol,
    Value<int>? count,
    Value<int>? rowid,
  }) {
    return HeatEdgesCompanion(
      level: level ?? this.level,
      aRow: aRow ?? this.aRow,
      aCol: aCol ?? this.aCol,
      bRow: bRow ?? this.bRow,
      bCol: bCol ?? this.bCol,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (aRow.present) {
      map['a_row'] = Variable<int>(aRow.value);
    }
    if (aCol.present) {
      map['a_col'] = Variable<int>(aCol.value);
    }
    if (bRow.present) {
      map['b_row'] = Variable<int>(bRow.value);
    }
    if (bCol.present) {
      map['b_col'] = Variable<int>(bCol.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeatEdgesCompanion(')
          ..write('level: $level, ')
          ..write('aRow: $aRow, ')
          ..write('aCol: $aCol, ')
          ..write('bRow: $bRow, ')
          ..write('bCol: $bCol, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeatSnapshotsTable extends HeatSnapshots
    with TableInfo<$HeatSnapshotsTable, HeatSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeatSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeMeta = const VerificationMeta('range');
  @override
  late final GeneratedColumn<String> range = GeneratedColumn<String>(
    'range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [level, range, payload, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heat_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeatSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('range')) {
      context.handle(
        _rangeMeta,
        range.isAcceptableOrUnknown(data['range']!, _rangeMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {level, range};
  @override
  HeatSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeatSnapshotRow(
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      range: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $HeatSnapshotsTable createAlias(String alias) {
    return $HeatSnapshotsTable(attachedDatabase, alias);
  }
}

class HeatSnapshotRow extends DataClass implements Insertable<HeatSnapshotRow> {
  final int level;
  final String range;

  /// Kanten und Maximum als JSON. Ein eigenes Tabellenschema dafuer waere
  /// eine zweite, konkurrierende Darstellung derselben Kanten neben
  /// HeatEdges -- der Vorrat wird nur als Ganzes geschrieben und gelesen,
  /// nie einzeln abgefragt.
  final String payload;
  final DateTime fetchedAt;
  const HeatSnapshotRow({
    required this.level,
    required this.range,
    required this.payload,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level'] = Variable<int>(level);
    map['range'] = Variable<String>(range);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  HeatSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return HeatSnapshotsCompanion(
      level: Value(level),
      range: Value(range),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory HeatSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeatSnapshotRow(
      level: serializer.fromJson<int>(json['level']),
      range: serializer.fromJson<String>(json['range']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'level': serializer.toJson<int>(level),
      'range': serializer.toJson<String>(range),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  HeatSnapshotRow copyWith({
    int? level,
    String? range,
    String? payload,
    DateTime? fetchedAt,
  }) => HeatSnapshotRow(
    level: level ?? this.level,
    range: range ?? this.range,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  HeatSnapshotRow copyWithCompanion(HeatSnapshotsCompanion data) {
    return HeatSnapshotRow(
      level: data.level.present ? data.level.value : this.level,
      range: data.range.present ? data.range.value : this.range,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeatSnapshotRow(')
          ..write('level: $level, ')
          ..write('range: $range, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(level, range, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeatSnapshotRow &&
          other.level == this.level &&
          other.range == this.range &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class HeatSnapshotsCompanion extends UpdateCompanion<HeatSnapshotRow> {
  final Value<int> level;
  final Value<String> range;
  final Value<String> payload;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const HeatSnapshotsCompanion({
    this.level = const Value.absent(),
    this.range = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeatSnapshotsCompanion.insert({
    required int level,
    required String range,
    required String payload,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : level = Value(level),
       range = Value(range),
       payload = Value(payload),
       fetchedAt = Value(fetchedAt);
  static Insertable<HeatSnapshotRow> custom({
    Expression<int>? level,
    Expression<String>? range,
    Expression<String>? payload,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (level != null) 'level': level,
      if (range != null) 'range': range,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeatSnapshotsCompanion copyWith({
    Value<int>? level,
    Value<String>? range,
    Value<String>? payload,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return HeatSnapshotsCompanion(
      level: level ?? this.level,
      range: range ?? this.range,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (range.present) {
      map['range'] = Variable<String>(range.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeatSnapshotsCompanion(')
          ..write('level: $level, ')
          ..write('range: $range, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $HeatCellsTable heatCells = $HeatCellsTable(this);
  late final $HeatEdgesTable heatEdges = $HeatEdgesTable(this);
  late final $HeatSnapshotsTable heatSnapshots = $HeatSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trips,
    trackPoints,
    heatCells,
    heatEdges,
    heatSnapshots,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_points', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<double> maxSpeed,
      Value<double> avgSpeed,
      Value<double> distance,
      Value<double> elevationGain,
      Value<int> durationSeconds,
      Value<double?> zeroToHundredSeconds,
      Value<bool> kept,
      Value<String> clientUuid,
      Value<DateTime?> syncedAt,
      Value<DateTime?> heatFoldedAt,
      Value<int?> cloudVehicleId,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<double> maxSpeed,
      Value<double> avgSpeed,
      Value<double> distance,
      Value<double> elevationGain,
      Value<int> durationSeconds,
      Value<double?> zeroToHundredSeconds,
      Value<bool> kept,
      Value<String> clientUuid,
      Value<DateTime?> syncedAt,
      Value<DateTime?> heatFoldedAt,
      Value<int?> cloudVehicleId,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPoint>>
  _trackPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackPoints,
    aliasName: 'trips__id__track_points__trip_id',
  );

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager(
      $_db,
      $_db.trackPoints,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
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

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeed => $composableBuilder(
    column: $table.maxSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgSpeed => $composableBuilder(
    column: $table.avgSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zeroToHundredSeconds => $composableBuilder(
    column: $table.zeroToHundredSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kept => $composableBuilder(
    column: $table.kept,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get heatFoldedAt => $composableBuilder(
    column: $table.heatFoldedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudVehicleId => $composableBuilder(
    column: $table.cloudVehicleId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackPointsRefs(
    Expression<bool> Function($$TrackPointsTableFilterComposer f) f,
  ) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeed => $composableBuilder(
    column: $table.maxSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgSpeed => $composableBuilder(
    column: $table.avgSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zeroToHundredSeconds => $composableBuilder(
    column: $table.zeroToHundredSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kept => $composableBuilder(
    column: $table.kept,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get heatFoldedAt => $composableBuilder(
    column: $table.heatFoldedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudVehicleId => $composableBuilder(
    column: $table.cloudVehicleId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<double> get maxSpeed =>
      $composableBuilder(column: $table.maxSpeed, builder: (column) => column);

  GeneratedColumn<double> get avgSpeed =>
      $composableBuilder(column: $table.avgSpeed, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get zeroToHundredSeconds => $composableBuilder(
    column: $table.zeroToHundredSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kept =>
      $composableBuilder(column: $table.kept, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get heatFoldedAt => $composableBuilder(
    column: $table.heatFoldedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudVehicleId => $composableBuilder(
    column: $table.cloudVehicleId,
    builder: (column) => column,
  );

  Expression<T> trackPointsRefs<T extends Object>(
    Expression<T> Function($$TrackPointsTableAnnotationComposer a) f,
  ) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, $$TripsTableReferences),
          Trip,
          PrefetchHooks Function({bool trackPointsRefs})
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<double> maxSpeed = const Value.absent(),
                Value<double> avgSpeed = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<double> elevationGain = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double?> zeroToHundredSeconds = const Value.absent(),
                Value<bool> kept = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> heatFoldedAt = const Value.absent(),
                Value<int?> cloudVehicleId = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                startTime: startTime,
                endTime: endTime,
                maxSpeed: maxSpeed,
                avgSpeed: avgSpeed,
                distance: distance,
                elevationGain: elevationGain,
                durationSeconds: durationSeconds,
                zeroToHundredSeconds: zeroToHundredSeconds,
                kept: kept,
                clientUuid: clientUuid,
                syncedAt: syncedAt,
                heatFoldedAt: heatFoldedAt,
                cloudVehicleId: cloudVehicleId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<double> maxSpeed = const Value.absent(),
                Value<double> avgSpeed = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<double> elevationGain = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double?> zeroToHundredSeconds = const Value.absent(),
                Value<bool> kept = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> heatFoldedAt = const Value.absent(),
                Value<int?> cloudVehicleId = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                startTime: startTime,
                endTime: endTime,
                maxSpeed: maxSpeed,
                avgSpeed: avgSpeed,
                distance: distance,
                elevationGain: elevationGain,
                durationSeconds: durationSeconds,
                zeroToHundredSeconds: zeroToHundredSeconds,
                kept: kept,
                clientUuid: clientUuid,
                syncedAt: syncedAt,
                heatFoldedAt: heatFoldedAt,
                cloudVehicleId: cloudVehicleId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TripsTable, Trip>(table),
                  $$TripsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackPointsRefs) db.trackPoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackPointsRefs)
                    await $_getPrefetchedData<Trip, $TripsTable, TrackPoint>(
                      currentTable: table,
                      referencedTable: $$TripsTableReferences
                          ._trackPointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TripsTableReferences(db, table, p0).trackPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tripId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, $$TripsTableReferences),
      Trip,
      PrefetchHooks Function({bool trackPointsRefs})
    >;
typedef $$TrackPointsTableCreateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      required int tripId,
      required double lat,
      required double lng,
      required double speed,
      required double altitude,
      required double accuracy,
      required DateTime timestamp,
    });
typedef $$TrackPointsTableUpdateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      Value<int> tripId,
      Value<double> lat,
      Value<double> lng,
      Value<double> speed,
      Value<double> altitude,
      Value<double> accuracy,
      Value<DateTime> timestamp,
    });

final class $$TrackPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackPointsTable, TrackPoint> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('track_points__trip_id__trips__id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<int>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
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

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
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

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackPointsTable,
          TrackPoint,
          $$TrackPointsTableFilterComposer,
          $$TrackPointsTableOrderingComposer,
          $$TrackPointsTableAnnotationComposer,
          $$TrackPointsTableCreateCompanionBuilder,
          $$TrackPointsTableUpdateCompanionBuilder,
          (TrackPoint, $$TrackPointsTableReferences),
          TrackPoint,
          PrefetchHooks Function({bool tripId})
        > {
  $$TrackPointsTableTableManager(_$AppDatabase db, $TrackPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tripId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<double> altitude = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => TrackPointsCompanion(
                id: id,
                tripId: tripId,
                lat: lat,
                lng: lng,
                speed: speed,
                altitude: altitude,
                accuracy: accuracy,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tripId,
                required double lat,
                required double lng,
                required double speed,
                required double altitude,
                required double accuracy,
                required DateTime timestamp,
              }) => TrackPointsCompanion.insert(
                id: id,
                tripId: tripId,
                lat: lat,
                lng: lng,
                speed: speed,
                altitude: altitude,
                accuracy: accuracy,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackPointsTable, TrackPoint>(table),
                  $$TrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$TrackPointsTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$TrackPointsTableReferences
                                    ._tripIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackPointsTable,
      TrackPoint,
      $$TrackPointsTableFilterComposer,
      $$TrackPointsTableOrderingComposer,
      $$TrackPointsTableAnnotationComposer,
      $$TrackPointsTableCreateCompanionBuilder,
      $$TrackPointsTableUpdateCompanionBuilder,
      (TrackPoint, $$TrackPointsTableReferences),
      TrackPoint,
      PrefetchHooks Function({bool tripId})
    >;
typedef $$HeatCellsTableCreateCompanionBuilder =
    HeatCellsCompanion Function({
      required int level,
      required int cellRow,
      required int cellCol,
      Value<double> latSum,
      Value<double> lngSum,
      Value<int> n,
      Value<double> speedSum,
      Value<int> rowid,
    });
typedef $$HeatCellsTableUpdateCompanionBuilder =
    HeatCellsCompanion Function({
      Value<int> level,
      Value<int> cellRow,
      Value<int> cellCol,
      Value<double> latSum,
      Value<double> lngSum,
      Value<int> n,
      Value<double> speedSum,
      Value<int> rowid,
    });

class $$HeatCellsTableFilterComposer
    extends Composer<_$AppDatabase, $HeatCellsTable> {
  $$HeatCellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cellRow => $composableBuilder(
    column: $table.cellRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cellCol => $composableBuilder(
    column: $table.cellCol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latSum => $composableBuilder(
    column: $table.latSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lngSum => $composableBuilder(
    column: $table.lngSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get n => $composableBuilder(
    column: $table.n,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedSum => $composableBuilder(
    column: $table.speedSum,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HeatCellsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeatCellsTable> {
  $$HeatCellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cellRow => $composableBuilder(
    column: $table.cellRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cellCol => $composableBuilder(
    column: $table.cellCol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latSum => $composableBuilder(
    column: $table.latSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lngSum => $composableBuilder(
    column: $table.lngSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get n => $composableBuilder(
    column: $table.n,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedSum => $composableBuilder(
    column: $table.speedSum,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeatCellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeatCellsTable> {
  $$HeatCellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get cellRow =>
      $composableBuilder(column: $table.cellRow, builder: (column) => column);

  GeneratedColumn<int> get cellCol =>
      $composableBuilder(column: $table.cellCol, builder: (column) => column);

  GeneratedColumn<double> get latSum =>
      $composableBuilder(column: $table.latSum, builder: (column) => column);

  GeneratedColumn<double> get lngSum =>
      $composableBuilder(column: $table.lngSum, builder: (column) => column);

  GeneratedColumn<int> get n =>
      $composableBuilder(column: $table.n, builder: (column) => column);

  GeneratedColumn<double> get speedSum =>
      $composableBuilder(column: $table.speedSum, builder: (column) => column);
}

class $$HeatCellsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeatCellsTable,
          HeatCellRow,
          $$HeatCellsTableFilterComposer,
          $$HeatCellsTableOrderingComposer,
          $$HeatCellsTableAnnotationComposer,
          $$HeatCellsTableCreateCompanionBuilder,
          $$HeatCellsTableUpdateCompanionBuilder,
          (
            HeatCellRow,
            BaseReferences<_$AppDatabase, $HeatCellsTable, HeatCellRow>,
          ),
          HeatCellRow,
          PrefetchHooks Function()
        > {
  $$HeatCellsTableTableManager(_$AppDatabase db, $HeatCellsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeatCellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeatCellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeatCellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> level = const Value.absent(),
                Value<int> cellRow = const Value.absent(),
                Value<int> cellCol = const Value.absent(),
                Value<double> latSum = const Value.absent(),
                Value<double> lngSum = const Value.absent(),
                Value<int> n = const Value.absent(),
                Value<double> speedSum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeatCellsCompanion(
                level: level,
                cellRow: cellRow,
                cellCol: cellCol,
                latSum: latSum,
                lngSum: lngSum,
                n: n,
                speedSum: speedSum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int level,
                required int cellRow,
                required int cellCol,
                Value<double> latSum = const Value.absent(),
                Value<double> lngSum = const Value.absent(),
                Value<int> n = const Value.absent(),
                Value<double> speedSum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeatCellsCompanion.insert(
                level: level,
                cellRow: cellRow,
                cellCol: cellCol,
                latSum: latSum,
                lngSum: lngSum,
                n: n,
                speedSum: speedSum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeatCellsTable, HeatCellRow>(table),
                  BaseReferences<_$AppDatabase, $HeatCellsTable, HeatCellRow>(
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

typedef $$HeatCellsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeatCellsTable,
      HeatCellRow,
      $$HeatCellsTableFilterComposer,
      $$HeatCellsTableOrderingComposer,
      $$HeatCellsTableAnnotationComposer,
      $$HeatCellsTableCreateCompanionBuilder,
      $$HeatCellsTableUpdateCompanionBuilder,
      (
        HeatCellRow,
        BaseReferences<_$AppDatabase, $HeatCellsTable, HeatCellRow>,
      ),
      HeatCellRow,
      PrefetchHooks Function()
    >;
typedef $$HeatEdgesTableCreateCompanionBuilder =
    HeatEdgesCompanion Function({
      required int level,
      required int aRow,
      required int aCol,
      required int bRow,
      required int bCol,
      Value<int> count,
      Value<int> rowid,
    });
typedef $$HeatEdgesTableUpdateCompanionBuilder =
    HeatEdgesCompanion Function({
      Value<int> level,
      Value<int> aRow,
      Value<int> aCol,
      Value<int> bRow,
      Value<int> bCol,
      Value<int> count,
      Value<int> rowid,
    });

class $$HeatEdgesTableFilterComposer
    extends Composer<_$AppDatabase, $HeatEdgesTable> {
  $$HeatEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aRow => $composableBuilder(
    column: $table.aRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aCol => $composableBuilder(
    column: $table.aCol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bRow => $composableBuilder(
    column: $table.bRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bCol => $composableBuilder(
    column: $table.bCol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HeatEdgesTableOrderingComposer
    extends Composer<_$AppDatabase, $HeatEdgesTable> {
  $$HeatEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aRow => $composableBuilder(
    column: $table.aRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aCol => $composableBuilder(
    column: $table.aCol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bRow => $composableBuilder(
    column: $table.bRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bCol => $composableBuilder(
    column: $table.bCol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeatEdgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeatEdgesTable> {
  $$HeatEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get aRow =>
      $composableBuilder(column: $table.aRow, builder: (column) => column);

  GeneratedColumn<int> get aCol =>
      $composableBuilder(column: $table.aCol, builder: (column) => column);

  GeneratedColumn<int> get bRow =>
      $composableBuilder(column: $table.bRow, builder: (column) => column);

  GeneratedColumn<int> get bCol =>
      $composableBuilder(column: $table.bCol, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$HeatEdgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeatEdgesTable,
          HeatEdgeRow,
          $$HeatEdgesTableFilterComposer,
          $$HeatEdgesTableOrderingComposer,
          $$HeatEdgesTableAnnotationComposer,
          $$HeatEdgesTableCreateCompanionBuilder,
          $$HeatEdgesTableUpdateCompanionBuilder,
          (
            HeatEdgeRow,
            BaseReferences<_$AppDatabase, $HeatEdgesTable, HeatEdgeRow>,
          ),
          HeatEdgeRow,
          PrefetchHooks Function()
        > {
  $$HeatEdgesTableTableManager(_$AppDatabase db, $HeatEdgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeatEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeatEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeatEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> level = const Value.absent(),
                Value<int> aRow = const Value.absent(),
                Value<int> aCol = const Value.absent(),
                Value<int> bRow = const Value.absent(),
                Value<int> bCol = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeatEdgesCompanion(
                level: level,
                aRow: aRow,
                aCol: aCol,
                bRow: bRow,
                bCol: bCol,
                count: count,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int level,
                required int aRow,
                required int aCol,
                required int bRow,
                required int bCol,
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeatEdgesCompanion.insert(
                level: level,
                aRow: aRow,
                aCol: aCol,
                bRow: bRow,
                bCol: bCol,
                count: count,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeatEdgesTable, HeatEdgeRow>(table),
                  BaseReferences<_$AppDatabase, $HeatEdgesTable, HeatEdgeRow>(
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

typedef $$HeatEdgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeatEdgesTable,
      HeatEdgeRow,
      $$HeatEdgesTableFilterComposer,
      $$HeatEdgesTableOrderingComposer,
      $$HeatEdgesTableAnnotationComposer,
      $$HeatEdgesTableCreateCompanionBuilder,
      $$HeatEdgesTableUpdateCompanionBuilder,
      (
        HeatEdgeRow,
        BaseReferences<_$AppDatabase, $HeatEdgesTable, HeatEdgeRow>,
      ),
      HeatEdgeRow,
      PrefetchHooks Function()
    >;
typedef $$HeatSnapshotsTableCreateCompanionBuilder =
    HeatSnapshotsCompanion Function({
      required int level,
      required String range,
      required String payload,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$HeatSnapshotsTableUpdateCompanionBuilder =
    HeatSnapshotsCompanion Function({
      Value<int> level,
      Value<String> range,
      Value<String> payload,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$HeatSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $HeatSnapshotsTable> {
  $$HeatSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get range => $composableBuilder(
    column: $table.range,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HeatSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $HeatSnapshotsTable> {
  $$HeatSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get range => $composableBuilder(
    column: $table.range,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeatSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeatSnapshotsTable> {
  $$HeatSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get range =>
      $composableBuilder(column: $table.range, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$HeatSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeatSnapshotsTable,
          HeatSnapshotRow,
          $$HeatSnapshotsTableFilterComposer,
          $$HeatSnapshotsTableOrderingComposer,
          $$HeatSnapshotsTableAnnotationComposer,
          $$HeatSnapshotsTableCreateCompanionBuilder,
          $$HeatSnapshotsTableUpdateCompanionBuilder,
          (
            HeatSnapshotRow,
            BaseReferences<_$AppDatabase, $HeatSnapshotsTable, HeatSnapshotRow>,
          ),
          HeatSnapshotRow,
          PrefetchHooks Function()
        > {
  $$HeatSnapshotsTableTableManager(_$AppDatabase db, $HeatSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeatSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeatSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeatSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> level = const Value.absent(),
                Value<String> range = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeatSnapshotsCompanion(
                level: level,
                range: range,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int level,
                required String range,
                required String payload,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => HeatSnapshotsCompanion.insert(
                level: level,
                range: range,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeatSnapshotsTable, HeatSnapshotRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HeatSnapshotsTable,
                    HeatSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HeatSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeatSnapshotsTable,
      HeatSnapshotRow,
      $$HeatSnapshotsTableFilterComposer,
      $$HeatSnapshotsTableOrderingComposer,
      $$HeatSnapshotsTableAnnotationComposer,
      $$HeatSnapshotsTableCreateCompanionBuilder,
      $$HeatSnapshotsTableUpdateCompanionBuilder,
      (
        HeatSnapshotRow,
        BaseReferences<_$AppDatabase, $HeatSnapshotsTable, HeatSnapshotRow>,
      ),
      HeatSnapshotRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$HeatCellsTableTableManager get heatCells =>
      $$HeatCellsTableTableManager(_db, _db.heatCells);
  $$HeatEdgesTableTableManager get heatEdges =>
      $$HeatEdgesTableTableManager(_db, _db.heatEdges);
  $$HeatSnapshotsTableTableManager get heatSnapshots =>
      $$HeatSnapshotsTableTableManager(_db, _db.heatSnapshots);
}

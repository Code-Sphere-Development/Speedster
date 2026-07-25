/// A completed (or in-progress) drive. Speeds in m/s, distance/elevation in meters.
class Trip {
  const Trip({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.maxSpeed,
    required this.avgSpeed,
    required this.distance,
    required this.elevationGain,
    required this.durationSeconds,
    required this.zeroToHundredSeconds,
    required this.kept,
    this.clientUuid = '',
    this.syncedAt,
  });

  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double maxSpeed;
  final double avgSpeed;
  final double distance;
  final double elevationGain;
  final int durationSeconds;
  final double? zeroToHundredSeconds;

  /// false = discarded (rode as passenger); excluded from lists and rankings.
  final bool kept;

  /// Stable client-generated id for idempotent cloud upload.
  final String clientUuid;

  /// When this trip was uploaded to the cloud; null = not yet synced.
  final DateTime? syncedAt;

  Trip copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    double? maxSpeed,
    double? avgSpeed,
    double? distance,
    double? elevationGain,
    int? durationSeconds,
    double? zeroToHundredSeconds,
    bool? kept,
    String? clientUuid,
    DateTime? syncedAt,
  }) {
    return Trip(
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
    );
  }
}

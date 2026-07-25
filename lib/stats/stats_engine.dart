import 'dart:math' as math;

import 'package:speedster/domain/track_point.dart';

/// Computed metrics for a trip. All SI: speed m/s, distance/elevation meters.
class TripStats {
  const TripStats({
    required this.maxSpeed,
    required this.avgSpeed,
    required this.distance,
    required this.elevationGain,
    required this.durationSeconds,
    required this.zeroToHundredSeconds,
  });

  final double maxSpeed;
  final double avgSpeed;
  final double distance;
  final double elevationGain;
  final int durationSeconds;
  final double? zeroToHundredSeconds;

  static const empty = TripStats(
    maxSpeed: 0,
    avgSpeed: 0,
    distance: 0,
    elevationGain: 0,
    durationSeconds: 0,
    zeroToHundredSeconds: null,
  );
}

/// Pure functions over track points. No I/O, no platform dependencies.
class StatsEngine {
  static const _earthRadiusMeters = 6371000.0;

  /// 100 km/h expressed in m/s.
  static const _hundredKmhMps = 100 / 3.6;

  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  static TripStats compute(List<TrackPoint> points) {
    if (points.isEmpty) return TripStats.empty;

    var distance = 0.0;
    var elevationGain = 0.0;
    var maxSpeed = 0.0;
    var speedSum = 0.0;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      maxSpeed = math.max(maxSpeed, p.speed);
      speedSum += p.speed;
      if (i > 0) {
        final prev = points[i - 1];
        distance += haversineMeters(prev.lat, prev.lng, p.lat, p.lng);
        final dAlt = p.altitude - prev.altitude;
        if (dAlt > 0) elevationGain += dAlt;
      }
    }

    final durationSeconds =
        points.last.timestamp.difference(points.first.timestamp).inSeconds;
    final avgSpeed = speedSum / points.length;

    return TripStats(
      maxSpeed: maxSpeed,
      avgSpeed: avgSpeed,
      distance: distance,
      elevationGain: elevationGain,
      durationSeconds: durationSeconds,
      zeroToHundredSeconds: _zeroToHundred(points),
    );
  }

  static double? _zeroToHundred(List<TrackPoint> points) {
    DateTime? movingStart;
    for (final p in points) {
      if (movingStart == null) {
        if (p.speed > 0) movingStart = p.timestamp;
        continue;
      }
      if (p.speed >= _hundredKmhMps) {
        return p.timestamp.difference(movingStart).inMilliseconds / 1000.0;
      }
    }
    return null;
  }
}

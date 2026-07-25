/// A recorded point along a trip. SI units: speed m/s, altitude/accuracy meters.
class TrackPoint {
  const TrackPoint({
    this.id,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  final int? id;
  final int tripId;
  final double lat;
  final double lng;
  final double speed;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
}

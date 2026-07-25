/// A single normalized sensor reading. All values are SI units:
/// speed in m/s, altitude/accuracy in meters.
class Sample {
  const Sample({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    this.accelMagnitude,
  });

  final double lat;
  final double lng;
  final double speed;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  /// Magnitude of user acceleration (m/s^2), if available.
  final double? accelMagnitude;

  @override
  bool operator ==(Object other) =>
      other is Sample &&
      other.lat == lat &&
      other.lng == lng &&
      other.speed == speed &&
      other.altitude == altitude &&
      other.accuracy == accuracy &&
      other.timestamp == timestamp &&
      other.accelMagnitude == accelMagnitude;

  @override
  int get hashCode =>
      Object.hash(lat, lng, speed, altitude, accuracy, timestamp, accelMagnitude);
}

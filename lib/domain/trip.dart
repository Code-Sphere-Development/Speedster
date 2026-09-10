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
    this.cloudVehicleId,
    this.purpose,
    this.note,
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

  /// false = verworfen; bleibt aus Listen und Wertungen heraus.
  ///
  /// Es gibt keinen Weg mehr, das zu setzen: die Rueckfrage "selbst
  /// gefahren?" ist weg, wer aufzeichnet, faehrt selbst. Bestaende aus
  /// frueheren Fassungen tragen den Wert aber noch, und ihre Fahrten
  /// sollen verworfen bleiben.
  final bool kept;

  /// Stable client-generated id for idempotent cloud upload.
  final String clientUuid;

  /// When this trip was uploaded to the cloud; null = not yet synced.
  final DateTime? syncedAt;

  /// Das Fahrzeug in der Cloud, in dem diese Fahrt zurueckgelegt wurde.
  ///
  /// Beim Fahrtende festgehalten, nicht beim Hochladen bestimmt: wer
  /// zwischendurch das Standardfahrzeug wechselt, saehe seine wartenden
  /// Fahrten sonst am neuen Auto haengen.
  final int? cloudVehicleId;

  /// Zweck der Fahrt, wie ihn die Cloud fuehrt: `private`, `commute`
  /// oder `business`. `null` heisst "kein Zweck" -- ein gueltiger
  /// Zustand, kein fehlender Wert.
  final String? purpose;

  final String? note;

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
    int? cloudVehicleId,
    String? purpose,
    String? note,
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
      cloudVehicleId: cloudVehicleId ?? this.cloudVehicleId,
      purpose: purpose ?? this.purpose,
      note: note ?? this.note,
      kept: kept ?? this.kept,
      clientUuid: clientUuid ?? this.clientUuid,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}

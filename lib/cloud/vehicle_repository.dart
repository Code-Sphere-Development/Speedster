import 'package:dio/dio.dart';
import 'package:speedster/cloud/api_error.dart';

/// Ein Modell aus dem Fahrzeugkatalog der Cloud.
///
/// Die Kennung ist die der Cloud; die App fuehrt keinen eigenen Katalog.
/// Zehntausend Modelle auf dem Geraet zu halten waere Aufwand fuer eine
/// Liste, die man dreimal im Leben oeffnet.
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.label,
    this.vehicleClass,
    this.fuel,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] as int,
        label: json['label'] as String? ?? '',
        vehicleClass: json['vehicle_class'] as String?,
        fuel: json['fuel'] as String?,
      );

  final int id;
  final String label;
  final String? vehicleClass;
  final String? fuel;
}

/// Der geschaetzte Tachostand eines Fahrzeugs.
///
/// Geschaetzt, nicht gemessen: aufgezeichnet wird nur, was die App
/// mitbekommen hat. Ohne Telefon, ohne Empfang oder ohne Zuordnung
/// gefahrene Kilometer fehlen. Deshalb steht die Ablesung, auf der die
/// Zahl beruht, ueberall daneben.
class Odometer {
  const Odometer({
    this.estimateKm,
    this.trackedKm = 0,
    this.readingKm,
    this.readAt,
  });

  factory Odometer.fromJson(Map<String, dynamic> json) => Odometer(
        estimateKm: (json['estimate_km'] as num?)?.toInt(),
        trackedKm: (json['tracked_km'] as num?)?.toDouble() ?? 0,
        readingKm: (json['reading_km'] as num?)?.toInt(),
        readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      );

  /// `null` heisst: noch keine Ablesung. Aufgezeichnete Kilometer allein
  /// sind kein Tachostand.
  final int? estimateKm;
  final double trackedKm;
  final int? readingKm;
  final DateTime? readAt;
}

/// Eine faellige Wartung -- HU, Inspektion, Oelwechsel, Reifen.
class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.title,
    this.dueOn,
    this.dueKm,
    this.note,
    this.daysLeft,
    this.kilometersLeft,
  });

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) => MaintenanceItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        dueOn: DateTime.tryParse(json['due_on'] as String? ?? ''),
        dueKm: (json['due_km'] as num?)?.toInt(),
        note: json['note'] as String?,
        daysLeft: (json['days_left'] as num?)?.toInt(),
        kilometersLeft: (json['kilometers_left'] as num?)?.toInt(),
      );

  final int id;
  final String title;
  final DateTime? dueOn;
  final int? dueKm;
  final String? note;

  /// Negativ heisst ueberfaellig, `null` heisst "kein Termin gesetzt".
  final int? daysLeft;

  /// Gegen den geschaetzten Tachostand gerechnet. `null`, wenn keine
  /// Laufleistung gesetzt ist oder kein Stand vorliegt -- eine Zahl ohne
  /// Bezugsgroesse waere keine Auskunft.
  final int? kilometersLeft;

  bool get overdue =>
      (daysLeft != null && daysLeft! < 0) ||
      (kilometersLeft != null && kilometersLeft! < 0);
}

/// Ein Fahrzeug aus der Garage.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.isDefault,
    this.year,
    this.powerPs,
    this.model,
    this.odometer = const Odometer(),
    this.maintenance = const [],
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
        year: json['year'] as int?,
        powerPs: json['power_ps'] as int?,
        model: json['model'] == null
            ? null
            : VehicleModel.fromJson(json['model'] as Map<String, dynamic>),
        odometer: json['odometer'] == null
            ? const Odometer()
            : Odometer.fromJson(
                Map<String, dynamic>.from(json['odometer'] as Map)),
        maintenance: [
          for (final row in json['maintenance'] as List? ?? const [])
            MaintenanceItem.fromJson(Map<String, dynamic>.from(row as Map)),
        ],
      );

  final int id;
  final String name;
  final bool isDefault;
  final int? year;
  final int? powerPs;
  final VehicleModel? model;
  final Odometer odometer;
  final List<MaintenanceItem> maintenance;
}

/// Fehler mit der Meldung des Servers, sofern er eine geschickt hat.
class VehicleException implements Exception {
  const VehicleException(this.message);

  final String? message;

  @override
  String toString() => message ?? 'VehicleException';
}

class VehicleRepository {
  VehicleRepository(this.dio);

  final Dio dio;

  Future<List<Vehicle>> load() async {
    final res = await dio.get<Map<String, dynamic>>('/vehicles');
    final list = res.data?['vehicles'] as List? ?? const [];

    return [
      for (final row in list)
        Vehicle.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }

  /// Sucht im Katalog. Ohne Suchbegriff antwortet der Server mit einer
  /// leeren Liste -- eine Auswahl ohne Eingabe braucht keine.
  Future<List<VehicleModel>> searchModels(String term) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/vehicle-models',
      queryParameters: {'q': term},
    );
    final list = res.data?['models'] as List? ?? const [];

    return [
      for (final row in list)
        VehicleModel.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }

  Future<Vehicle> create({
    required String name,
    int? vehicleModelId,
    int? year,
    int? powerPs,
  }) async {
    try {
      final res = await dio.post<Map<String, dynamic>>('/vehicles', data: {
        'name': name,
        'vehicle_model_id': vehicleModelId,
        'year': year,
        'power_ps': powerPs,
      });

      return Vehicle.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw VehicleException(serverMessage(e));
    }
  }

  Future<Vehicle> update(
    int id, {
    required String name,
    int? vehicleModelId,
    int? year,
    int? powerPs,
  }) async {
    try {
      final res = await dio.patch<Map<String, dynamic>>('/vehicles/$id', data: {
        'name': name,
        'vehicle_model_id': vehicleModelId,
        'year': year,
        'power_ps': powerPs,
      });

      return Vehicle.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw VehicleException(serverMessage(e));
    }
  }

  /// Traegt einen abgelesenen Tachostand nach.
  ///
  /// Gibt zurueck, wie weit die Schaetzung danebenlag, oder `null`, wenn
  /// es die erste Ablesung war. Diese Zahl ist die eigentliche Auskunft:
  /// so viel hat die Aufzeichnung nicht mitbekommen.
  Future<int?> addReading(int id, int kilometers, DateTime readAt) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/vehicles/$id/odometer',
        data: {
          'kilometers': kilometers,
          'read_at': readAt.toUtc().toIso8601String(),
        },
      );

      return (res.data?['deviation_km'] as num?)?.toInt();
    } on DioException catch (e) {
      throw VehicleException(serverMessage(e));
    }
  }

  /// Legt eine Wartung an.
  ///
  /// [dueKm] ist der Zielstand ("bei 135 000 km"), [dueInKm] der Restweg
  /// ("in 5 000 km"). Der Server rechnet den Restweg gegen den
  /// geschaetzten Tachostand um -- hier waere dieselbe Rechnung ein
  /// zweites Mal und koennte auseinanderlaufen.
  Future<void> addMaintenance(
    int vehicleId, {
    required String title,
    DateTime? dueOn,
    int? dueKm,
    int? dueInKm,
  }) async {
    try {
      await dio.post('/vehicles/$vehicleId/maintenance', data: {
        'title': title,
        'due_on': dueOn?.toIso8601String().split('T').first,
        'due_km': dueKm,
        'due_in_km': dueInKm,
      });
    } on DioException catch (e) {
      throw VehicleException(serverMessage(e));
    }
  }

  /// Aendert eine Wartung.
  ///
  /// Fehlende Angaben leeren das jeweilige Feld: wer von "bei km" auf ein
  /// Datum wechselt, will die alte Kilometerangabe los sein.
  Future<void> updateMaintenance(
    int vehicleId,
    int itemId, {
    required String title,
    DateTime? dueOn,
    int? dueKm,
    int? dueInKm,
  }) async {
    try {
      await dio.patch('/vehicles/$vehicleId/maintenance/$itemId', data: {
        'title': title,
        'due_on': dueOn?.toIso8601String().split('T').first,
        'due_km': dueKm,
        'due_in_km': dueInKm,
      });
    } on DioException catch (e) {
      throw VehicleException(serverMessage(e));
    }
  }

  /// Hakt eine Wartung ab. Erledigt statt geloescht -- der naechste Termin
  /// ergibt sich meist aus dem letzten.
  Future<void> completeMaintenance(int vehicleId, int itemId) =>
      dio.post('/vehicles/$vehicleId/maintenance/$itemId/done');

  Future<void> makeDefault(int id) => dio.post('/vehicles/$id/default');

  Future<void> remove(int id) => dio.delete('/vehicles/$id');
}

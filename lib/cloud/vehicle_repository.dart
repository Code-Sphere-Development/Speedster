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

/// Ein Fahrzeug aus der Garage.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.isDefault,
    this.year,
    this.powerPs,
    this.model,
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
      );

  final int id;
  final String name;
  final bool isDefault;
  final int? year;
  final int? powerPs;
  final VehicleModel? model;
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

  Future<void> makeDefault(int id) => dio.post('/vehicles/$id/default');

  Future<void> remove(int id) => dio.delete('/vehicles/$id');
}

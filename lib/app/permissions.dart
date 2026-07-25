import 'package:geolocator/geolocator.dart';

/// Abstraction over location-permission acquisition so it can be faked.
abstract class PermissionGate {
  /// Returns true if location tracking is permitted after requesting.
  Future<bool> ensure();
}

class LocationPermissions implements PermissionGate {
  const LocationPermissions();

  @override
  Future<bool> ensure() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

class FakePermissionGate implements PermissionGate {
  FakePermissionGate({required this.granted});

  final bool granted;

  @override
  Future<bool> ensure() async => granted;
}

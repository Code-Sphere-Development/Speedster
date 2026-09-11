import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Wie weit die Ortung erlaubt ist.
///
/// Der Unterschied ist nicht akademisch: mit [whileInUse] liefert iOS
/// Positionen im Hintergrund nur weiter, solange die Sitzung im
/// Vordergrund begonnen hat. Beendet das System die App -- und das tut es
/// bei Speicherdruck --, zeichnet nichts mehr auf, und **niemand startet
/// sie wieder**. Erst [always] erlaubt es, die App bei einer deutlichen
/// Ortsaenderung neu zu starten.
enum LocationAccess {
  /// Keine Ortung. Es gibt nichts aufzuzeichnen.
  denied,

  /// Reicht, solange die App laeuft.
  whileInUse,

  /// Reicht auch, wenn iOS die App zwischendurch beendet hat.
  always;

  bool get canRecord => this != LocationAccess.denied;

  /// Ob die Aufzeichnung ein Beenden der App ueberlebt.
  bool get survivesTermination => this == LocationAccess.always;
}

/// Abstraction over location-permission acquisition so it can be faked.
abstract class PermissionGate {
  /// Holt die Grundberechtigung ein und meldet, wie weit sie reicht.
  ///
  /// Kann einen Systemdialog zeigen.
  Future<LocationAccess> ensure();

  /// Der Stand, ohne zu fragen.
  ///
  /// Fuer Anzeigen: `ensure` duerfte dafuer nicht verwendet werden, sonst
  /// erschiene beim blossen Aufrufen der Einstellungen ein Dialog.
  Future<LocationAccess> current();

  /// Fragt ausdruecklich "Immer" an.
  ///
  /// Getrennt von [ensure], weil iOS den Dialog dafuer **nur einmal**
  /// zeigt und erst, wenn "Beim Verwenden" bereits erteilt ist. Danach
  /// fuehrt der Weg ausschliesslich ueber die Systemeinstellungen.
  Future<LocationAccess> requestAlways();

  /// Oeffnet die Systemeinstellungen der App.
  Future<void> openSettings();
}

class LocationPermissions implements PermissionGate {
  const LocationPermissions();

  @override
  Future<LocationAccess> ensure() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.denied;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _map(permission);
  }

  /// Ueber permission_handler und nicht ueber geolocator.
  ///
  /// geolocator fragt auf iOS ausschliesslich `requestWhenInUseAuthorization`,
  /// sobald `NSLocationWhenInUseUsageDescription` in der Info.plist steht
  /// -- der `requestAlwaysAuthorization`-Zweig ist dort ein `else` und
  /// damit unerreichbar. Genau deshalb hat diese App "Immer" nie bekommen.
  /// permission_handler ruft es direkt auf.
  @override
  Future<LocationAccess> current() async =>
      await Geolocator.isLocationServiceEnabled()
          ? _map(await Geolocator.checkPermission())
          : LocationAccess.denied;

  @override
  Future<LocationAccess> requestAlways() async {
    final status = await ph.Permission.locationAlways.request();
    if (status.isGranted) return LocationAccess.always;

    // Abgelehnt heisst nicht zwangslaeufig "gar nichts": "Beim Verwenden"
    // kann weiterhin stehen.
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<void> openSettings() => ph.openAppSettings();

  static LocationAccess _map(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always => LocationAccess.always,
        LocationPermission.whileInUse => LocationAccess.whileInUse,
        _ => LocationAccess.denied,
      };
}

class FakePermissionGate implements PermissionGate {
  FakePermissionGate({bool granted = true, LocationAccess? access})
      : access = access ??
            (granted ? LocationAccess.always : LocationAccess.denied);

  LocationAccess access;

  int alwaysRequests = 0;
  int settingsOpened = 0;

  @override
  Future<LocationAccess> ensure() async => access;

  @override
  Future<LocationAccess> current() async => access;

  @override
  Future<LocationAccess> requestAlways() async {
    alwaysRequests++;
    return access;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

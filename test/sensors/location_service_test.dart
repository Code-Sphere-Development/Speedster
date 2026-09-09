import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/sensors/location_service.dart';

void main() {
  test('FakeSampleSource replays samples in order', () async {
    final samples = [
      Sample(
        lat: 50,
        lng: 6,
        speed: 0,
        altitude: 100,
        accuracy: 3,
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
      ),
      Sample(
        lat: 50,
        lng: 6,
        speed: 10,
        altitude: 100,
        accuracy: 3,
        timestamp: DateTime(2026, 1, 1, 12, 0, 1),
      ),
    ];
    final src = FakeSampleSource(samples);
    expect(await src.samples().toList(), samples);
  });

  _platformSettings();
}

void _platformSettings() {
  group('Standort-Einstellungen je Plattform', () {
    test('iOS erlaubt Updates im Hintergrund', () {
      // Ohne dieses Flag stellt iOS die Lieferung ein, sobald das Display
      // sperrt -- UIBackgroundModes in der Info.plist allein genuegt nicht.
      final s = GeolocatorSampleSource.settingsFor(SamplePlatform.ios);

      expect(s, isA<AppleSettings>());
      final apple = s as AppleSettings;
      expect(apple.allowBackgroundLocationUpdates, isTrue);
      expect(apple.showBackgroundLocationIndicator, isTrue);
      // iOS pausiert sonst bei laengerem Stillstand und nimmt nicht
      // zuverlaessig von selbst wieder auf.
      expect(apple.pauseLocationUpdatesAutomatically, isFalse);
      expect(apple.activityType, ActivityType.automotiveNavigation);
    });

    test('Android laeuft als Vordergrunddienst', () {
      // Ohne Notification beendet Android die Standortlieferung im
      // Hintergrund, obwohl das Manifest die Rechte deklariert.
      final s = GeolocatorSampleSource.settingsFor(SamplePlatform.android);

      expect(s, isA<AndroidSettings>());
      final android = s as AndroidSettings;
      expect(android.foregroundNotificationConfig, isNotNull);
      expect(android.foregroundNotificationConfig!.notificationTitle, isNotEmpty);
    });

    test('laeuft im Stand grob und mit Mindestabstand', () {
      // Sonst laeuft der GPS-Empfaenger durch, waehrend das Telefon auf
      // dem Sofa liegt.
      for (final platform in SamplePlatform.values) {
        final idle = GeolocatorSampleSource.settingsFor(
          platform,
          precise: false,
        );

        expect(idle.accuracy, LocationAccuracy.low,
            reason: 'zu fein im Stand bei $platform');
        expect(idle.distanceFilter, greaterThan(0),
            reason: 'kein Mindestabstand bei $platform');
      }
    });

    test('laeuft waehrend der Fahrt in voller Aufloesung', () {
      for (final platform in SamplePlatform.values) {
        final driving = GeolocatorSampleSource.settingsFor(platform);

        expect(driving.accuracy, LocationAccuracy.best,
            reason: 'zu grob waehrend der Fahrt bei $platform');
        // Jeder Fix zaehlt: ein Mindestabstand liesse Kurven ausfallen.
        expect(driving.distanceFilter, 0,
            reason: 'Mindestabstand waehrend der Fahrt bei $platform');
      }
    });

    test('behaelt die Hintergrund-Optionen in beiden Staerken', () {
      // Ohne sie stellt iOS die Lieferung beim Sperren des Displays ein --
      // unabhaengig davon, wie fein geortet wird.
      for (final precise in [true, false]) {
        final settings = GeolocatorSampleSource.settingsFor(
          SamplePlatform.ios,
          precise: precise,
        ) as AppleSettings;

        expect(settings.allowBackgroundLocationUpdates, isTrue);
        expect(settings.pauseLocationUpdatesAutomatically, isFalse);
      }
    });

  });
}

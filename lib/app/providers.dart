import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/notifications/local_notifications.dart';
import 'package:speedster/notifications/maintenance_reminder.dart';
import 'package:speedster/notifications/trip_notifier.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/recording/trip_repair.dart';
import 'package:speedster/app/car_connection.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/sensors/location_wake.dart';
import 'package:speedster/app/tracking_armer.dart';
import 'package:speedster/cloud/api_client.dart';
import 'package:speedster/cloud/account_repository.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/friend_repository.dart';
import 'package:speedster/cloud/cloud_sync_service.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/cloud/trip_cache_service.dart';
import 'package:speedster/cloud/trip_source.dart';
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/data/backup_service.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/distance_totals.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/cloud_heat_source.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_snapshot_store.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/heat/local_heat_source.dart';
import 'package:speedster/heat/usual_speed.dart';
import 'package:speedster/live/live_activity.dart';
import 'package:speedster/recording/demo_ride.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/sensors/last_known_location.dart';
import 'package:speedster/widgets/widget_publisher.dart';
import 'package:speedster/widgets/widget_store.dart';
import 'package:speedster/sensors/location_service.dart';

/// Opened in main() and injected via override.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider not overridden'),
);

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => DriftTripRepository(ref.watch(databaseProvider)),
);

final permissionGateProvider = Provider<PermissionGate>(
  (ref) => const LocationPermissions(),
);

final carConnectionProvider = Provider<CarConnection>(
  (ref) => const PlatformCarConnection(),
);

/// Zusaetzliches Signal fuer "der Nutzer sitzt im Auto".
final carConnectedProvider = StreamProvider<bool>(
  (ref) => ref.watch(carConnectionProvider).connected,
);

final lastKnownLocationProvider = Provider<LastKnownLocation>(
  (ref) => const GeolocatorLastKnownLocation(),
);

/// Startpunkt der Karte, solange keine Strecken vorliegen.
final mapFallbackCenterProvider =
    FutureProvider<({double lat, double lng})?>(
  (ref) => ref.watch(lastKnownLocationProvider).get(),
);

final sampleSourceProvider = Provider<SampleSource>(
  (ref) => GeolocatorSampleSource(),
);

final tripDetectorProvider = Provider<TripDetector>(
  (ref) => TripDetector(const DetectorConfig()),
);

/// Die gemeinsame Verdrahtung aller Mitteilungen -- eine Einrichtung,
/// eine Berechtigungsabfrage, ein Ort fuer die Sprache.
final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => LocalNotifications(),
);

/// Meldet den Fahrtbeginn. Ob gemeldet wird, liest der Melder bei jedem
/// Fahrtbeginn frisch aus den Einstellungen -- ueber ref.read und nicht
/// ref.watch, damit ein umgelegter Schalter nicht den Rekorder samt
/// laufender Fahrt neu erzeugt.
final tripNotifierProvider = Provider<TripNotifier>(
  (ref) => LocalTripNotifier(
    enabled: () => ref.read(settingsControllerProvider).notifyOnTripStart,
    notifications: ref.watch(localNotificationsProvider),
  ),
);

/// Laesst iOS die App bei deutlichen Ortsaenderungen wieder starten.
final locationWakeProvider = Provider<LocationWake>(
  (ref) => const PlatformLocationWake(),
);

/// Macht Aufzeichnung und Ortsueberwachung scharf.
final trackingArmerProvider = Provider<TrackingArmer>(TrackingArmer.new);

/// Der Berechtigungsstand, ohne zu fragen -- fuer die Anzeige in den
/// Einstellungen.
final locationAccessProvider = FutureProvider<LocationAccess>(
  (ref) => ref.watch(permissionGateProvider).current(),
);

/// Erinnert an faellige Wartungen -- beim Start und nach dem Fahrtende.
final maintenanceReminderProvider = Provider<MaintenanceReminder>(
  (ref) => MaintenanceReminder(
    notifications: ref.watch(localNotificationsProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    enabled: () => ref.read(settingsControllerProvider).notifyMaintenance,
  ),
);

final recorderProvider = Provider<TripRecorder>(
  (ref) => TripRecorder(
    source: ref.watch(sampleSourceProvider),
    detector: ref.watch(tripDetectorProvider),
    repo: ref.watch(tripRepositoryProvider),
    // Der Detektor beendet keine Fahrt, solange das Auto verbunden ist:
    // Ampel und Stau sind kein Fahrtende (siehe TripDetector.carConnected).
    carConnected: ref.watch(carConnectionProvider).connected,
    liveActivity: ref.watch(liveActivityProvider),
    notifier: ref.watch(tripNotifierProvider),
    locationWake: ref.watch(locationWakeProvider),
    usualSpeed: UsualSpeedReader(ref.watch(databaseProvider)),
    // Erst am Fahrtende abgefragt, nicht beim Erzeugen: die Garage kann
    // sich waehrend der Fahrt aendern. Faellt die Abfrage aus -- kein
    // Netz, keine Cloud --, bleibt die Fahrt ohne Fahrzeug, statt die
    // Aufzeichnung scheitern zu lassen.
    defaultVehicleId: () async {
      try {
        return (await ref.read(defaultVehicleProvider.future))?.id;
      } on Exception {
        return null;
      }
    },
  ),
);

/// Die erfundene Fahrt fuer die Vorschau.
final demoRideProvider = StreamProvider<RecorderState>(
  (ref) => DemoRide.stream(),
);

/// Was die Live-Ansicht zeigt -- und woran die Reiterleiste ablesen kann,
/// ob "Live" ueberhaupt erscheint.
///
/// Ist die Vorschau eingeschaltet, kommt der Zustand von [demoRideProvider].
/// Der Rekorder bleibt davon unberuehrt: es wird nichts aufgezeichnet.
final liveStateProvider = Provider<AsyncValue<RecorderState>>((ref) {
  if (ref.watch(settingsControllerProvider).demoRide) {
    return ref.watch(demoRideProvider);
  }

  return ref.watch(recorderStateProvider);
});

final recorderStateProvider = StreamProvider<RecorderState>(
  (ref) => ref.watch(recorderProvider).state,
);

final liveActivityProvider = Provider<LiveActivity>(
  (ref) => const PlatformLiveActivity(),
);

final widgetStoreProvider = Provider<WidgetStore>(
  (ref) => const PlatformWidgetStore(),
);

final widgetPublisherProvider = Provider<WidgetPublisher>(
  (ref) => WidgetPublisher(
    store: ref.watch(widgetStoreProvider),
    trips: ref.watch(tripRepositoryProvider),
    heat: ref.watch(heatSourceProvider),
    ranking: ref.watch(rankingRepositoryProvider),
  ),
);

final heatFolderProvider = Provider<HeatFolder>(
  (ref) => HeatFolder(ref.watch(databaseProvider)),
);

/// Cloud, wenn eingeloggt — sonst und bei Netzfehlern lokal.
final tripSourceProvider = Provider<TripSource>(
  (ref) => FallbackTripSource(
    CloudTripSource(ref.watch(apiClientProvider).dio),
    LocalTripSource(ref.watch(tripRepositoryProvider)),
    ref.watch(tokenStoreProvider),
    ref.watch(tripRepositoryProvider),
  ),
);

/// Rechnet abgebrochene Fahrten nach (siehe TripRepair).
final tripRepairProvider = Provider<TripRepair>(
  (ref) => TripRepair(ref.watch(tripRepositoryProvider)),
);

final keptTripsProvider = FutureProvider<List<Trip>>(
  (ref) => ref.watch(tripSourceProvider).keptTrips(),
);

/// Die Uhr.
///
/// Als Provider, damit Statistik und Kopfzahlen im Test und auf den
/// Screenshots gegen ein festes Datum rechnen koennen -- sonst haengt das
/// Ergebnis daran, in welchem Monat der Lauf stattfindet.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Monats- und Jahressumme fuer den Kopfbereich.
///
/// Aus der Fahrtenliste gerechnet und nicht vom Server geholt:
/// CloudTripSource blaettert ohnehin alle Seiten durch, die Liste ist
/// also vollstaendig -- ein eigener Endpunkt waere eine zweite Wahrheit
/// fuer dieselbe Zahl.
final distanceTotalsProvider = Provider<DistanceTotals>((ref) {
  final trips = ref.watch(keptTripsProvider).asData?.value;
  if (trips == null) return DistanceTotals.empty;

  return DistanceTotals.of(trips, ref.watch(nowProvider)());
});

final heatSnapshotStoreProvider = Provider<HeatSnapshotStore>(
  (ref) => HeatSnapshotStore(ref.watch(databaseProvider)),
);

/// Cloud, wenn eingeloggt — sonst und bei Netzfehlern lokal.
final heatSourceProvider = Provider<HeatSource>(
  (ref) => FallbackHeatSource(
    CloudHeatSource(ref.watch(apiClientProvider).dio),
    LocalHeatSource(
      ref.watch(databaseProvider),
      ref.watch(heatFolderProvider),
    ),
    ref.watch(tokenStoreProvider),
    ref.watch(heatSnapshotStoreProvider),
  ),
);

final heatMapProvider = FutureProvider.family<HeatMap, HeatQuery>(
  (ref, query) => ref.watch(heatSourceProvider).load(query),
);

/// Steuert, ob die Zeitraum-Filter angeboten werden.
final cloudActiveProvider = FutureProvider<bool>(
  (ref) async => await ref.watch(tokenStoreProvider).read() != null,
);

// --- Cloud (Phase 2) ---

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    dio: ref.watch(apiClientProvider).dio,
    tokenStore: ref.watch(tokenStoreProvider),
  ),
);

final cloudSyncServiceProvider = Provider<CloudSyncService>(
  (ref) => CloudSyncService(
    dio: ref.watch(apiClientProvider).dio,
    repo: ref.watch(tripRepositoryProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  ),
);

final tripCacheServiceProvider = Provider<TripCache>(
  (ref) => TripCacheService(
    dio: ref.watch(apiClientProvider).dio,
    repo: ref.watch(tripRepositoryProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  ),
);

final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => FriendRepository(ref.watch(apiClientProvider).dio),
);

final friendOverviewProvider = FutureProvider<FriendOverview>(
  (ref) => ref.watch(friendRepositoryProvider).load(),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider).dio),
);

/// Das eigene Cloud-Konto. Traegt den Benutzernamen, den die App anzeigt
/// und aus dem der Einladungslink entsteht.
final cloudAccountProvider = FutureProvider<CloudAccount?>((ref) async {
  if (await ref.watch(tokenStoreProvider).read() == null) return null;
  try {
    return await ref.watch(accountRepositoryProvider).me();
  } on Exception {
    // Ohne Netz bleibt der Bereich leer statt in einen Fehler zu kippen;
    // die Einstellungen muessen auch offline bedienbar sein.
    return null;
  }
});

/// Sicherung der Fahrten in eine Datei.
///
/// Der Dokumentenordner der App: er ist ueber die Dateien-App erreichbar,
/// sodass sich die Sicherung von dort wegkopieren laesst.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    Directory(ref.watch(documentsPathProvider)),
  );
});

/// Pfad des Dokumentenordners. Eigener Provider, damit ein Test ihn
/// ersetzen kann, ohne den Plattformkanal von path_provider zu brauchen.
final documentsPathProvider = Provider<String>((ref) {
  throw UnimplementedError('documentsPathProvider muss gesetzt werden');
});

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(ref.watch(apiClientProvider).dio),
);

/// Die Garage. Leer ohne Cloud -- die Fahrzeuge werden dort gefuehrt.
final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  if (!await ref.watch(cloudActiveProvider.future)) return const [];

  return ref.watch(vehicleRepositoryProvider).load();
});

/// Das Fahrzeug, dem neue Fahrten zufallen.
///
/// Faellt auf das erste zurueck, damit ein Konto mit genau einem Fahrzeug
/// es nicht erst zum Standard erklaeren muss -- dieselbe Regel wie in der
/// Cloud.
final defaultVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  final vehicles = await ref.watch(vehiclesProvider.future);
  if (vehicles.isEmpty) return null;

  return vehicles.firstWhere(
    (v) => v.isDefault,
    orElse: () => vehicles.first,
  );
});

/// Wie viele Fahrten auf den Upload warten.
///
/// Ohne Cloud immer null: dann wartet nichts, die Fahrten liegen dort, wo
/// sie hingehoeren.
final pendingUploadsProvider = FutureProvider<int>((ref) async {
  // Der Token entscheidet, nicht ein Schalter in den Einstellungen: die
  // beiden liefen auseinander, sobald der Schluesselbund eine
  // Neuinstallation ueberlebte und die Einstellungen nicht.
  if (!await ref.watch(cloudActiveProvider.future)) return 0;

  return ref.watch(cloudSyncServiceProvider).pendingCount();
});

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(apiClientProvider).dio),
);

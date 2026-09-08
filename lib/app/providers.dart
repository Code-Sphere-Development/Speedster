import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/car_connection.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/cloud/api_client.dart';
import 'package:speedster/cloud/account_repository.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/friend_repository.dart';
import 'package:speedster/cloud/cloud_sync_service.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/cloud/trip_cache_service.dart';
import 'package:speedster/cloud/trip_source.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/cloud_heat_source.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_snapshot_store.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/heat/local_heat_source.dart';
import 'package:speedster/heat/usual_speed.dart';
import 'package:speedster/live/live_activity.dart';
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

final recorderProvider = Provider<TripRecorder>(
  (ref) => TripRecorder(
    source: ref.watch(sampleSourceProvider),
    detector: ref.watch(tripDetectorProvider),
    repo: ref.watch(tripRepositoryProvider),
    // Der Detektor beendet keine Fahrt, solange das Auto verbunden ist:
    // Ampel und Stau sind kein Fahrtende (siehe TripDetector.carConnected).
    carConnected: ref.watch(carConnectionProvider).connected,
    liveActivity: ref.watch(liveActivityProvider),
    usualSpeed: UsualSpeedReader(ref.watch(databaseProvider)),
  ),
);

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

final keptTripsProvider = FutureProvider<List<Trip>>(
  (ref) => ref.watch(tripSourceProvider).keptTrips(),
);

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

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(apiClientProvider).dio),
);

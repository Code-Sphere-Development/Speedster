import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/car_connection.dart';
import 'package:speedster/app/permissions.dart';
import 'package:speedster/cloud/api_client.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/cloud_sync_service.dart';
import 'package:speedster/cloud/ranking_repository.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/detection/trip_detector.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/heat/cloud_heat_source.dart';
import 'package:speedster/heat/heat_folder.dart';
import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_source.dart';
import 'package:speedster/heat/local_heat_source.dart';
import 'package:speedster/recording/trip_recorder.dart';
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
  ),
);

final recorderStateProvider = StreamProvider<RecorderState>(
  (ref) => ref.watch(recorderProvider).state,
);

final heatFolderProvider = Provider<HeatFolder>(
  (ref) => HeatFolder(ref.watch(databaseProvider)),
);

final keptTripsProvider = FutureProvider<List<Trip>>(
  (ref) => ref.watch(tripRepositoryProvider).keptTrips(),
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

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(apiClientProvider).dio),
);

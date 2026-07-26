import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final keptTripsProvider = FutureProvider<List<Trip>>(
  (ref) => ref.watch(tripRepositoryProvider).keptTrips(),
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

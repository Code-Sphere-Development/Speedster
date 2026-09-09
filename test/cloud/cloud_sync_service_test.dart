import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/cloud/cloud_sync_service.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';

class MockDio extends Mock implements Dio {}

Trip keptTrip() => Trip(
      startTime: DateTime(2026),
      endTime: DateTime(2026, 1, 1, 12),
      maxSpeed: 30,
      avgSpeed: 12,
      distance: 15400,
      elevationGain: 120,
      durationSeconds: 1800,
      zeroToHundredSeconds: 8.2,
      kept: true,
    );

Response ok(int code) => Response(
      requestOptions: RequestOptions(path: '/trips'),
      statusCode: code,
      data: {'client_uuid': 'x'},
    );

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;
  late MockDio dio;
  late InMemoryTokenStore store;
  late CloudSyncService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
    dio = MockDio();
    store = InMemoryTokenStore();
    await store.write('token');
    service = CloudSyncService(dio: dio, repo: repo, tokenStore: store);
  });
  tearDown(() => db.close());

  test('uploads all unsynced trips and marks them synced', () async {
    await repo.createTrip(keptTrip());
    await repo.createTrip(keptTrip());
    when(() => dio.post('/trips', data: any(named: 'data')))
        .thenAnswer((_) async => ok(201));

    await service.syncOnce();

    expect(await repo.unsyncedTrips(), isEmpty);
    verify(() => dio.post('/trips', data: any(named: 'data'))).called(2);
  });

  test('401 stops sync and clears token', () async {
    await repo.createTrip(keptTrip());
    when(() => dio.post('/trips', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/trips'),
        response: Response(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 401,
        ),
      ),
    );

    await service.syncOnce();

    expect(await store.read(), isNull);
    expect(await repo.unsyncedTrips(), hasLength(1));
  });

  test('server error leaves trip unsynced', () async {
    await repo.createTrip(keptTrip());
    when(() => dio.post('/trips', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/trips'),
        response: Response(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 500,
        ),
      ),
    );

    await service.syncOnce();

    expect(await repo.unsyncedTrips(), hasLength(1));
    expect(await store.read(), 'token'); // token kept
  });

  test('haelt bei einer zurueckgewiesenen Fahrt nicht die ganze Reihe auf',
      () async {
    // Genau das ist passiert: eine Fahrt, die der Server nicht annahm,
    // stand vorn in der Warteschlange und hielt alle spaeteren dauerhaft
    // und lautlos auf. In der Bestenliste stand weiter ein alter Wert.
    final erste = await repo.createTrip(keptTrip());
    await repo.createTrip(keptTrip());

    var call = 0;
    when(() => dio.post('/trips', data: any(named: 'data'))).thenAnswer((_) {
      call++;
      if (call == 1) {
        throw DioException(
          requestOptions: RequestOptions(path: '/trips'),
          response: Response(
            requestOptions: RequestOptions(path: '/trips'),
            statusCode: 422,
          ),
        );
      }

      return Future.value(ok(201));
    });

    await service.syncOnce();

    // Die zweite ist oben, die erste liegt weiterhin -- aber sie blockiert
    // nicht mehr.
    final offen = await repo.unsyncedTrips();
    expect(offen, hasLength(1));
    expect(offen.single.id, erste);
    expect(service.rejected, hasLength(1));
  });

  test('haelt bei einem Netzfehler an und behaelt die Reihenfolge', () async {
    // Anders als bei einer Zurueckweisung hilft hier ein spaeterer
    // Versuch -- und die Fahrten sollen in ihrer Reihenfolge ankommen.
    await repo.createTrip(keptTrip());
    await repo.createTrip(keptTrip());

    when(() => dio.post('/trips', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/trips'),
        type: DioExceptionType.connectionError,
      ),
    );

    await service.syncOnce();

    expect(await repo.unsyncedTrips(), hasLength(2));
    verify(() => dio.post('/trips', data: any(named: 'data'))).called(1);
  });
}

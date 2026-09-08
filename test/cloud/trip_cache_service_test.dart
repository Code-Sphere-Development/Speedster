import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/cloud/trip_cache_service.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/trip.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> summary(String uuid, DateTime start) => {
      'client_uuid': uuid,
      'start_time': start.toUtc().toIso8601String(),
      'end_time': start.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
      'max_speed': 30.0,
      'avg_speed': 12.0,
      'distance': 15400.0,
      'elevation_gain': 120.0,
      'duration_seconds': 1800,
      'zero_to_hundred_seconds': 8.2,
    };

Response<Map<String, dynamic>> page(
  List<Map<String, dynamic>> rows, {
  String? next,
}) =>
    Response(
      requestOptions: RequestOptions(path: '/trips'),
      statusCode: 200,
      data: {'data': rows, 'next_page_url': next},
    );

Response<Map<String, dynamic>> detail(
  String uuid,
  DateTime start, {
  int points = 3,
}) =>
    Response(
      requestOptions: RequestOptions(path: '/trips/$uuid'),
      statusCode: 200,
      data: {
        ...summary(uuid, start),
        'points': [
          for (var i = 0; i < points; i++)
            {
              'lat': 50.0 + i * 0.001,
              'lng': 7.0 + i * 0.001,
              'speed': 12.0,
              'altitude': 50.0,
              'accuracy': 5.0,
              't': start.add(Duration(seconds: i)).toUtc().toIso8601String(),
            },
        ],
      },
    );

Trip localTrip(DateTime start, {DateTime? syncedAt, String uuid = ''}) => Trip(
      startTime: start,
      endTime: start.add(const Duration(minutes: 20)),
      maxSpeed: 25,
      avgSpeed: 10,
      distance: 8000,
      elevationGain: 40,
      durationSeconds: 1200,
      zeroToHundredSeconds: null,
      kept: true,
      clientUuid: uuid,
      syncedAt: syncedAt,
    );

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;
  late MockDio dio;
  late InMemoryTokenStore store;
  late TripCacheService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
    dio = MockDio();
    store = InMemoryTokenStore();
    await store.write('token');
    service = TripCacheService(dio: dio, repo: repo, tokenStore: store);
  });
  tearDown(() => db.close());

  void stubList(List<Map<String, dynamic>> rows) {
    when(() => dio.get<Map<String, dynamic>>(
          '/trips',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => page(rows));
  }

  test('holt hoechstens die neuesten zehn Fahrten', () async {
    final rows = [
      for (var i = 0; i < 15; i++)
        summary('uuid-$i', DateTime(2026, 1, 20).subtract(Duration(days: i))),
    ];
    stubList(rows);
    for (var i = 0; i < 15; i++) {
      when(() => dio.get<Map<String, dynamic>>('/trips/uuid-$i')).thenAnswer(
        (_) async =>
            detail('uuid-$i', DateTime(2026, 1, 20).subtract(Duration(days: i))),
      );
    }

    final result = await service.refresh();

    expect(result.cached, TripCacheService.keepTrips);
    expect(result.complete, isTrue);
    expect((await repo.keptTrips()).length, TripCacheService.keepTrips);
  });

  test('ueberspringt Fahrten, die schon lokal liegen', () async {
    await repo.createTrip(localTrip(DateTime(2026, 1, 20), uuid: 'uuid-0'));
    stubList([summary('uuid-0', DateTime(2026, 1, 20))]);

    final result = await service.refresh();

    expect(result.cached, 0);
    verifyNever(() => dio.get<Map<String, dynamic>>('/trips/uuid-0'));
  });

  test('schreibt die Punkte mit und rechnet die Zeit in die Ortszeit um',
      () async {
    final start = DateTime.utc(2026, 1, 20, 17, 30);
    stubList([summary('uuid-0', start)]);
    when(() => dio.get<Map<String, dynamic>>('/trips/uuid-0'))
        .thenAnswer((_) async => detail('uuid-0', start));

    await service.refresh();

    final trips = await repo.keptTrips();
    expect(trips, hasLength(1));
    expect(await repo.pointsFor(trips.single.id!), hasLength(3));
    expect(
      trips.single.startTime,
      start.toLocal(),
      reason: 'UTC unveraendert zu uebernehmen verschoebe die Anzeigezeit',
    );
  });

  test('markiert zwischengespeicherte Fahrten als synchronisiert', () async {
    stubList([summary('uuid-0', DateTime(2026, 1, 20))]);
    when(() => dio.get<Map<String, dynamic>>('/trips/uuid-0')).thenAnswer(
      (_) async => detail('uuid-0', DateTime(2026, 1, 20)),
    );

    await service.refresh();

    expect(
      await repo.unsyncedTrips(),
      isEmpty,
      reason: 'sonst laedt der naechste Upload-Lauf sie sofort wieder hoch',
    );
  });

  test('verwirft aeltere bestaetigte Fahrten, behaelt die zehn neuesten',
      () async {
    for (var i = 0; i < 14; i++) {
      await repo.createTrip(
        localTrip(
          DateTime(2026, 1, 20).subtract(Duration(days: i)),
          uuid: 'alt-$i',
          syncedAt: DateTime(2026, 1, 21),
        ),
      );
    }
    stubList(const []);

    final result = await service.refresh();

    expect(result.evicted, 4);
    expect((await repo.keptTrips()).length, TripCacheService.keepTrips);
  });

  test('verwirft nie eine noch nicht hochgeladene Fahrt', () async {
    for (var i = 0; i < 14; i++) {
      await repo.createTrip(
        localTrip(
          DateTime(2026, 1, 20).subtract(Duration(days: i)),
          uuid: 'alt-$i',
          // Die aeltesten vier sind genau die, die sonst wegfielen.
          syncedAt: i < 10 ? DateTime(2026, 1, 21) : null,
        ),
      );
    }
    stubList(const []);

    final result = await service.refresh();

    expect(result.evicted, 0);
    expect((await repo.keptTrips()).length, 14);
  });

  test('bricht ohne Netz ab, ohne zu raeumen', () async {
    await repo.createTrip(
      localTrip(DateTime(2026), uuid: 'alt', syncedAt: DateTime(2026, 1, 2)),
    );
    for (var i = 0; i < 12; i++) {
      await repo.createTrip(
        localTrip(DateTime(2026, 2, 1).add(Duration(days: i)),
            uuid: 'neu-$i', syncedAt: DateTime(2026, 3)),
      );
    }
    when(() => dio.get<Map<String, dynamic>>(
          '/trips',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/trips')),
    );

    final result = await service.refresh();

    expect(result.complete, isFalse);
    expect(result.evicted, 0);
    expect((await repo.keptTrips()).length, 13);
  });

  test('401 loescht den Token und raeumt nicht', () async {
    when(() => dio.get<Map<String, dynamic>>(
          '/trips',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/trips'),
        response: Response(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 401,
        ),
      ),
    );

    final result = await service.refresh();

    expect(await store.read(), isNull);
    expect(result.complete, isFalse);
  });

  test('ohne Token passiert nichts', () async {
    await store.clear();
    await repo.createTrip(
      localTrip(DateTime(2026), uuid: 'alt', syncedAt: DateTime(2026, 1, 2)),
    );

    final result = await service.refresh();

    expect(result, same(CacheResult.skipped));
    expect((await repo.keptTrips()).length, 1);
    verifyNever(() => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ));
  });
}

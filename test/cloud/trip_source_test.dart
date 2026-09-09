import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/cloud/token_store.dart';
import 'package:speedster/cloud/trip_source.dart';
import 'package:speedster/data/database.dart' show AppDatabase;
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> row(String uuid, DateTime start) => {
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

Trip local(DateTime start, {String uuid = ''}) => Trip(
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
    );

TrackPoint point(int tripId, int i) => TrackPoint(
      tripId: tripId,
      lat: 50.0 + i * 0.001,
      lng: 7.0,
      speed: 10,
      altitude: 50,
      accuracy: 5,
      timestamp: DateTime(2026, 1, 1, 0, 0, i),
    );

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;
  late MockDio dio;
  late InMemoryTokenStore store;
  late FallbackTripSource source;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
    dio = MockDio();
    store = InMemoryTokenStore();
    await store.write('token');
    source = FallbackTripSource(
      CloudTripSource(dio),
      LocalTripSource(repo),
      store,
      repo,
    );
  });
  tearDown(() => db.close());

  void stubPages(List<Response<Map<String, dynamic>>> pages) {
    var call = 0;
    when(() => dio.get<Map<String, dynamic>>(
          '/trips',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => pages[call++]);
  }

  test('ohne Token kommt die Liste lokal', () async {
    await store.clear();
    await repo.createTrip(local(DateTime(2026), uuid: 'a'));

    expect(await source.keptTrips(), hasLength(1));
    verifyNever(() => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ));
  });

  test('mit Token fuehrt die Cloud die Liste', () async {
    // Der lokale Vorrat ist nur ein Zwischenspeicher: eine bereits
    // hochgeladene Fahrt zaehlt einmal, naemlich die der Cloud -- sonst
    // stuende sie doppelt, sobald sie in beiden liegt.
    await repo.createTrip(local(DateTime(2020), uuid: 'schon-oben'));
    await repo.markSynced('schon-oben');
    stubPages([page([row('a', DateTime(2026, 1, 5))])]);

    final trips = await source.keptTrips();

    expect(trips, hasLength(1));
    expect(trips.single.clientUuid, 'a');
  });

  test('laeuft ueber alle Seiten', () async {
    stubPages([
      page([row('a', DateTime(2026, 1, 5))], next: '/trips?page=2'),
      page([row('b', DateTime(2026, 1, 4))]),
    ]);

    expect(await source.keptTrips(), hasLength(2));
  });

  test('traegt die lokale Id nach, wo die Fahrt im Vorrat liegt', () async {
    await repo.createTrip(local(DateTime(2026, 1, 5), uuid: 'a'));
    stubPages([
      page([row('a', DateTime(2026, 1, 5)), row('b', DateTime(2026, 1, 4))]),
    ]);

    final trips = await source.keptTrips();

    expect(trips.firstWhere((t) => t.clientUuid == 'a').id, isNotNull);
    expect(trips.firstWhere((t) => t.clientUuid == 'b').id, isNull);
  });

  test('faellt bei Netzfehler auf die lokale Liste zurueck', () async {
    await repo.createTrip(local(DateTime(2026), uuid: 'a'));
    when(() => dio.get<Map<String, dynamic>>(
          '/trips',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(requestOptions: RequestOptions(path: '/trips')));

    expect(await source.keptTrips(), hasLength(1));
    expect(await store.read(), 'token', reason: 'nur 401 loescht den Token');
  });

  test('401 loescht den Token und faellt lokal zurueck', () async {
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

    expect(await source.keptTrips(), isEmpty);
    expect(await store.read(), isNull);
  });

  test('Punkte einer zwischengespeicherten Fahrt kommen ohne Netz', () async {
    final id = await repo.createTrip(local(DateTime(2026), uuid: 'a'));
    await repo.addPoints(id, [point(id, 0), point(id, 1)]);

    final points = await source.pointsFor(clientUuid: 'a', localId: id);

    expect(points, hasLength(2));
    verifyNever(() => dio.get<Map<String, dynamic>>(any()));
  });

  test('Punkte einer nicht zwischengespeicherten Fahrt kommen aus der Cloud',
      () async {
    when(() => dio.get<Map<String, dynamic>>('/trips/a')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/trips/a'),
        statusCode: 200,
        data: {
          'points': [
            {
              'lat': 50.0,
              'lng': 7.0,
              'speed': 10.0,
              'altitude': 50.0,
              'accuracy': 5.0,
              't': DateTime.utc(2026, 1, 1, 17).toIso8601String(),
            },
          ],
        },
      ),
    );

    final points = await source.pointsFor(clientUuid: 'a');

    expect(points, hasLength(1));
    expect(
      points.single.timestamp,
      DateTime.utc(2026, 1, 1, 17).toLocal(),
      reason: 'UTC unveraendert zu uebernehmen verschoebe die Anzeigezeit',
    );
  });

  test('ohne Netz und ohne lokale Kopie bleibt die Strecke leer', () async {
    when(() => dio.get<Map<String, dynamic>>('/trips/a'))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '/trips/a')));

    expect(await source.pointsFor(clientUuid: 'a'), isEmpty);
  });

  test('zeigt noch nicht hochgeladene Fahrten neben denen der Cloud',
      () async {
    // Genau das ging verloren: die Fahrt lag auf dem Geraet, die Liste
    // zeigte nur die Cloud, und der Nutzer sah nichts.
    await repo.createTrip(local(DateTime(2026, 8, 17, 18), uuid: 'lokal-1'));

    when(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => page([row('cloud-1', DateTime(2026, 8, 16))]));

    final trips = await source.keptTrips();

    expect(trips.map((t) => t.clientUuid), ['lokal-1', 'cloud-1']);
  });

  test('zeigt eine hochgeladene Fahrt nicht doppelt', () async {
    // Zwischen Upload und Vermerk in der Datenbank liegt ein Moment; in
    // dem darf die Fahrt nicht zweimal in der Liste stehen.
    await repo.createTrip(local(DateTime(2026, 8, 17, 18), uuid: 'beide'));

    when(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => page([row('beide', DateTime(2026, 8, 17, 18))]));

    final trips = await source.keptTrips();

    expect(trips, hasLength(1));
  });

  test('sortiert die gemischte Liste nach Datum', () async {
    await repo.createTrip(local(DateTime(2026, 8, 10), uuid: 'alt-lokal'));

    when(() => dio.get<Map<String, dynamic>>(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => page([
              row('neu-cloud', DateTime(2026, 8, 20)),
              row('mittel-cloud', DateTime(2026, 8, 15)),
            ]));

    final trips = await source.keptTrips();

    expect(trips.map((t) => t.clientUuid),
        ['neu-cloud', 'mittel-cloud', 'alt-lokal']);
  });
}

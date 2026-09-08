import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/cloud/friend_repository.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> overview(Map<String, dynamic> body) => Response(
      requestOptions: RequestOptions(path: '/friends'),
      statusCode: 200,
      data: body,
    );

Map<String, dynamic> entry(int id, String username, String status) => {
      'id': id,
      'status': status,
      'username': username,
      'display_name': 'Anzeige $username',
    };

void main() {
  late MockDio dio;
  late FriendRepository repo;

  setUp(() {
    dio = MockDio();
    repo = FriendRepository(dio);
  });

  test('trennt Freunde, eingehende und ausgehende Anfragen', () async {
    when(() => dio.get<Map<String, dynamic>>('/friends')).thenAnswer(
      (_) async => overview({
        'friends': [entry(1, 'freund', 'accepted')],
        'incoming': [entry(2, 'fragtan', 'pending')],
        'outgoing': [entry(3, 'angefragt', 'pending')],
      }),
    );

    final result = await repo.load();

    expect(result.friends.single.username, 'freund');
    expect(result.incoming.single.username, 'fragtan');
    expect(result.outgoing.single.username, 'angefragt');
  });

  test('kommt mit fehlenden Listen zurecht', () async {
    when(() => dio.get<Map<String, dynamic>>('/friends'))
        .thenAnswer((_) async => overview({}));

    final result = await repo.load();

    expect(result.friends, isEmpty);
    expect(result.incoming, isEmpty);
  });

  test('schickt den Benutzernamen bei der Anfrage mit', () async {
    late Map<String, dynamic> sent;
    when(() => dio.post('/friends', data: any(named: 'data')))
        .thenAnswer((invocation) async {
      sent = invocation.namedArguments[#data] as Map<String, dynamic>;
      return Response(
        requestOptions: RequestOptions(path: '/friends'),
        statusCode: 201,
      );
    });

    await repo.request('collin');

    expect(sent['username'], 'collin');
  });

  test('reicht die Meldung des Servers durch, statt eine zu erfinden',
      () async {
    // "gibt es nicht", "laeuft bereits" und "seid bereits befreundet" sind
    // serverseitig unterschieden -- der Nutzer soll den Unterschied sehen.
    when(() => dio.post('/friends', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/friends'),
        response: Response(
          requestOptions: RequestOptions(path: '/friends'),
          statusCode: 422,
          data: {
            'message': 'Fehler',
            'errors': {
              'username': ['Ihr seid bereits befreundet.'],
            },
          },
        ),
      ),
    );

    await expectLater(
      repo.request('collin'),
      throwsA(
        isA<FriendException>().having(
          (e) => e.message,
          'message',
          'Ihr seid bereits befreundet.',
        ),
      ),
    );
  });

  test('faellt auf eine eigene Meldung zurueck, wenn keine kommt', () async {
    when(() => dio.post('/friends', data: any(named: 'data'))).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/friends')),
    );

    await expectLater(
      repo.request('collin'),
      throwsA(isA<FriendException>()),
    );
  });
}

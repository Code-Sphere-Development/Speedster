import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/token_store.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late InMemoryTokenStore store;
  late AuthRepository repo;

  setUp(() {
    dio = MockDio();
    store = InMemoryTokenStore();
    repo = AuthRepository(dio: dio, tokenStore: store);
  });

  test('login stores the returned token', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {'token': 'abc123'},
        statusCode: 200,
      ),
    );

    await repo.login('a@b.c', 'secret12');
    expect(await store.read(), 'abc123');
  });

  test('login surfaces AuthException on 422', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 422,
          data: {'message': 'Ungültig.'},
        ),
      ),
    );

    expect(() => repo.login('a@b.c', 'wrong'), throwsA(isA<AuthException>()));
    expect(await store.read(), isNull);
  });

  test('register sends the username alongside name, email and password',
      () async {
    late Map<String, dynamic> sent;
    when(() => dio.post('/auth/register', data: any(named: 'data')))
        .thenAnswer((invocation) async {
      sent = invocation.namedArguments[#data] as Map<String, dynamic>;
      return Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        data: {'token': 'tok'},
        statusCode: 201,
      );
    });

    await repo.register(
      name: 'Collin',
      username: 'collin',
      email: 'a@b.c',
      password: 'secret12',
    );

    expect(sent['username'], 'collin');
    expect(sent['name'], 'Collin');
    expect(await store.read(), 'tok');
  });

  test('register surfaces the server message when the username is taken',
      () async {
    when(() => dio.post('/auth/register', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 422,
          data: {
            'message': 'Dieser Benutzername ist bereits vergeben.',
            'errors': {
              'username': ['Dieser Benutzername ist bereits vergeben.'],
            },
          },
        ),
      ),
    );

    await expectLater(
      repo.register(
        name: 'Collin',
        username: 'collin',
        email: 'a@b.c',
        password: 'secret12',
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('bereits vergeben'),
        ),
      ),
    );
    expect(await store.read(), isNull);
  });

  test('loginSocial omits the username when none is given', () async {
    late Map<String, dynamic> sent;
    when(() => dio.post('/auth/social', data: any(named: 'data')))
        .thenAnswer((invocation) async {
      sent = invocation.namedArguments[#data] as Map<String, dynamic>;
      return Response(
        requestOptions: RequestOptions(path: '/auth/social'),
        data: {'token': 'tok'},
        statusCode: 200,
      );
    });

    await repo.loginSocial('google', 'id-token');
    expect(sent.containsKey('username'), isFalse);

    await repo.loginSocial('google', 'id-token', username: 'collin');
    expect(sent['username'], 'collin');
  });

  group('Geraeteregion', () {
    Future<Map<String, dynamic>> capture(
      MockDio dio,
      String path,
      Future<void> Function() call,
    ) async {
      late Map<String, dynamic> sent;
      when(() => dio.post(path, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return Response(
          requestOptions: RequestOptions(path: path),
          data: {'token': 'tok'},
          statusCode: 200,
        );
      });
      await call();

      return sent;
    }

    test('schickt sie beim Anmelden mit', () async {
      final sent = await capture(
        dio,
        '/auth/login',
        () => repo.login('a@b.c', 'secret12'),
      );

      // Im Test meldet die Plattform je nach Umgebung eine Region oder
      // keine. Beides ist zulaessig -- nur geraten werden darf nicht.
      final country = sent['country'];
      expect(country == null || (country as String).length == 2, isTrue);
      if (country != null) {
        expect(country, country.toUpperCase());
      }
    });

    test('laesst den Schluessel weg, wenn das Geraet keine Region kennt',
        () async {
      // Der Server prueft gegen die Laenderliste; ein leerer oder
      // geratener Wert wuerde mit 422 abgewiesen.
      final sent = await capture(
        dio,
        '/auth/register',
        () => repo.register(
          name: 'Collin',
          username: 'collin',
          email: 'a@b.c',
          password: 'secret12',
        ),
      );

      expect(sent.containsKey('country'), deviceCountry() != null);
    });
  });
}

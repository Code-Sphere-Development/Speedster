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
}

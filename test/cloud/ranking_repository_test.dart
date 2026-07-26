import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/cloud/ranking_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('parses board with entries and me', () async {
    final dio = MockDio();
    when(() => dio.get('/rankings', queryParameters: any(named: 'queryParameters')))
        .thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/rankings'),
        statusCode: 200,
        data: {
          'scope': 'world',
          'metric': 'max_speed',
          'entries': [
            {'rank': 1, 'display_name': 'Fast', 'country': 'DE', 'value': 54.2},
            {'rank': 2, 'display_name': 'Slow', 'country': null, 'value': 20.0},
          ],
          'me': {'rank': 2, 'value': 20.0},
        },
      ),
    );

    final board = await RankingRepository(dio)
        .fetch(RankScope.world, RankMetric.maxSpeed);

    expect(board.entries, hasLength(2));
    expect(board.entries.first.displayName, 'Fast');
    expect(board.entries.first.value, 54.2);
    expect(board.me?.rank, 2);
  });

  test('me is null when absent', () async {
    final dio = MockDio();
    when(() => dio.get('/rankings', queryParameters: any(named: 'queryParameters')))
        .thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/rankings'),
        statusCode: 200,
        data: {'entries': [], 'me': null},
      ),
    );

    final board = await RankingRepository(dio)
        .fetch(RankScope.country, RankMetric.tripCount);

    expect(board.entries, isEmpty);
    expect(board.me, isNull);
  });
}

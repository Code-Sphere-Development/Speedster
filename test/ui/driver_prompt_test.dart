import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/stats/stats_engine.dart';
import 'package:speedster/ui/driver_prompt.dart';

class _FakeRepo implements TripRepository {
  final List<(int, bool)> keptCalls = [];

  @override
  Future<void> setKept(int tripId, bool kept) async {
    keptCalls.add((tripId, kept));
  }

  @override
  Future<int> createTrip(Trip t) async => 0;
  @override
  Future<void> addPoints(int tripId, List<TrackPoint> pts) async {}
  @override
  Future<void> finalizeTrip(int id, TripStats s, DateTime e) async {}
  @override
  Future<List<Trip>> keptTrips() async => [];
  @override
  Future<List<TrackPoint>> pointsFor(int tripId) async => [];
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<Trip>> unsyncedTrips() async => [];
  @override
  Future<void> markSynced(String clientUuid) async {}
  @override
  Future<Map<String, int>> clientUuidIndex() async => {};
  @override
  Future<int> evictSyncedBeyond(int keep) async => 0;
}

void main() {
  testWidgets('Verwerfen marks trip kept=false', (tester) async {
    final repo = _FakeRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tripRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: DriverPrompt(tripId: 7)),
        ),
      ),
    );

    await tester.tap(find.text('Verwerfen'));
    await tester.pump();

    expect(repo.keptCalls, [(7, false)]);
  });
}

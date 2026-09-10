import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/data/trip_repository.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/stats/stats_engine.dart';
import 'package:speedster/ui/driver_prompt.dart';

class _FakeRepo implements TripRepository {
  final List<(int, bool)> keptCalls = [];

  @override
  Future<void> setPurpose(int id, String? purpose, String? note) async {}
  @override
  Future<String?> clientUuidFor(int tripId) async => 'uuid-$tripId';
  @override
  Future<void> setKept(int tripId, bool kept) async {
    keptCalls.add((tripId, kept));
  }

  @override
  Future<int> createTrip(Trip t) async => 0;
  @override
  Future<void> addPoints(int tripId, List<TrackPoint> pts) async {}
  @override
  Future<void> finalizeTrip(int id, TripStats s, DateTime e,
      {int? cloudVehicleId}) async {}
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
    // Ohne Cloud: der Dialog soll dann gar nichts verschicken.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(repo),
          // Der Dialog fragt die Einstellungen, um zu wissen, ob die
          // Cloud im Spiel ist -- auch beim Verwerfen, denn eine bereits
          // hochgeladene Fahrt muss dort wieder weg.
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DriverPrompt(tripId: 7)),
        ),
      ),
    );

    await tester.tap(find.text('Verwerfen'));
    await tester.pump();

    expect(repo.keptCalls, [(7, false)]);
  });
}

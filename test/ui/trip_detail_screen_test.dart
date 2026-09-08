import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/domain/track_point.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/trip_detail_screen.dart';

Trip sampleTrip() => Trip(
      id: 1,
      startTime: DateTime(2026, 1, 1, 12),
      endTime: DateTime(2026, 1, 1, 12, 30),
      maxSpeed: 10,
      avgSpeed: 5,
      distance: 1500,
      elevationGain: 42,
      durationSeconds: 1800,
      zeroToHundredSeconds: null,
      kept: true,
      clientUuid: 'fahrt-1',
    );

void main() {
  testWidgets('renders stat tiles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tripPointsProvider((clientUuid: 'fahrt-1', localId: 1))
              .overrideWith(
            (ref) => <TrackPoint>[
              TrackPoint(
                tripId: 1,
                lat: 50,
                lng: 6,
                speed: 10,
                altitude: 100,
                accuracy: 3,
                timestamp: DateTime(2026, 1, 1, 12),
              ),
            ],
          ),
        ],
        child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: TripDetailScreen(trip: sampleTrip())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Höhenmeter'), findsOneWidget);
    expect(find.textContaining('36 km/h'), findsOneWidget); // maxSpeed 10 m/s
    expect(find.text('42 m'), findsOneWidget);
  });
}

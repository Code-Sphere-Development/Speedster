import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/trip_list_screen.dart';

Trip trip(int id, double maxSpeed) => Trip(
      id: id,
      startTime: DateTime(2026, 1, id, 12),
      endTime: DateTime(2026, 1, id, 12, 30),
      maxSpeed: maxSpeed,
      avgSpeed: 5,
      distance: 1500,
      elevationGain: 10,
      durationSeconds: 1800,
      zeroToHundredSeconds: null,
      kept: true,
    );

void main() {
  testWidgets('renders a card per trip with formatted max speed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          keptTripsProvider.overrideWith(
            (ref) => [trip(1, 10), trip(2, 20)],
          ),
        ],
        child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: TripListScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(Card), findsNWidgets(2));
    expect(find.textContaining('36 km/h'), findsOneWidget); // 10 m/s
    expect(find.textContaining('72 km/h'), findsOneWidget); // 20 m/s
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/trip.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/components/card_section.dart';
import 'package:speedster/ui/components/route_thumbnail.dart';
import 'package:speedster/ui/trip_list_screen.dart';

Trip trip(
  int id,
  double maxSpeed, {
  String? routePreview,
  String? purpose,
  DateTime? syncedAt,
}) =>
    Trip(
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
      routePreview: routePreview,
      purpose: purpose,
      syncedAt: syncedAt,
    );

Future<void> pumpTrips(WidgetTester tester, List<Trip> trips) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        keptTripsProvider.overrideWith((ref) => trips),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TripListScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders a card per trip with formatted max speed',
      (tester) async {
    await pumpTrips(tester, [trip(1, 10), trip(2, 20)]);

    // Eine Karte je Monat, nicht je Fahrt: beide Fahrten liegen im
    // Januar 2026 und teilen sich damit einen Abschnitt.
    expect(find.byType(CardSection), findsOneWidget);
    expect(find.text('JANUAR 2026'), findsOneWidget);

    // Zahl und Einheit stehen in zwei Textknoten: nur so laesst sich die
    // Zahl gross und die Einheit klein setzen.
    expect(find.text('36'), findsOneWidget); // 10 m/s
    expect(find.text('72'), findsOneWidget); // 20 m/s
    expect(find.text('km/h'), findsNWidgets(2));
  });

  testWidgets('jede Zeile traegt ein Streckenbild', (tester) async {
    // Auch ohne gespeicherte Strecke: sonst waere die Zeile ohne
    // Vorschau schmaler als die daneben, und die Liste franste aus.
    await pumpTrips(tester, [
      trip(1, 10, routePreview: '52.50000,13.40000;52.51000,13.41000'),
      trip(2, 20),
    ]);

    expect(find.byType(RouteThumbnail), findsNWidgets(2));
  });

  testWidgets('zeigt den Zweck, sobald einer gesetzt ist', (tester) async {
    // Der Zweck stand bislang nur in der Detailansicht -- also nirgends,
    // wo man ihn zum Vergleichen gebraucht haette.
    await pumpTrips(tester, [trip(1, 10, purpose: 'commute'), trip(2, 20)]);

    expect(find.text('Arbeitsweg'), findsOneWidget);
  });

  testWidgets('markiert Fahrten, die noch nicht in der Cloud sind',
      (tester) async {
    // Die Liste mischt lokale Fahrten unter die aus der Cloud; bisher sah
    // man ihnen das nicht an.
    await pumpTrips(tester, [
      trip(1, 10),
      trip(2, 20, syncedAt: DateTime(2026, 1, 3)),
    ]);

    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('gruppiert nach Monat', (tester) async {
    // Die Gruppierung ersetzt die Reihe gleich aussehender Karten und
    // traegt nebenbei eine Zahl, die vorher nirgends stand: wie weit man
    // in diesem Monat gekommen ist.
    await pumpTrips(tester, [
      trip(1, 10),
      Trip(
        id: 9,
        startTime: DateTime(2025, 12, 24, 12),
        endTime: DateTime(2025, 12, 24, 12, 30),
        maxSpeed: 30,
        avgSpeed: 5,
        distance: 2500,
        elevationGain: 0,
        durationSeconds: 1800,
        zeroToHundredSeconds: null,
        kept: true,
      ),
    ]);

    expect(find.byType(CardSection), findsNWidgets(2));
    expect(find.text('JANUAR 2026'), findsOneWidget);
    expect(find.text('DEZEMBER 2025'), findsOneWidget);
  });
}

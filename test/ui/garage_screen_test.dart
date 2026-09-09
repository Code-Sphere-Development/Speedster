import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/vehicle_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/garage_screen.dart';

class MockVehicles extends Mock implements VehicleRepository {}

Vehicle vehicle({
  int id = 1,
  String name = 'Der Golf',
  bool isDefault = true,
  VehicleModel? model,
}) =>
    Vehicle(id: id, name: name, isDefault: isDefault, model: model);

Future<void> pumpGarage(
  WidgetTester tester, {
  required bool cloud,
  List<Vehicle> vehicles = const [],
  VehicleRepository? repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repo != null) vehicleRepositoryProvider.overrideWithValue(repo),
        cloudActiveProvider.overrideWith((ref) async => cloud),
        vehiclesProvider.overrideWith((ref) async => vehicles),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GarageScreen(),
      ),
    ),
  );
  // pumpAndSettle statt zweier Durchlaeufe: der Knopf faehrt eingeblendet
  // hoch, und waehrend der Animation nimmt er keine Tipper an.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('verweist ohne Cloud auf die Synchronisierung', (tester) async {
    // Ohne Konto gibt es nichts, woran Fahrzeuge haengen koennten. Eine
    // leere Liste saehe aus wie ein Fehler.
    await pumpGarage(tester, cloud: false);

    expect(find.textContaining('Cloud-Synchronisierung'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('zeigt Fahrzeuge mit Modell und Standardmarke', (tester) async {
    await pumpGarage(tester, cloud: true, vehicles: [
      vehicle(
        model: const VehicleModel(
          id: 7,
          label: 'VW Golf VII',
          vehicleClass: 'C-Segment',
          fuel: 'Dieselmotor',
        ),
      ),
      vehicle(id: 2, name: 'Winterauto', isDefault: false),
    ]);

    expect(find.text('Der Golf'), findsOneWidget);
    expect(find.textContaining('VW Golf VII'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    // Ohne Modell steht dort der Hinweis, nicht eine leere Zeile.
    expect(find.textContaining('Kein Modell'), findsOneWidget);
  });

  testWidgets('bietet den Wechsel nur beim Nicht-Standard an', (tester) async {
    await pumpGarage(tester, cloud: true, vehicles: [
      vehicle(),
      vehicle(id: 2, name: 'Winterauto', isDefault: false),
    ]);

    expect(find.text('Zum Standard machen'), findsOneWidget);
  });

  testWidgets('macht ein Fahrzeug zum Standard', (tester) async {
    final repo = MockVehicles();
    when(() => repo.makeDefault(any())).thenAnswer((_) async {});

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [
      vehicle(),
      vehicle(id: 2, name: 'Winterauto', isDefault: false),
    ]);

    // Die Kachel traegt inzwischen Tachostand und Wartung; der Knopf des
    // zweiten Fahrzeugs liegt damit unterhalb des Sichtbereichs.
    await tester.ensureVisible(find.text('Zum Standard machen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zum Standard machen'));
    await tester.pump();

    verify(() => repo.makeDefault(2)).called(1);
  });

  testWidgets('loescht erst nach Rueckfrage', (tester) async {
    final repo = MockVehicles();
    when(() => repo.remove(any())).thenAnswer((_) async {});

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [vehicle()]);

    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Die Fahrten bleiben erhalten'), findsOneWidget);
    verifyNever(() => repo.remove(any()));

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.remove(any()));
  });

  testWidgets('sagt beim leeren Katalog, dass nichts gefunden wurde',
      (tester) async {
    final repo = MockVehicles();
    when(() => repo.searchModels(any())).thenAnswer((_) async => const []);

    await pumpGarage(tester, cloud: true, repo: repo);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Gibtsnicht');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text('Kein Modell gefunden.'), findsOneWidget);
  });

  testWidgets('legt ein Fahrzeug ohne Modell an', (tester) async {
    // Wer sein Modell nicht findet, soll trotzdem eines fuehren koennen.
    final repo = MockVehicles();
    when(() => repo.create(
          name: any(named: 'name'),
          vehicleModelId: any(named: 'vehicleModelId'),
          year: any(named: 'year'),
          powerPs: any(named: 'powerPs'),
        )).thenAnswer((_) async => vehicle());

    await pumpGarage(tester, cloud: true, repo: repo);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Oldtimer');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    verify(() => repo.create(
          name: 'Oldtimer',
          vehicleModelId: null,
          year: null,
          powerPs: null,
        )).called(1);
  });

  testWidgets('fuellt beim Bearbeiten die vorhandenen Werte', (tester) async {
    // Ohne das verloere ein Konto sein Modell, sobald es nur den Namen
    // aendert.
    final repo = MockVehicles();
    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [
      const Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        year: 2019,
        powerPs: 150,
        model: VehicleModel(id: 7, label: 'VW Golf VII'),
      ),
    ]);

    // Der Stift steht beim Namen, nicht am Fuss der Kachel.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Der Golf'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2019'), findsOneWidget);
    expect(find.widgetWithText(TextField, '150'), findsOneWidget);
    // Das zugeordnete Modell steht in der Auswahl, ohne erneute Suche.
    expect(find.text('VW Golf VII'), findsOneWidget);
  });

  testWidgets('schickt beim Bearbeiten update statt create', (tester) async {
    final repo = MockVehicles();
    when(() => repo.update(
          any(),
          name: any(named: 'name'),
          vehicleModelId: any(named: 'vehicleModelId'),
          year: any(named: 'year'),
          powerPs: any(named: 'powerPs'),
        )).thenAnswer((_) async => vehicle());

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [vehicle()]);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Golf VII');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    verify(() => repo.update(1,
        name: 'Golf VII',
        vehicleModelId: null,
        year: null,
        powerPs: null)).called(1);
    verifyNever(() => repo.create(
          name: any(named: 'name'),
          vehicleModelId: any(named: 'vehicleModelId'),
          year: any(named: 'year'),
          powerPs: any(named: 'powerPs'),
        ));
  });

  testWidgets('zeigt den Tachostand als Schaetzung mit Grundlage',
      (tester) async {
    // Nie die nackte Zahl: aufgezeichnet wird nur, was die App
    // mitbekommen hat.
    await pumpGarage(tester, cloud: true, vehicles: [
      Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        odometer: Odometer(
          estimateKm: 120042,
          trackedKm: 42.3,
          readingKm: 120000,
          readAt: DateTime(2026, 9, 1),
        ),
      ),
    ]);

    // Mit Tausendertrennung: "120042" liest niemand auf einen Blick.
    expect(find.textContaining('ca. 120.042'), findsOneWidget);
    expect(find.textContaining('120.000'), findsWidgets);
  });

  testWidgets('sagt ohne Ablesung, dass keine vorliegt', (tester) async {
    await pumpGarage(tester, cloud: true, vehicles: [vehicle()]);

    expect(find.textContaining('Noch kein Tachostand'), findsOneWidget);
  });

  testWidgets('meldet nach dem Eintragen die Abweichung', (tester) async {
    // Das ist die eigentliche Auskunft: so viel hat die App nicht
    // mitbekommen.
    final repo = MockVehicles();
    when(() => repo.addReading(any(), any(), any()))
        .thenAnswer((_) async => 80);

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [vehicle()]);

    await tester.tap(find.text('Tachostand eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '120180');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    verify(() => repo.addReading(1, 120180, any())).called(1);
    expect(find.textContaining('+80'), findsOneWidget);
  });

  testWidgets('zeigt faellige Wartung in Tagen und Kilometern',
      (tester) async {
    await pumpGarage(tester, cloud: true, vehicles: [
      const Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        maintenance: [
          MaintenanceItem(
            id: 1,
            title: 'HU',
            daysLeft: 30,
          ),
          MaintenanceItem(
            id: 2,
            title: 'Ölwechsel',
            dueKm: 121000,
            kilometersLeft: 1570,
          ),
        ],
      ),
    ]);

    expect(find.text('HU'), findsOneWidget);
    expect(find.textContaining('in 30 Tagen'), findsOneWidget);
    expect(find.textContaining('in ca. 1.570 km'), findsOneWidget);
  });

  testWidgets('nennt ohne Tachostand keine Restkilometer', (tester) async {
    // Eine Restangabe ohne Bezugsgroesse waere keine Auskunft.
    await pumpGarage(tester, cloud: true, vehicles: [
      const Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        maintenance: [
          MaintenanceItem(id: 1, title: 'Ölwechsel', dueKm: 135000),
        ],
      ),
    ]);

    expect(find.textContaining('bei 135.000 km'), findsOneWidget);
    expect(find.textContaining('in ca.'), findsNothing);
  });

  testWidgets('verlangt Termin oder Laufleistung', (tester) async {
    // Ohne beides waere es kein Termin, sondern eine Notiz -- dieselbe
    // Regel wie am Server.
    final repo = MockVehicles();
    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [vehicle()]);

    await tester.tap(find.text('Wartung eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'HU');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Datum oder einen Kilometerstand'),
        findsOneWidget);
    verifyNever(() => repo.addMaintenance(any(),
        title: any(named: 'title'),
        dueOn: any(named: 'dueOn'),
        dueKm: any(named: 'dueKm')));
  });

  testWidgets('hakt eine Wartung ab', (tester) async {
    final repo = MockVehicles();
    when(() => repo.completeMaintenance(any(), any()))
        .thenAnswer((_) async {});

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [
      const Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        maintenance: [MaintenanceItem(id: 5, title: 'HU', daysLeft: 3)],
      ),
    ]);

    await tester.tap(find.text('Erledigt'));
    await tester.pump();

    verify(() => repo.completeMaintenance(1, 5)).called(1);
  });

  testWidgets('bietet "in x km" nur mit Tachostand an', (tester) async {
    // Ohne Bezugspunkt lehnte der Server den Restweg ab -- dann wird er
    // gar nicht erst angeboten.
    final repo = MockVehicles();

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [vehicle()]);
    await tester.tap(find.text('Wartung eintragen'));
    await tester.pumpAndSettle();

    expect(find.text('In x Kilometern'), findsNothing);
  });

  testWidgets('schickt den Restweg getrennt vom Zielstand', (tester) async {
    final repo = MockVehicles();
    when(() => repo.addMaintenance(any(),
        title: any(named: 'title'),
        dueOn: any(named: 'dueOn'),
        dueKm: any(named: 'dueKm'),
        dueInKm: any(named: 'dueInKm'))).thenAnswer((_) async {});

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [
      const Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        odometer: Odometer(estimateKm: 128000),
      ),
    ]);

    await tester.tap(find.text('Wartung eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Inspektion');
    await tester.tap(find.text('In x Kilometern'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '5000');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    // Umgerechnet wird am Server -- hier waere dieselbe Rechnung ein
    // zweites Mal.
    verify(() => repo.addMaintenance(1,
        title: 'Inspektion',
        dueOn: null,
        dueKm: null,
        dueInKm: 5000)).called(1);
  });

  testWidgets('aendert eine Wartung, statt sie neu anzulegen', (tester) async {
    final repo = MockVehicles();
    when(() => repo.updateMaintenance(any(), any(),
        title: any(named: 'title'),
        dueOn: any(named: 'dueOn'),
        dueKm: any(named: 'dueKm'),
        dueInKm: any(named: 'dueInKm'))).thenAnswer((_) async {});

    await pumpGarage(tester, cloud: true, repo: repo, vehicles: [
      const Vehicle(
        id: 1,
        name: 'Der Golf',
        isDefault: true,
        maintenance: [
          MaintenanceItem(id: 5, title: 'Inspektion', dueKm: 13000),
        ],
      ),
    ]);

    // Am Fahrzeug ist es ein Stift oben, an der Wartung ein Knopf mit
    // Beschriftung -- hier ist die Wartung gemeint.
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    // Der vorhandene Wert steht drin -- sonst tippt man ihn erneut, und
    // genau dabei ist der Zahlendreher entstanden.
    expect(find.widgetWithText(TextField, '13000'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '130000');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    verify(() => repo.updateMaintenance(1, 5,
        title: 'Inspektion',
        dueOn: null,
        dueKm: 130000,
        dueInKm: null)).called(1);
    verifyNever(() => repo.addMaintenance(any(),
        title: any(named: 'title'),
        dueOn: any(named: 'dueOn'),
        dueKm: any(named: 'dueKm'),
        dueInKm: any(named: 'dueInKm')));
  });

  testWidgets('nennt die Leistung in der Einheit der Sprache',
      (tester) async {
    // PS im Deutschen, hp im Englischen -- die Einheit ist nicht ueberall
    // dieselbe.
    for (final (locale, unit) in [('de', 'PS'), ('en', 'hp')]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudActiveProvider.overrideWith((ref) async => true),
            vehiclesProvider.overrideWith((ref) async => [
                  const Vehicle(
                    id: 1,
                    name: 'Der Golf',
                    isDefault: true,
                    powerPs: 150,
                  ),
                ]),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const GarageScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('150 $unit'), findsOneWidget,
          reason: 'Einheit fehlt in $locale');
    }
  });
}

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

    await tester.tap(find.text('Bearbeiten'));
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

    await tester.tap(find.text('Bearbeiten'));
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
}

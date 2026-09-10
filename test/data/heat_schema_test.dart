import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('Schemaversion ist 8', () async {
    // Die Zahl steht hier fest, damit eine Aenderung am Schema auffaellt,
    // solange die zugehoerige Migration noch fehlt. Wer sie hebt, hat
    // sie geschrieben.
    expect(db.schemaVersion, 8);
  });

  test('Fahrten fuehren ein Fahrzeug, das leer bleiben darf', () async {
    // Bestandsfahrten haben keines, und eine geratene Zuordnung waere
    // eine Behauptung ueber die Vergangenheit.
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(startTime: DateTime(2026, 9, 9, 12)),
        );

    final row = await (db.select(db.trips)..where((t) => t.id.equals(id)))
        .getSingle();

    expect(row.cloudVehicleId, isNull);
    // Ebenso Zweck und Notiz: ein geratener Zweck waere eine Behauptung
    // ueber die Vergangenheit.
    expect(row.purpose, isNull);
    expect(row.note, isNull);
  });

  test('Heat-Tabellen existieren und nehmen Zeilen auf', () async {
    await db.into(db.heatCells).insert(
          HeatCellsCompanion.insert(
            level: 0,
            cellRow: 10,
            cellCol: 20,
            latSum: const Value(100.0),
            lngSum: const Value(12.0),
            n: const Value(2),
          ),
        );
    await db.into(db.heatEdges).insert(
          HeatEdgesCompanion.insert(
            level: 0,
            aRow: 10,
            aCol: 20,
            bRow: 10,
            bCol: 21,
            count: const Value(3),
          ),
        );

    expect((await db.select(db.heatCells).get()).single.n, 2);
    expect((await db.select(db.heatEdges).get()).single.count, 3);
  });

  test('Trips traegt heatFoldedAt und ist anfangs null', () async {
    final id = await db.into(db.trips).insert(
          TripsCompanion.insert(startTime: DateTime.utc(2026, 1, 1)),
        );
    final row =
        await (db.select(db.trips)..where((t) => t.id.equals(id))).getSingle();
    expect(row.heatFoldedAt, isNull);
  });
}

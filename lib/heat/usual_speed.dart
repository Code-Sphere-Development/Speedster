import 'package:drift/drift.dart';
import 'package:speedster/data/database.dart';
import 'package:speedster/heat/heat_grid.dart';

/// Wie schnell an einem Ort ueblicherweise gefahren wird.
class UsualSpeed {
  const UsualSpeed({required this.metersPerSecond, required this.samples});

  /// Durchschnitt der bisher dort gemessenen Geschwindigkeiten.
  final double metersPerSecond;

  /// Wie viele Messungen dahinterstehen. Wenige Messungen tragen kein
  /// Urteil -- eine einzige Fahrt bei Nacht ist keine Gewohnheit.
  final int samples;
}

/// Urteil ueber die aktuelle Geschwindigkeit im Vergleich zur Gewohnheit.
enum SpeedVerdict {
  /// Zu wenige eigene Messungen an diesem Ort: keine Aussage.
  noReference,
  slower,
  usual,
  faster,
}

/// Schwellen des Vergleichs.
///
/// Zwei Bedingungen muessen zusammenkommen, ein relativer Abstand **und**
/// ein absoluter. Allein relativ betrachtet waere die Anzeige im
/// Schritttempo nervoes: 12 statt 10 km/h sind zwanzig Prozent, aber
/// niemand faehrt dort "deutlich zu schnell". Allein absolut betrachtet
/// spraeche sie auf der Autobahn nie an.
class SpeedComparison {
  const SpeedComparison({
    this.minSamples = 8,
    this.relative = 0.2,
    this.absolute = 2.8, // ~10 km/h
  });

  final int minSamples;
  final double relative;
  final double absolute;

  SpeedVerdict verdict(double current, UsualSpeed? usual) {
    if (usual == null || usual.samples < minSamples) {
      return SpeedVerdict.noReference;
    }

    final reference = usual.metersPerSecond;
    final delta = current - reference;

    if (delta > reference * relative && delta > absolute) {
      return SpeedVerdict.faster;
    }
    if (-delta > reference * relative && -delta > absolute) {
      return SpeedVerdict.slower;
    }

    return SpeedVerdict.usual;
  }
}

/// Liest die gewohnte Geschwindigkeit aus den Heat-Aggregaten.
///
/// Nutzt die feinste Rasterebene (25-m-Zellen): grober waere die Aussage
/// ueber eine Ortsdurchfahrt mit der danebenliegenden Umgehung vermischt.
class UsualSpeedReader {
  UsualSpeedReader(this.db, {this.level = 0});

  final AppDatabase db;
  final int level;

  Future<UsualSpeed?> at(double lat, double lng) async {
    final cell = HeatGrid.cellFor(lat, lng, level);
    final row = await (db.select(db.heatCells)
          ..where((c) =>
              c.level.equals(level) &
              c.cellRow.equals(cell.row) &
              c.cellCol.equals(cell.col)))
        .getSingleOrNull();

    if (row == null || row.n == 0) return null;

    return UsualSpeed(
      metersPerSecond: row.speedSum / row.n,
      samples: row.n,
    );
  }
}

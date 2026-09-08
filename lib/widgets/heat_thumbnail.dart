import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:speedster/heat/heat_map.dart';
import 'package:speedster/heat/heat_palette.dart';
import 'package:speedster/ui/map_tiles.dart';

/// Rendert die Heatmap als PNG fuer das Widget.
///
/// Bewusst **ohne Kartenkacheln**: Ein Widget hat kein Netz, und die
/// Quellenangabe, die OpenStreetMap und Esri verlangen, liesse sich auf
/// der kleinen Flaeche nicht lesbar unterbringen. Gezeigt wird nur das
/// Streckennetz auf dunklem Grund -- ohne Kacheln entsteht auch keine
/// Pflicht zur Nennung.
///
/// Die Zeichenweise entspricht `HeatGlowLayer`: ein weichgezeichneter
/// Schein, darueber ein scharfer Kern, beides additiv. Nicht dieselbe
/// Klasse, weil jene an die Kamera von flutter_map gebunden ist -- hier
/// wird auf die Umschliessende der Kanten skaliert.
class HeatThumbnail {
  const HeatThumbnail._();

  /// Rand in Pixeln, damit der Schein am Bildrand nicht abgeschnitten wird.
  static const double margin = 16;

  static Future<Uint8List?> render(HeatMap map, {int size = 512}) async {
    if (map.edges.isEmpty) return null;

    final bounds = _bounds(map.edges);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final area = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

    canvas.drawRect(area, ui.Paint()..color = esriDarkBackground);

    final points = [
      for (final e in map.edges)
        (
          _project(e.aLat, e.aLng, bounds, size),
          _project(e.bLat, e.bLng, bounds, size),
          HeatPalette.styleFor(e.count, map.maxCount),
        ),
    ];

    canvas.saveLayer(area, ui.Paint());
    canvas.saveLayer(
      area.inflate(HeatPalette.glowBlurSigma * 3),
      ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: HeatPalette.glowBlurSigma / 3,
          sigmaY: HeatPalette.glowBlurSigma / 3,
        ),
    );
    for (final (a, b, style) in points) {
      _stroke(canvas, a, b, style.glow, scale: 0.35);
    }
    canvas.restore();
    for (final (a, b, style) in points) {
      _stroke(canvas, a, b, style.core, scale: 0.5);
    }
    canvas.restore();

    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return data?.buffer.asUint8List();
  }

  static void _stroke(
    ui.Canvas canvas,
    ui.Offset a,
    ui.Offset b,
    HeatLayer layer, {
    required double scale,
  }) {
    canvas.drawLine(
      a,
      b,
      ui.Paint()
        ..color = layer.color
        // Auf Widget-Groesse heruntergerechnet: die Strichstaerken der
        // Karte sind fuer einen ganzen Bildschirm gedacht und wuerden
        // hier alles zu einem Fleck verschmelzen.
        ..strokeWidth = math.max(0.6, layer.strokeWidth * scale)
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..style = ui.PaintingStyle.stroke
        ..blendMode = ui.BlendMode.plus,
    );
  }

  static ({double minLat, double maxLat, double minLng, double maxLng}) _bounds(
    List<HeatEdgeView> edges,
  ) {
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final e in edges) {
      for (final (lat, lng) in [(e.aLat, e.aLng), (e.bLat, e.bLng)]) {
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLng = math.min(minLng, lng);
        maxLng = math.max(maxLng, lng);
      }
    }

    return (minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng);
  }

  /// Gleichmaessige Skalierung auf die laengere Achse, damit die Strecken
  /// nicht verzerren. Der Laengengrad wird um den Kosinus der Breite
  /// gestaucht -- sonst zoege sich das Netz in Deutschland spuerbar in die
  /// Breite.
  static ui.Offset _project(
    double lat,
    double lng,
    ({double minLat, double maxLat, double minLng, double maxLng}) b,
    int size,
  ) {
    final cos = math.cos((b.minLat + b.maxLat) / 2 * math.pi / 180).abs();
    final width = math.max((b.maxLng - b.minLng) * cos, 1e-9);
    final height = math.max(b.maxLat - b.minLat, 1e-9);
    final usable = size - margin * 2;
    final scale = math.min(usable / width, usable / height);

    final x = (lng - b.minLng) * cos * scale;
    final y = (b.maxLat - lat) * scale;

    return ui.Offset(
      margin + x + (usable - width * scale) / 2,
      margin + y + (usable - height * scale) / 2,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/domain/route_preview.dart';
import 'package:speedster/domain/track_point.dart';

TrackPoint point(double lat, double lng, {int second = 0}) => TrackPoint(
      tripId: 1,
      lat: lat,
      lng: lng,
      speed: 10,
      altitude: 0,
      accuracy: 5,
      timestamp: DateTime(2026, 1, 1).add(Duration(seconds: second)),
    );

void main() {
  test('ohne Punkte gibt es nichts zu zeichnen', () {
    // null und nicht "": ein leerer Text waere ein zweiter Ausdruck fuer
    // denselben Zustand, und die Oberflaeche muesste beides pruefen.
    expect(RoutePreview.encode(const []), isNull);
    expect(RoutePreview.encodeLatLng(const []), isNull);
  });

  test('kurze Fahrten bleiben vollstaendig', () {
    final points = [
      for (var i = 0; i < 10; i++) point(52.5 + i * 0.001, 13.4, second: i),
    ];

    expect(RoutePreview.decode(RoutePreview.encode(points)), hasLength(10));
  });

  test('lange Fahrten werden auf maxPoints eingedampft', () {
    final points = [
      for (var i = 0; i < 5000; i++) point(52.5 + i * 0.0001, 13.4, second: i),
    ];

    final decoded = RoutePreview.decode(RoutePreview.encode(points));

    expect(decoded.length, lessThanOrEqualTo(RoutePreview.maxPoints));
    expect(decoded.length, greaterThan(RoutePreview.maxPoints ~/ 2));
  });

  test('Anfang und Ende bleiben in jedem Fall erhalten', () {
    final points = [
      for (var i = 0; i < 500; i++) point(52.5 + i * 0.001, 13.4, second: i),
    ];

    final decoded = RoutePreview.decode(RoutePreview.encode(points));

    expect(decoded.first.lat, closeTo(52.5, 0.00001));
    expect(decoded.last.lat, closeTo(52.5 + 499 * 0.001, 0.00001));
  });

  test('verteilt nach Strecke, nicht nach Index', () {
    // Erst eine lange Standzeit auf einem Fleck, dann die eigentliche
    // Fahrt. Nach Index gerechnet fielen zwei Drittel aller Stuetzpunkte
    // auf den Parkplatz, und von der Strecke bliebe eine Gerade.
    final points = <TrackPoint>[
      for (var i = 0; i < 400; i++) point(52.5, 13.4, second: i),
      for (var i = 0; i < 200; i++)
        point(52.5 + i * 0.001, 13.4 + i * 0.001, second: 400 + i),
    ];

    final decoded = RoutePreview.decode(RoutePreview.encode(points));

    // Nahezu alle Stuetzpunkte liegen auf dem bewegten Teil.
    final moved = decoded.where((p) => p.lat > 52.5001).length;
    expect(moved, greaterThan(RoutePreview.maxPoints ~/ 2));
  });

  test('eine Fahrt, die sich nicht bewegt hat, ergibt zwei Punkte', () {
    final points = [
      for (var i = 0; i < 200; i++) point(52.5, 13.4, second: i),
    ];

    expect(RoutePreview.decode(RoutePreview.encode(points)), hasLength(2));
  });

  test('decode liest, was encode geschrieben hat', () {
    final points = [point(52.51234, 13.41234), point(48.13743, 11.57549)];

    final decoded = RoutePreview.decode(RoutePreview.encode(points));

    expect(decoded[0].lat, closeTo(52.51234, 0.00001));
    expect(decoded[0].lng, closeTo(13.41234, 0.00001));
    expect(decoded[1].lat, closeTo(48.13743, 0.00001));
    expect(decoded[1].lng, closeTo(11.57549, 0.00001));
  });

  test('beschaedigte Werte ergeben eine leere Liste, keinen Fehler', () {
    // Der Wert kommt aus der Datenbank. Eine kaputte Zeile darf die
    // Fahrtenliste nicht zum Absturz bringen.
    expect(RoutePreview.decode(null), isEmpty);
    expect(RoutePreview.decode(''), isEmpty);
    expect(RoutePreview.decode('kaputt'), isEmpty);
    expect(RoutePreview.decode('52.5,13.4;52.6'), isEmpty);
    expect(RoutePreview.decode('52.5,oben'), isEmpty);
  });
}

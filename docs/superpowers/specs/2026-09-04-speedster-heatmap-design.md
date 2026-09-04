# Speedster — Strecken-Heatmap (Design / PRD)

**Datum:** 2026-09-04
**Status:** Approved (Design)
**Scope:** Heatmap der eigenen gefahrenen Strecken als neuer Start-Tab. Je häufiger ein
Streckenabschnitt befahren wurde, desto heller/wärmer wird er rot eingefärbt. Lokal ohne Filter,
mit aktiver Cloud zusätzlich mit Zeitraum-Filtern. Enthält die Erkennung einer
CarPlay-/Android-Auto-Verbindung als Signal für die Start-Tab-Wahl.

## 1. Ziel

Der Nutzer sieht auf einer Karte, wo er wie oft gefahren ist. Der tägliche Arbeitsweg leuchtet hell,
die einmalige Urlaubsfahrt bleibt dunkel. Die Heatmap ist die Standardansicht beim App-Start —
außer der Nutzer fährt gerade, dann bleibt „Live" vorn.

## 2. Entscheidungen / Annahmen

- **Matching über ein Kanten-Raster**, kein Map-Matching auf OSM-Straßen. Map-Matching bräuchte
  einen OSRM/Valhalla-Dienst und wäre offline unmöglich — der lokale Modus ist aber
  Kernanforderung.
- **Zwei Implementierungen derselben reinen Funktion**: Dart (`lib/heat/heat_grid.dart`) und PHP
  (`backend/app/Services/HeatGrid.php`). Beide erhalten dieselben Testfixtures. Weichen sie ab,
  springt das Kartenbild beim Ein-/Ausloggen — das ist der Grund für die Doppelung, nicht
  Nachlässigkeit.
- **Zählweise:** jede Befahrung zählt. Hin- und Rückweg über dieselbe Straße innerhalb einer Fahrt
  ergibt `count = 2`.
- **Kantenschlüssel ungerichtet:** Fahrtrichtung ist irrelevant.
- **Quellenwahl:** Token vorhanden → Cloud (mit Filtern), sonst lokal (ohne Filter). Dieselbe
  Bedingung wie in `CloudSyncService.syncOnce()`.
- **Normierung logarithmisch**, nicht linear. Befahrungshäufigkeiten sind stark schief verteilt
  (Arbeitsweg 200×, Ausflug 1×); linear normiert wäre alles außer dem Arbeitsweg unlesbar dunkel.
- **Keine Fremd-Heatmap-Bibliothek.** Gerendert wird mit dem bereits genutzten `flutter_map` +
  `PolylineLayer`.

## 3. Rasterung (Kern-Algorithmus)

Identisch in Dart und PHP. Reine Funktionen, keine I/O.

### 3.1 Zellquantisierung

```
cellMeters(level)   = [25.0, 100.0, 400.0][level]
metersPerDegLat     = 111320.0
latStep             = cellMeters / metersPerDegLat
row                 = floor(lat / latStep)
rowLat              = (row + 0.5) * latStep
lngStep             = latStep / max(cos(rowLat * PI / 180), 0.01)
col                 = floor(lng / lngStep)
```

`row` hängt nur vom Breitengrad ab, `lngStep` nur von `row`. Dadurch ist die Quantisierung
deterministisch und nicht selbstbezüglich — beide Implementierungen kommen zwingend auf dieselbe
Zelle. Die `cos`-Skalierung hält die Zellen über alle Breitengrade näherungsweise quadratisch.
Der `max(..., 0.01)`-Clamp verhindert Division durch ~0 nahe den Polen.

### 3.2 Punkt-Vorbereitung

Pro Fahrt, auf den nach `timestamp` sortierten Punkten:

1. Punkte mit `accuracy > 50` m verwerfen.
2. **Lücke erkennen:** liegen zwei aufeinanderfolgende Punkte > 200 m oder > 30 s auseinander, wird
   die Polyline getrennt (keine Interpolation, keine Kante über die Lücke). Ohne diese Regel zieht
   ein GPS-Ausfall im Tunnel eine falsche Gerade quer durch die Stadt.
3. **Nachverdichten** auf ≤ 10 m: `n = floor(d / 10)` linear interpolierte Zwischenpunkte. Bei
   Tempo 130 liegen Sekundenpunkte 36 m auseinander und würden sonst ganze Zellen überspringen —
   die Linie bekäme Löcher. Lineare Interpolation in lat/lng ist auf diesen Distanzen
   vernachlässigbar ungenau.

### 3.3 Kantenextraktion

Auf der aufbereiteten Punktfolge, je Level:

1. Punkte auf Zellen abbilden, aufeinanderfolgende Duplikate (dieselbe Zelle) entfernen. Stillstand
   an der Ampel erzeugt dadurch keine Kante.
2. Aufeinanderfolgende Zellpaare = Kanten. Schlüssel normalisiert: das lexikografisch kleinere
   `(row, col)` ist `a`.
3. Direkt wiederholte identische Kanten kollabieren (GPS-Zittern über eine Zellgrenze).

Ergebnis pro Fahrt und Level: eine Liste von Kanten mit Vielfachheit, plus je berührter Zelle
`(latSum, lngSum, n)` aus den **real gemessenen** (nicht den interpolierten) Punkten.

### 3.4 Schwerpunkte statt Zellmitten

Gezeichnet wird eine Kante von Schwerpunkt zu Schwerpunkt (`latSum/n`, `lngSum/n`), nicht von
Zellmitte zu Zellmitte. Die Linie folgt dadurch dem tatsächlich gefahrenen Verlauf statt sichtbar
zu treppen. Kosten: zwei Additionen pro Punkt.

### 3.5 Zoomstufen-Pyramide

Drei Level (25 m / 100 m / 400 m) werden bei jeder Faltung gleichzeitig geschrieben. Grund: Ein
Vielfahrer mit 3.000 km unterschiedlicher Strecke hat auf Level 0 rund 120.000 Kanten. Das ist
weder als JSON übertragbar noch als `PolylineLayer` renderbar. Die Karte wählt das Level nach
Zoom:

| Zoom  | Level | Zellgröße |
|-------|-------|-----------|
| ≥ 14  | 0     | 25 m      |
| 11–13 | 1     | 100 m     |
| ≤ 10  | 2     | 400 m     |

Zusammen mit dem Viewport-Filter (Abschnitt 6.2) bleibt die Zahl gezeichneter Kanten in jeder
Situation im niedrigen vierstelligen Bereich.

## 4. Lokale Persistenz

Drift `schemaVersion` 2 → 3.

```dart
class HeatCells extends Table {          // PK (level, row, col)
  IntColumn  get level  => integer()();
  IntColumn  get row    => integer()();
  IntColumn  get col    => integer()();
  RealColumn get latSum => real().withDefault(const Constant(0))();
  RealColumn get lngSum => real().withDefault(const Constant(0))();
  IntColumn  get n      => integer().withDefault(const Constant(0))();
}

class HeatEdges extends Table {          // PK (level, aRow, aCol, bRow, bCol)
  IntColumn get level => integer()();
  IntColumn get aRow  => integer()();
  IntColumn get aCol  => integer()();
  IntColumn get bRow  => integer()();
  IntColumn get bCol  => integer()();
  IntColumn get count => integer().withDefault(const Constant(0))();
}
```

`Trips` += `heatFoldedAt` (DateTime, nullable).

Migration v2 → v3: beide Tabellen anlegen, Spalte ergänzen. Bestehende Fahrten haben
`heatFoldedAt = NULL` und werden beim ersten Heatmap-Aufruf nachgefaltet — damit ist der Backfill
für vorhandene Installationen abgedeckt, ohne Migrationslogik über GPS-Blobs.

Index auf `(level, aRow, aCol)` für den Viewport-Query.

### 4.1 Inkrementelle Faltung

Die Heatmap ist der Start-Screen und darf beim Öffnen nicht rechnen. 500 Fahrten × 1.800 Punkte
sind knapp eine Million Punkte — eine Voll-Aggregation beim Start ist ausgeschlossen.

- **Hinzufügen:** nach `finalizeTrip` und bestätigtem „behalten" wird genau diese eine Fahrt
  eingefaltet und `heatFoldedAt` gesetzt.
- **Nachziehen:** beim Laden werden Fahrten mit `kept = true AND heatFoldedAt IS NULL` gefaltet
  (deckt Migration und verpasste Faltungen ab).
- **Entfernen:** `setKept(false)` auf eine bereits gefaltete Fahrt und `deleteAll()` lösen einen
  vollständigen Neuaufbau aus. Beides ist selten; ein Rückrechnen einzelner Fahrten wäre
  fehleranfälliger als ein Rebuild.
- Faltung und Rebuild laufen in einem Isolate (`compute`), nie auf dem UI-Thread.

## 5. Backend

### 5.1 Schema-Delta

```
trips:       += heat_folded_at (datetime, nullable)

heat_cells:  user_id, level, row, col, lat_sum, lng_sum, n
             PK (user_id, level, row, col)

heat_edges:  user_id, level, month, a_row, a_col, b_row, b_col, count
             PK (user_id, level, month, a_row, a_col, b_row, b_col)
             INDEX (user_id, level, month)
```

`month` ist ein `YYYYMM`-Integer. Er ist der Grund, warum die Cloud filtern kann: ein Zeitraum wird
zu `SUM(count) ... WHERE month BETWEEN ?, ?` statt zu einer Neuaggregation über die
gzip-komprimierten Routen-Blobs. Tagesbuckets wären zu viele Zeilen (täglicher Arbeitsweg über drei
Jahre ≈ 750 Zeilen je Kante), Monatsbuckets rund 36.

`heat_cells` trägt bewusst **keinen** Monat — der Schwerpunkt einer Zelle ist zeitlich stabil.

Daraus folgt: die Filter sind monatsscharf (**Letzte 3 Monate / Letzte 12 Monate / Alles**), kein
freies Datum. Ein tagesgenauer Filter würde das Bucketing sprengen.

### 5.2 Faltung

In `TripController::store()`, wo die Punkte bereits validiert vorliegen — kein zweites Entpacken
des Blobs. `updateOrCreate`-Semantik: wird dieselbe `client_uuid` erneut hochgeladen, muss die alte
Faltung zurückgenommen werden, bevor die neue greift, sonst zählt eine erneut synchronisierte Fahrt
doppelt. Umgesetzt über eine Markierung `trips.heat_folded_at`; bei Re-Upload einer bereits
gefalteten Fahrt werden deren Kanten subtrahiert.

Artisan-Command `heatmap:rebuild [--user=]` baut die Aggregate aus den vorhandenen Blobs neu —
nötig für Bestandsdaten und als Reparaturweg.

### 5.3 Endpoint

`GET /api/heatmap` (auth). Query:

- `range` = `all` | `12m` | `3m` (default `all`)
- `level` = 0 | 1 | 2 (default 0)
- `min_lat`, `min_lng`, `max_lat`, `max_lng` (optional Viewport-Filter)

Antwort:

```json
{
  "range": "all",
  "level": 0,
  "max_count": 214,
  "edges": [
    {"a": [50.9412, 6.9583], "b": [50.9414, 6.9586], "c": 12}
  ]
}
```

Koordinaten werden serverseitig aus `heat_cells` aufgelöst; der Client kennt das Raster für die
Darstellung nicht. `max_count` ist das Maximum über den **gesamten** gewählten Zeitraum und Level,
nicht nur über den Viewport — sonst würden sich die Farben beim Verschieben der Karte ändern.

## 6. App

### 6.1 Struktur

```
lib/heat/heat_grid.dart        reine Rasterung (Spiegel von HeatGrid.php)
lib/heat/heat_map.dart         HeatMap / HeatEdge / HeatFilter (Domain)
lib/heat/heat_source.dart      abstract HeatSource
lib/heat/local_heat_source.dart   Drift-Aggregate, ignoriert den Zeitfilter
lib/heat/cloud_heat_source.dart   GET /heatmap
lib/ui/heatmap_screen.dart     Karte, Legende, Filter-Chips
lib/app/car_connection.dart    abstract CarConnection + Fake
```

`heatSourceProvider` wählt anhand eines vorhandenen Tokens zwischen lokal und Cloud — dasselbe
Kriterium wie beim Sync. Die Filter-Chips sind nur bei aktiver Cloud sichtbar.

### 6.2 Rendering

`FlutterMap` mit OSM-Tiles wie in `trip_detail_screen.dart`. Ein `PolylineLayer` mit einer Polyline
je Kante. Auf `MapEvent` (Zoom/Pan) wird mit ~300 ms Debounce neu geladen; der Provider ist auf
`(level, bbox, filter)` gekeyt. Ohne Debounce würde jeder Pan-Frame einen HTTP-Request auslösen.

Startausschnitt: Bounding-Box aller Kanten, gefallback auf die letzte bekannte Position.

Sollte sich im Profiling Jank zeigen, ist der Ausweg ein `CustomPaint`-Layer, der alle Segmente in
einem Canvas-Durchgang zeichnet, statt tausender Polyline-Widgets. Nicht Teil dieser Spec.

### 6.3 Farbskala

Normierung: `t = log(count) / log(maxCount)`, geklemmt auf `[0, 1]`. Stops:

| t    | Farbe        | Bedeutung        |
|------|--------------|------------------|
| 0.0  | `#4A0E0E`    | dunkelrot, 1×    |
| 0.35 | `#B3261E`    | rot              |
| 0.7  | `#FF7A00`    | orange           |
| 1.0  | `#FFD54A`    | hellgelb, Maximum|

Strichstärke konstant. Eine kompakte Legende („selten → oft") liegt über der Karte; ohne sie ist die
Skala nicht interpretierbar.

### 6.4 Start-Tab und Fahrterkennung

Tab-Reihenfolge neu: **Heatmap, Live, Fahrten, Ranking, Einstellungen**.

- Beim Start: Heatmap — außer `RecorderState.isDriving` ist gesetzt **oder** eine CarPlay-/
  Android-Auto-Verbindung besteht, dann Live.
- Beginnt eine Fahrt bei geöffneter App, springt die App **einmalig** auf Live.
- Endet die Fahrt, springt sie **nicht** zurück. Dem Nutzer die Ansicht unter dem Finger
  wegzuziehen, während er selbst navigiert, wäre störend.

### 6.5 CarConnection

```dart
abstract class CarConnection { Stream<bool> get connected; }
```

- **iOS:** `AVAudioSession.currentRoute.outputs` auf `.carAudio` prüfen, plus Observer auf
  `routeChangeNotification`. Kein CarPlay-Entitlement von Apple nötig — das wäre nur für eine App
  auf dem Autodisplay erforderlich.
- **Android:** `androidx.car.app.connection.CarConnection` (Dependency `androidx.car.app:app`),
  `getType()` als LiveData, verbunden bei `CONNECTION_TYPE_NATIVE` oder `CONNECTION_TYPE_PROJECTION`.
- Fehlt der Kanal oder wirft er, ist die Antwort `false`; die Fahrterkennung greift weiterhin. Die
  Verbindung ist ein *zusätzliches* Signal, nie das einzige.
- Für Tests ein `FakeCarConnection` mit steuerbarem Stream.

## 7. Fehlerbehandlung

- **Keine Fahrten / keine Kanten:** leere Karte mit Hinweis „Noch keine Strecken aufgezeichnet",
  keine Fehlermeldung.
- **Cloud nicht erreichbar / 5xx:** Fallback auf die lokale Quelle, dezenter Hinweis „Offline-Daten".
  Die Heatmap ist der Start-Screen und darf nie in einen Fehlerzustand kippen.
- **401:** Token löschen (wie beim Sync), Quelle wechselt dadurch automatisch auf lokal.
- **Faltung schlägt fehl:** `heatFoldedAt` bleibt `NULL`, die Fahrt wird beim nächsten Laden erneut
  versucht. Kein Datenverlust, kein Doppelzählen.
- **Ortungsrechte fehlen:** betrifft nur neue Aufzeichnungen; bereits vorhandene Heatmap-Daten
  bleiben sichtbar.

## 8. Testing

**Dart — Rasterung (reine Funktionen, gemeinsame Fixtures mit PHP):**
- Zweimal dieselbe Strecke → `count == 2`.
- Zweite Fahrt 15 m versetzt → dieselbe Kante (Raster fängt GPS-Rauschen).
- Zwei parallele Straßen 80 m auseinander → getrennte Kanten (kein Verschmelzen).
- Punktabstand 36 m (Tempo 130) → lückenlose Kantenkette.
- Stillstand (viele Punkte in einer Zelle) → keine Kante.
- GPS-Lücke > 200 m → keine überbrückende Kante.
- Hin- und Rückweg in einer Fahrt → `count == 2`.
- Determinismus: dieselbe Eingabe → identische Schlüssel; Level 0/1/2 konsistent.

**Dart — Persistenz/Quellen:**
- Inkrementelle Faltung: zwei Fahrten nacheinander = eine Faltung beider zusammen.
- `setKept(false)` auf gefaltete Fahrt → Rebuild, Kante verschwindet.
- Migration v2 → v3 mit Bestandsdaten, anschließendes Nachfalten.
- `LocalHeatSource` ignoriert Zeitfilter; `CloudHeatSource` parst die Antwort korrekt.
- Quellenwahl: Token gesetzt → Cloud, sonst lokal; Cloud-Fehler → Fallback lokal.

**Dart — UI:**
- Start ohne Fahrt → Heatmap-Tab aktiv.
- Start während einer Fahrt → Live-Tab aktiv.
- Start bei bestehender Auto-Verbindung ohne `isDriving` → Live-Tab aktiv.
- Fahrtbeginn bei offener App → Sprung auf Live; Fahrtende → kein Rücksprung.
- Filter-Chips nur bei aktiver Cloud sichtbar.

**PHP (Pest):**
- Portierungs-Parität: dieselben Fixtures wie Dart, identische Zellschlüssel und Counts.
- `GET /heatmap` ohne Auth → 401; fremde Nutzerdaten sind nie sichtbar.
- `range`-Filter grenzt über Monatsbuckets korrekt ab.
- Viewport-Filter liefert nur Kanten in der Box, `max_count` bleibt global.
- Re-Upload derselben `client_uuid` → keine Doppelzählung.
- `heatmap:rebuild` erzeugt dasselbe Ergebnis wie die inkrementelle Faltung.

## 9. Bewusst nicht enthalten

- Map-Matching auf echte OSM-Straßen (Abschnitt 2).
- Tagesgenaue Zeitfilter (Abschnitt 5.1).
- Heatmap über fremde/geteilte Fahrten — diese Spec zeigt ausschließlich eigene Daten.
- CarPlay-App auf dem Autodisplay. Die Verbindung wird nur als Signal gelesen; eine eigene
  CarPlay-Oberfläche bräuchte ein Apple-Entitlement und wäre eine eigene Phase.
- `CustomPaint`-Renderpfad (Abschnitt 6.2), falls `PolylineLayer` nicht ausreicht.

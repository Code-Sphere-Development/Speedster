# Speedster

Flutter-App, die aufzeichnet, wie du fährst: Geschwindigkeit, Route und jeden
Kilometer. Die Aufzeichnung startet von selbst, sobald es losgeht — auch über
CarPlay.

Das Laravel-Backend liegt in einem eigenen Repository:
[Code-Sphere-Development/Speedster_Cloud](https://github.com/Code-Sphere-Development/Speedster_Cloud).

## Was die App kann

- **Aufzeichnung ohne Knopfdruck.** Die Fahrterkennung startet bei Bewegung und
  beendet erst, wenn wirklich Schluss ist. Eine bestehende CarPlay-Verbindung
  unterdrückt das Fahrtende — Ampel und Stau sind kein Fahrtende, und eine
  kurz abreißende Verbindung erst recht nicht.
- **Sperrbildschirm und Dynamic Island** zeigen das Tempo während der Fahrt,
  dazu ein Urteil gegen die eigene Gewohnheit auf dieser Strecke: schneller als
  sonst, wie üblich, langsamer. Die App kennt keine Tempolimits und behauptet
  das auch nirgends.
- **Meldung zum Fahrtbeginn** als Gegenprobe, dass die Aufzeichnung
  angesprungen ist — iOS spiegelt sie auf eine gekoppelte Apple Watch,
  solange die Uhr am Handgelenk und das iPhone gesperrt ist. Über CarPlay
  oder Android Auto kommt sie mit Ton: dort schaut man weder auf die Uhr
  noch aufs Display. Abschaltbar in den Einstellungen.
- **Heatmap** aller gefahrenen Strecken, lokal aus den Punkten gefaltet.
- **Bestenliste** weltweit, im eigenen Land, unter Freunden oder nach Fahrzeug,
  jeweils für Woche, Monat oder gesamt.
- **Garage** mit Fahrzeugen aus einem Katalog, geschätztem Tachostand und
  fälligen Wartungen.
- **Widgets** für Homescreen: letzte Fahrt, Gesamtzahlen, eigener Rang,
  Mini-Heatmap.
- **Sicherung** der Fahrten in eine Datei — ohne Cloud liegen sie nur auf dem
  Gerät.

Ohne Cloud-Synchronisierung verlässt keine Fahrt das Gerät. Mit ihr werden die
Fahrten beim Fahrtende hochgeladen; lokal bleiben die letzten zehn als Vorrat
für den Fall ohne Netz.

## Entwicklung

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift-Code
flutter run
```

Nach Änderungen an `lib/data/database.dart` muss `build_runner` laufen. Wer die
Schemaversion hebt, schreibt die zugehörige Migration in
`AppDatabase.migration` — ein Test hält die Zahl fest, damit das eine ohne das
andere auffällt.

### Tests

```bash
flutter test
flutter analyze
```

Der Testlauf erzwingt Deutsch (`test/flutter_test_config.dart`), sonst liefe er
gegen die englische Fassung und deutsche Erwartungen schlügen fehl.

### Sprachen

Texte stehen in `lib/l10n/app_de.arb` und `app_en.arb`; die Klassen darunter
erzeugt `flutter gen-l10n`. `test/l10n/localization_test.dart` prüft, dass beide
Dateien dieselben Schlüssel führen, keinen leeren Text enthalten und dieselben
Platzhalter tragen.

Fehlermeldungen, die auch der Server kennt, sind wörtlich von dort übernommen —
derselbe Fehler soll nicht in zwei Formulierungen auftauchen.

### Screenshots

```bash
flutter test test/screenshots/generate.dart
```

Erzeugt echte Bildschirme der App als PNG, in beiden Sprachen und zwei Größen:
`build/screenshots` für die Landingpage der Cloud, `build/appstore` im
6,9-Zoll-Format (1320 × 2868) für App Store Connect.

Der Generator liegt bewusst in `test/`, aber ohne `_test.dart`-Endung: so
sammelt `flutter test` ihn nicht von selbst ein, während der Analyzer ihn
weiterhin als Testcode behandelt.

Vor dem Hochladen muss der Alphakanal weg — Flutter schreibt RGBA, und App
Store Connect weist Bilder damit zurück, auch wenn sie deckend sind:

```bash
magick bild.png -background black -alpha remove -alpha off bild.png
```

## Oberfläche

Die Formensprache folgt **EasyWallet** (derselbe Entwickler), in den Farben
dieser App statt in Blau:

- **`GradientHeader`** — Verlauf von fast schwarz nach tiefrot, darin der Name
  der App und zwei Kennzahlkarten (`HeaderStat`). Er nennt bewusst den
  App-Namen und nicht den des Reiters: den sagt die Leiste unten bereits.
  Bildschirme, die auf den Stapel gelegt werden, tragen dort ihren Titel und
  einen Zurück-Pfeil — eine `AppBar` gibt es nirgends mehr.
- **`CardSection`** — gruppierte Karte mit Versalüberschrift, Symbol und
  halben Bildpunktlinien zwischen den Zeilen. Ordnet die Fahrten nach Monat,
  die Einstellungen nach Bereich und die Bestenliste als Ganzes.
- Die Karte ist ein `Material` und kein gefärbter `Container`: `ListTile` und
  `InkWell` malen Hintergrund und Wellenanimation auf das nächste `Material`,
  und ein gefärbter Container darüber macht beides unsichtbar.

Das Raster (`lib/app/spacing.dart`) und die Akzentregel gelten unverändert
weiter: Rot markiert Zustand und genau eine Hauptaktion je Bildschirm.

## Aufbau

| Verzeichnis | Inhalt |
|---|---|
| `lib/recording/` | Fahrtaufzeichnung, Puffer, Fahrtende |
| `lib/detection/` | Wann eine Fahrt beginnt und endet |
| `lib/data/` | Drift-Datenbank, Fahrten, Sicherung |
| `lib/heat/` | Rasterung, Faltung und Farbskala der Heatmap |
| `lib/cloud/` | API-Zugriff: Konto, Fahrten, Freunde, Fahrzeuge, Bestenliste |
| `lib/live/` | Live Activity auf dem Sperrbildschirm |
| `lib/notifications/` | Mitteilung zum Fahrtbeginn |
| `lib/widgets/` | Daten für die Homescreen-Widgets |
| `lib/ui/` | Bildschirme |
| `lib/ui/components/` | Gemeinsame Bausteine der Oberfläche |
| `ios/SpeedsterWidgets/` | Widget-Erweiterung und Live Activity (Swift) |

## iOS

- **App Group** `group.de.codesphere.speedster` — darüber lesen Widgets und
  Live Activity die Werte, die die App hineinschreibt.
- **CarPlay** meldet sich über den Kanal `de.codesphere.speedster/car_connection`
  an die Fahrterkennung.
- **`UIFileSharingEnabled`** und **`LSSupportsOpeningDocumentsInPlace`** machen
  den Dokumentenordner in der Dateien-App sichtbar. Ohne beides läge die
  Sicherung an einer Stelle, an die niemand herankommt.
- **`UNUserNotificationCenter.current().delegate`** wird im `AppDelegate`
  gesetzt. Ohne das verwirft iOS eine Mitteilung stillschweigend, solange
  die App im Vordergrund steht — also genau in dem Fall, in dem man die
  Meldung zum Fahrtbeginn zuerst ausprobiert.
- Die Widget-Erweiterung zieht Version und Build über `$(FLUTTER_BUILD_NAME)`
  und `$(FLUTTER_BUILD_NUMBER)` aus derselben Quelle wie die App — Apple weist
  Uploads sonst wegen abweichender Versionsnummern zurück.

`flutter build ios` endet mit Exit-Code 0, auch wenn der Xcode-Build darunter
fehlschlägt. Die Ausgabe zählt, nicht der Exit-Code.

## Parität mit der Cloud

`lib/heat/heat_grid.dart` und `app/Services/HeatGrid.php` in der Cloud sind
zeilengetreue Spiegel. Weichen sie voneinander ab, springt das Kartenbild,
sobald sich jemand an- oder abmeldet.

`test/fixtures/heat_parity.json` und `heat_parity_expected.json` sind der
gemeinsame Vertrag beider Seiten. Ändert sich die Rasterung, reicht es nicht,
eine Seite anzupassen:

1. Referenz neu erzeugen:
   `flutter test test/heat/heat_grid_parity_test.dart --dart-define=REGENERATE_HEAT_FIXTURES=true`
2. Beide Dateien nach `tests/fixtures/` der Cloud kopieren.
3. Dort muss `php artisan test --filter=HeatGridParity` grün sein.

Dasselbe gilt für `lib/heat/heat_palette.dart` und `resources/js/maps.js` in der
Cloud: dieselben Farbstützstellen, dieselbe logarithmische Interpolation. Sonst
sieht dieselbe Fahrt im Web anders heiß aus als in der App.

Auch die Farbwelt ist gespiegelt: `lib/app/theme.dart` ist die Quelle,
`resources/css/app.css` in der Cloud zieht nach.

# Speedster — Design / PRD

**Datum:** 2026-07-25
**Status:** Approved (Design)
**Scope dieser Spec:** MVP (Phase 1) — lokal-only Flutter App. Spätere Phasen als Roadmap.

## 1. Produktvision

Speedster ist eine mobile App (iOS + Android), die Fahrten der Nutzer automatisch trackt und
Geschwindigkeits- und Routenstatistiken liefert. Nutzer entscheiden selbst, ob Daten nur lokal
auf dem Gerät bleiben oder (spätere Phase) in eine Cloud synchronisiert werden. Langfristiges Ziel:
weltweite, landesweite und freundesbezogene Rankings sowie CarPlay/Android-Auto-Automation, damit
nur eigene Fahrten (nicht als Beifahrer) getrackt werden.

Diese Spec beschreibt **nur den MVP (Phase 1)**. Cloud, Rankings, CarPlay sind als Roadmap skizziert
und bekommen jeweils eine eigene Spec.

## 2. Zielplattformen & Stack

- **Framework:** Flutter (ein Codebase, iOS + Android).
- **Sprache:** Dart.
- **MVP:** lokal-only, kein Backend.
- **Spätere Cloud (Phase 2):** optimierte Laravel-Anwendung (REST API, Sanctum Auth).

## 3. MVP-Funktionsumfang (Phase 1)

### 3.1 Automatische Fahrterkennung (Motion-based)
- App erkennt Fahrtbeginn: Geschwindigkeit über Schwelle (z. B. > 10 km/h) für X Sekunden.
- App erkennt Fahrtende: Stillstand (< Schwelle) für Y Sekunden.
- Läuft als Background-Location-Service (iOS: Always/Background Location, Android: Foreground Service).
- Schwellen in Settings konfigurierbar (mit sinnvollen Defaults).

### 3.2 Beifahrer-Schutz (MVP-Brücke)
Auto-Erkennung kann Fahrten als Beifahrer starten. Bis CarPlay-Automation (Phase 3) existiert:
- Nach Fahrtende Prompt: **"Selbst gefahren? Behalten / Verwerfen"**.
- Verworfene Fahrten werden gelöscht (bzw. markiert `kept=false`) und zählen nie in spätere Rankings.
- Optional: globaler "Tracking pausieren"-Schalter.

### 3.3 Statistiken pro Fahrt
- Höchstgeschwindigkeit (max speed)
- Durchschnittsgeschwindigkeit (avg speed)
- Distanz (Haversine-Summe über Track-Punkte)
- Dauer
- Route als Polyline auf Karte (`flutter_map`, OpenStreetMap-Tiles)
- 0–100 km/h Beschleunigungszeit (aus Speed-Verlauf / Accelerometer-Peaks)
- Höhenmeter / Elevation Gain (aus GPS-Altitude)

### 3.4 UI-Screens
- **Live-Screen** (während Fahrt): aktuelle Geschwindigkeit groß, Dauer, Distanz live.
- **Trip-Liste:** alle behaltenen Fahrten, Kurzstats, chronologisch.
- **Trip-Detail:** Karte mit Route, Stat-Kacheln, Speed-Graph.
- **"Fahrer?"-Bestätigung** nach Fahrtende.
- **Settings:** Einheiten (km/h ↔ mph), Detection-Schwellen, Tracking-Pause, Disclaimer/Consent, Daten löschen.
- **Onboarding / Consent** beim ersten Start.

### 3.5 Disclaimer & Datenschutz
- First-Launch Consent: "Verantwortungsvoll fahren, StVO gilt, Nutzung auf eigene Gefahr."
  Hinweis: Auf deutschen Autobahnen teils kein Tempolimit — App fördert kein Rasen.
- GDPR: Im MVP bleiben alle Daten lokal auf dem Gerät. Kein Upload. "Alle Daten löschen" in Settings.

## 4. Architektur (MVP, on-device)

Schichten mit je einer klaren Aufgabe, testbar isoliert:

- **Sensor-Layer** — Wrapper um `geolocator` (Position, Speed, Altitude, Accuracy) und
  `sensors_plus` (Accelerometer). Liefert einen Stream normalisierter Samples. Keine Business-Logik.
- **Trip-Detection** — konsumiert Sample-Stream, entscheidet Fahrt-Start/-Ende via Schwellen +
  Zeitfenster. Emittiert Trip-Lifecycle-Events. Reine Zustandsmaschine, ohne I/O — testbar mit
  Fake-Streams.
- **Trip-Recorder** — bei aktiver Fahrt: puffert TrackPoints, schreibt periodisch in DB.
- **Stats-Engine** — reine Funktionen: nimmt Liste von TrackPoints → berechnet Max/Ø Speed, Distanz,
  Dauer, 0–100-Zeit, Elevation Gain. Deterministisch, keine Abhängigkeiten. Kritischster Testbereich.
- **Persistenz** — `drift` (SQLite). Tabellen `trips`, `track_points`. Repository-Interface, damit
  spätere Cloud-Sync-Schicht dieselbe API nutzen kann.
- **State/UI** — State-Management (Riverpod), Screens siehe 3.4. Karte via `flutter_map`.

Datenfluss: Sensor-Layer → Trip-Detection → (bei Fahrt) Trip-Recorder → DB. Bei Fahrtende:
Stats-Engine rechnet über gespeicherte Punkte → Trip-Row aktualisiert → "Fahrer?"-Prompt → behalten/verwerfen.

## 5. Datenmodell

**Trip**
- id (int, pk)
- startTime, endTime (datetime)
- maxSpeed, avgSpeed (double, m/s intern — Anzeige konvertiert)
- distance (double, meter)
- durationSeconds (int)
- zeroToHundredSeconds (double, nullable — nur wenn erreicht)
- elevationGain (double, meter)
- kept (bool — false = als Beifahrer verworfen / soft-deleted)

**TrackPoint**
- id (int, pk)
- tripId (fk → Trip)
- lat, lng (double)
- speed (double, m/s)
- altitude (double, meter)
- accuracy (double, meter)
- timestamp (datetime)

Interne Speicherung SI-Einheiten (m/s, meter). Umrechnung in km/h/mph nur in der UI-Schicht.

## 6. Fehlerbehandlung / Edge Cases

- **Location-Permission verweigert:** klare Erklärung + Deep-Link in Settings. Ohne Permission kein Tracking.
- **GPS-Drift / Ausreißer:** Samples mit schlechter Accuracy (> Schwelle) verwerfen; Speed-Ausreißer
  gegen physikalisches Maximum klemmen, bevor sie in Stats fließen.
- **Kurze Stopps (Ampel):** Fahrtende erst nach Y Sekunden Stillstand → verhindert Zerstückelung.
- **App-Kill / Crash während Fahrt:** TrackPoints periodisch persistiert → Trip aus DB rekonstruierbar.
- **Sehr kurze Fahrten:** Mindestdistanz/-dauer, sonst nicht als Trip speichern.

## 7. Testing

- **Stats-Engine:** Unit-Tests mit bekannten TrackPoint-Sequenzen → erwartete Distanz/Speed/0-100/Elevation.
- **Trip-Detection:** Unit-Tests mit Fake-Sample-Streams (Start-, Stopp-, Ampel-, Beifahrer-Szenarien).
- **Persistenz:** Repository-Tests gegen In-Memory-SQLite.
- **Widget-Tests:** Kern-Screens (Trip-Liste, Detail, Consent) rendern mit Mock-Daten.

## 8. Roadmap (spätere Phasen — je eigene Spec)

- **Phase 2 — Cloud:** Laravel-Backend (REST, Sanctum), Accounts, opt-in Sync, lokal↔cloud Toggle.
  Repository-Abstraktion aus Phase 1 wird um Remote-Impl erweitert.
- **Phase 3 — Rankings + CarPlay:** Welt-/Land-/Freundes-Rankings (nur `kept`-Fahrten, opt-in).
  CarPlay + Android Auto Automation → Tracking startet nur bei eigener Fahrt (ersetzt Beifahrer-Prompt).
- **Phase 4 — Social & Monetarisierung:** Freundessystem; Monetarisierungsmodell (offen —
  z. B. Free lokal + Premium Cloud/Ranking).

## 9. Offene Fragen

- Monetarisierungsmodell (Phase 4).
- Karten-Tiles: OpenStreetMap (gratis, Attribution) vs. Mapbox (Key/Kosten) — MVP: OSM.
- Genaue Detection-Schwellen — empirisch beim Testen tunen.

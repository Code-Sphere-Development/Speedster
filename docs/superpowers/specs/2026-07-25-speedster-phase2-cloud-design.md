# Speedster Phase 2 — Cloud Sync & Accounts (Design / PRD)

**Datum:** 2026-07-25
**Status:** Approved (Design)
**Scope:** Phase 2 — optionale Cloud. Optimierte Laravel-API (Backend) + Flutter-Sync-Client
(App). Push-only Backup + Basis für Phase-3-Rankings. Rankings selbst = Phase 3 (eigene Spec).

## 1. Ziel

Nutzer können optional ihre lokal aufgezeichneten Fahrten in eine Cloud hochladen — als Backup
und als Datengrundlage für spätere Rankings. Lokal-only bleibt Default (Phase 1). Cloud ist opt-in
pro Nutzer über einen Schalter in den Einstellungen. Datenschutz: nichts verlässt das Gerät, bis
der Nutzer Cloud aktiviert und zustimmt.

## 2. Entscheidungen (aus Brainstorming)

- **Auth:** E-Mail + Passwort **und** Social Login (Sign in with Apple, Google). Laravel Sanctum
  als Token-Aussteller für die App.
- **Sync-Umfang:** Volle Fahrten inkl. aller TrackPoints.
- **Sync-Richtung:** Push-only. App lädt lokale Trips hoch; Cloud = Backup + Ranking-Quelle. Kein
  Download/2-Wege-Sync in Phase 2 (kommt ggf. Phase 4).
- **DB:** MySQL. **Empfehlung umgesetzt:** TrackPoints werden **nicht** als Zeile-pro-Punkt
  gespeichert (würde Millionen Rows erzeugen), sondern als **gzip-komprimierter JSON-Blob pro
  Trip** (`route` LONGBLOB). Volle Fidelity, minimaler Speicher, ideal für Push-only-Backup.
  Aggregierte Stats liegen als indizierte Spalten am Trip → schnelle Ranking-Queries ohne die
  Rohpunkte anzufassen. Kein Postgres/PostGIS nötig, bis Phase-3 Geo-Umkreis-Rankings dazukommen.
- **Hosting:** übernimmt der Auftraggeber. Spec + Code liefern eine deploybare Laravel-App (MySQL,
  `.env`-konfigurierbar), kein Deployment-Setup.

## 3. Architektur (Überblick)

```
Flutter App (Phase 1)                    Laravel API (Phase 2)
┌───────────────────────┐   HTTPS/JSON   ┌────────────────────────┐
│ TripRepository (iface) │───────────────▶│ Sanctum Auth           │
│  ├ DriftTripRepository │  Bearer token  │ /api/auth/*            │
│  └ CloudSyncService    │◀──────────────▶│ /api/trips  (push)     │
│     (upload queue)     │                │ /api/me, /api/account  │
│ AuthController (app)   │                │ MySQL: users, trips    │
│ Settings: cloud toggle │                │ (route = gzip blob)    │
└───────────────────────┘                └────────────────────────┘
```

Die Phase-1-`TripRepository`-Abstraktion bleibt Quelle der Wahrheit lokal. Ein neuer
`CloudSyncService` (App) beobachtet neue/abgeschlossene `kept`-Trips und lädt sie hoch, wenn Cloud
aktiv + eingeloggt. Der Server ist zustandslos bzgl. App-Logik; er validiert, dedupliziert (per
`client_uuid`) und speichert.

## 4. Backend — Laravel API

### 4.1 Auth (Sanctum)
- `POST /api/auth/register` — {name, email, password} → User + Token.
- `POST /api/auth/login` — {email, password} → Token.
- `POST /api/auth/social` — {provider: apple|google, id_token} → verifiziert das Provider-Token
  serverseitig, erstellt/findet User per verifizierter E-Mail/Provider-ID → Token.
- `POST /api/auth/logout` — (auth) widerruft aktuelles Token.
- `GET  /api/me` — (auth) aktueller User (id, name, email, country).
- Token: Sanctum Personal Access Token, im App-Secure-Storage abgelegt.

### 4.2 Trip-Upload (Push, idempotent)
- `POST /api/trips` — (auth) lädt einen Trip hoch. Body:
  ```json
  {
    "client_uuid": "uuid-v4",          // von der App erzeugt, pro Trip stabil
    "start_time": "2026-07-25T10:00:00Z",
    "end_time":   "2026-07-25T10:30:00Z",
    "max_speed": 30.5, "avg_speed": 12.1, "distance": 15400,
    "duration_seconds": 1800, "zero_to_hundred_seconds": 8.2,
    "elevation_gain": 120,
    "points": [ {"lat":..,"lng":..,"speed":..,"altitude":..,"accuracy":..,"t":".."}, ... ]
  }
  ```
  Server komprimiert `points` → gzip-JSON in `trips.route`. **Idempotenz:** `unique(user_id,
  client_uuid)` → erneuter Upload gleicher UUID = Upsert (kein Duplikat). Erlaubt sicheres Retry.
- `GET  /api/trips` — (auth) Liste eigener Trips (Stats, ohne route-Blob, paginiert).
- `GET  /api/trips/{client_uuid}` — (auth) ein Trip inkl. dekomprimierter Punkte.
- `DELETE /api/trips/{client_uuid}` — (auth) löscht eigenen Trip.

### 4.3 Account / GDPR
- `DELETE /api/account` — (auth) löscht User + alle Trips (Cascade). Recht auf Löschung.
- `GET  /api/account/export` — (auth) vollständiger JSON-Export aller eigenen Daten. Recht auf
  Datenübertragbarkeit.

### 4.4 Datenmodell (MySQL)

**users**
- id, name, email (unique), password (nullable — bei reinem Social-Login), country (nullable,
  ISO-2, für spätere Land-Rankings), provider (nullable: apple|google|null), provider_id
  (nullable), email_verified_at, timestamps.

**trips**
- id, user_id (fk, cascade), client_uuid (char36), start_time, end_time,
- max_speed, avg_speed, distance, elevation_gain (double), duration_seconds (int),
  zero_to_hundred_seconds (double nullable),
- route (LONGBLOB — gzip(JSON(points))),
- point_count (int), timestamps.
- **Indizes:** `unique(user_id, client_uuid)`; `index(max_speed)`, `index(distance)`,
  `index(duration_seconds)` (Ranking-Queries Phase 3); `index(user_id)`.

Stats liegen redundant als Spalten (nicht aus dem Blob berechnet) → Ranking-Aggregationen ohne
Dekompression.

### 4.5 Querschnitt
- **Validierung:** FormRequests; Speed/Distanz gegen physikalische Obergrenzen klemmen
  (Anti-Cheat-Basis: unrealistische Werte ablehnen — z. B. max_speed > 150 m/s = 540 km/h).
- **Rate Limiting:** `throttle` auf Auth (Brute-Force) und Upload.
- **Auth-Middleware:** alle `/api/trips|me|account` hinter `auth:sanctum`.
- **Fehlerformat:** einheitliches JSON `{ "message": ..., "errors": {...} }`.

## 5. App-Client (Flutter)

- **CloudSyncService** — beobachtet `kept`-Trips ohne `synced_at`. Bei Cloud aktiv + Token
  vorhanden: sammelt Punkte via `pointsFor`, `POST /api/trips`, markiert lokal `synced_at`.
  Retry mit Backoff; idempotent dank `client_uuid`.
- **Lokales Schema-Delta:** `trips`-Tabelle bekommt `client_uuid` (uuid v4 bei Trip-Erstellung)
  und `synced_at` (nullable). Migration in drift (schemaVersion 2).
- **Auth-UI:** Login/Registrierung + „Mit Apple/Google anmelden". Token in
  `flutter_secure_storage`.
- **Settings:** Schalter „Cloud-Sync aktivieren" (mit Consent-Text zum Upload). Aus = Phase-1-
  Verhalten (nichts verlässt das Gerät). „Account löschen" ruft `DELETE /api/account`.
- **HTTP:** `dio` mit Auth-Interceptor (Bearer), Basis-URL aus Build-Config.

## 6. Fehlerbehandlung / Edge Cases

- **Offline:** Upload schlägt fehl → Trip bleibt `synced_at = null`, wird beim nächsten Online-
  Zyklus erneut versucht.
- **Token abgelaufen/ungültig (401):** App löscht Token, fordert erneuten Login, pausiert Sync.
- **Doppel-Upload / Retry:** durch `unique(user_id, client_uuid)` serverseitig idempotent.
- **Großer Trip:** Punkte gzip-komprimiert übertragen (Request-Body gzip) + serverseitig als Blob.
- **Social-Token-Fälschung:** Provider-`id_token` serverseitig gegen Apple/Google-Keys verifizieren,
  nie dem Client vertrauen.
- **Cheating:** unrealistische Stats bei Validierung ablehnen; Phase 3 verschärft (Plausibilität
  Distanz↔Dauer↔Speed).

## 7. Testing

- **Backend (Pest/PHPUnit Feature-Tests):** Register/Login/Social, Upload (inkl. Idempotenz bei
  doppeltem `client_uuid`), Liste/Detail/Delete, Account-Delete-Cascade, Auth-Guard (401 ohne
  Token), Validierung (unrealistische Werte abgelehnt). MySQL-Test-DB oder SQLite-in-memory.
- **App:** `CloudSyncService`-Unit-Tests mit gemocktem HTTP-Client (Upload-Erfolg markiert
  `synced_at`; 401 pausiert; Retry nach Fehler). Auth-Repository-Tests mit Fake-Backend.

## 8. Roadmap-Anschluss

- **Phase 3 — Rankings + CarPlay:** Ranking-Endpunkte (`/api/rankings/{scope}`) über die
  indizierten Stat-Spalten (welt/land via `users.country`/freunde). CarPlay-Automation ersetzt den
  Beifahrer-Prompt. Freundessystem (Phase 4-nah).
- **Phase 4 — 2-Wege-Sync/Social:** Download auf Zweitgerät, Freundes-Feed, Monetarisierung.

## 9. Offene Fragen / Annahmen

- Basis-URL/Env liefert der Auftraggeber beim Hosting.
- `country` wird aus Geräte-Locale vorbelegt, in Settings änderbar (für Land-Ranking Phase 3).
- Request-Body-Gzip abhängig von Server-Config; Fallback = unkomprimierter JSON-Body.

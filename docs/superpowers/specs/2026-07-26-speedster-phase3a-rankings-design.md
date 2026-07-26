# Speedster Phase 3a — Rankings (Design / PRD)

**Datum:** 2026-07-26
**Status:** Approved (Design)
**Scope:** Welt- und Land-Rankings über die in Phase 2 hochgeladenen Fahrten. Freundes-Rankings
und CarPlay bleiben spätere Phasen (3b / 3c) mit eigener Spec.

## 1. Ziel

Nutzer sehen, wo sie im weltweiten und landesweiten Vergleich stehen — nach Höchstgeschwindigkeit,
gefahrener Gesamtdistanz, Anzahl Fahrten und bester 0–100-Zeit. Basis sind die bereits als
indizierte Spalten gespeicherten Fahrt-Stats (kein Zugriff auf die Roh-GPS-Blobs).

## 2. Entscheidungen / Annahmen

- **Scopes:** `world`, `country` (aus `users.country`). Freunde deferred.
- **Metriken:** `max_speed` (Max), `total_distance` (Summe), `trip_count` (Anzahl),
  `best_zero_to_hundred` (Minimum, kleiner = besser).
- **Privacy:** neue Spalten `users.display_name` (Anzeigename, default = `name`) und
  `users.ranking_opt_in` (bool, default true). Wer `ranking_opt_in=false` setzt, taucht in keinem
  Ranking auf (weder gelistet noch mit eigenem Rang).
- **Datenbasis:** alle hochgeladenen Trips eines Nutzers (verworfene Beifahrer-Fahrten werden nie
  hochgeladen, sind also automatisch ausgeschlossen).
- **Identität:** Rankings zeigen `display_name` + `country`, niemals E-Mail.

## 3. Backend

### 3.1 Schema-Delta
`users` += `display_name` (string, nullable → fällt auf `name` zurück), `ranking_opt_in`
(boolean, default true).

### 3.2 Endpoint
`GET /api/rankings` (auth). Query:
- `scope` = `world` | `country` (default `world`)
- `metric` = `max_speed` | `total_distance` | `trip_count` | `best_zero_to_hundred`
  (default `max_speed`)
- `limit` = 1..100 (default 50)

Antwort:
```json
{
  "scope": "world", "metric": "max_speed",
  "entries": [ {"rank":1, "display_name":"Ada", "country":"DE", "value":54.2}, ... ],
  "me": {"rank":42, "value":30.1}   // null wenn opt-out oder keine Fahrten
}
```

Aggregation je Nutzer über `trips`, gejoint auf `users` mit `ranking_opt_in = true`. `country`-Scope
filtert auf das Land des aufrufenden Nutzers. Sortierung: Metrik desc (bei
`best_zero_to_hundred` asc, NULLs raus). Rang des Aufrufers per Zählung besserer Aggregate.

### 3.3 Performance
Aggregation nutzt die vorhandenen Indizes (`max_speed`, `distance`, `duration_seconds`). Für den
MVP genügt eine Live-Query mit `GROUP BY user_id`; bei Wachstum kann eine materialisierte
`user_stats`-Tabelle folgen (nicht Teil dieser Spec).

## 4. App

- **RankingScreen** (neuer Tab „Ranking"): Scope-Umschalter (Welt/Land), Metrik-Auswahl
  (Chips/Dropdown), Liste mit Rang, Name, Land, formatiertem Wert; eigener Rang oben angeheftet.
  Nur sichtbar/aktiv wenn Cloud aktiviert + eingeloggt; sonst Hinweis „Cloud aktivieren für
  Rankings".
- **RankingRepository** — `Future<RankingBoard> fetch(scope, metric)` via dio.
- Werte formatiert über die bestehenden `SpeedFormat`/`Formatters`.

## 5. Fehlerbehandlung

- Nicht eingeloggt / Cloud aus → Screen zeigt Hinweis, kein Call.
- 401 → Token löschen, Login anstoßen (wie Sync).
- Nutzer ohne Land → erscheint im Welt-Ranking, im Land-Ranking nur wenn `country` gesetzt.
- Opt-out → `me` = null, Nutzer nicht in `entries`.

## 6. Testing

- **Backend (Pest):** Ranking-Sortierung je Metrik; `country`-Scope filtert korrekt; opt-out
  ausgeschlossen; `me`-Rang korrekt; auth erforderlich (401).
- **App:** `RankingRepository` mit gemocktem dio (parst Board); `RankingScreen` Widget-Test
  (rendert Einträge, Scope-Umschalter) mit überschriebenem Repository.

## 7. Roadmap-Anschluss

- **Phase 3b — Freunde:** Freundschaftssystem (`friendships`), Scope `friends`.
- **Phase 3c — CarPlay / Android Auto:** Automation-Trigger ersetzt Beifahrer-Prompt.
- Anti-Cheat verschärfen (Plausibilität Distanz↔Dauer↔Speed) bevor Rankings öffentlich beworben
  werden.

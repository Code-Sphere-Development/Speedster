# Speedster MVP — On-Device QA Checklist

Simulators lack real GPS/motion. Run on a real iPhone and Android phone:
`flutter run --release`.

## Walkthrough

- [ ] First launch shows Consent screen; "Akzeptieren" proceeds to the tab shell.
- [ ] Location permission prompt appears; grant "While Using / Always".
- [ ] Deny permission once → tracking does not start, no crash.
- [ ] Live tab shows "Bereit" when idle.
- [ ] Start driving → after ~5 s sustained motion the Live speed appears and roughly
      matches the car speedometer.
- [ ] Brief stop at a red light (< 45 s) does NOT end the trip.
- [ ] Park and wait > 45 s → trip ends, "Selbst gefahren?" prompt appears.
- [ ] "Behalten" → trip shows in Fahrten list.
- [ ] "Verwerfen" → trip does NOT appear in Fahrten list.
- [ ] Trip detail shows the route polyline on the map and correct-looking stats
      (max/avg speed, distance, duration, 0–100 if reached, elevation).
- [ ] Settings: toggle km/h ↔ mph → all speeds/distances update.
- [ ] Settings: "Tracking pausieren" → no new trips auto-start.
- [ ] Settings: "Alle Daten löschen" (confirm) → Fahrten list is empty.
- [ ] Background: lock phone while driving → trip keeps recording (iOS Always +
      Android foreground service).

## Threshold tuning

Record real-world behavior and adjust `DetectorConfig` defaults in
`lib/detection/trip_detector.dart` if needed:

- `startSpeed` / `startWindow`: too many false starts (walking)? raise.
- `stopWindow`: trips split at long lights? raise. Trips linger after parking? lower.
- `minAccuracy`: urban canyon drift? tighten.

## Known follow-ups (post-MVP)

- Live tab: add live distance + elapsed duration (needs richer `RecorderState`).
- Map tiles use public OSM servers (usage-policy warning) — move to a proper tile
  provider (Mapbox/self-hosted) before wide release.
- Android foreground-service notification wiring for reliable background capture.

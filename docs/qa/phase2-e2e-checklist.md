# Speedster Phase 2 — Cloud E2E Checklist

Verifies the full loop: app ↔ Laravel backend ↔ MySQL. Backend hosting is provided
separately; this checklist assumes a reachable API instance.

## Backend bring-up

- [ ] Configure `backend/.env` with MySQL credentials (`DB_CONNECTION=mysql`, host, db, user, pass).
- [ ] `cd backend && php artisan migrate` — all migrations run against MySQL.
- [ ] `php artisan serve` (or the real host) exposes the API.
- [ ] `./vendor/bin/pest` → 26 passing (auth, social, upload idempotency, read, account, throttle).
- [ ] Set `GOOGLE_CLIENT_ID` / `APPLE_CLIENT_ID` in `.env` before enabling social login in prod
      (the verifier fails closed without them).

## App against the backend

Run: `flutter run --release --dart-define=API_BASE_URL=http://<host>:8000`

- [ ] Accept consent → tab shell.
- [ ] Settings → "Cloud-Sync aktivieren" while logged out → Auth screen opens.
- [ ] Register a new account → returns to settings, cloud switch stays on.
- [ ] Record a trip → confirm "Behalten" in the driver prompt.
- [ ] The kept trip uploads: `GET /api/trips` (with the token) lists it; `point_count` > 0.
- [ ] Re-trigger sync (toggle cloud off/on) → no duplicate on the server (idempotent client_uuid).
- [ ] `GET /api/trips/{client_uuid}` returns the decoded route points.
- [ ] `GET /api/account/export` returns user + trips with points.
- [ ] "Cloud-Account löschen" → `DELETE /api/account`; verify user + trips gone from MySQL.
- [ ] Disable cloud → new trips stay local only (nothing hits the API).

## Known follow-ups (post-Phase-2)

- **Social login is UI-stubbed.** Buttons show "folgt in Kürze". Wiring real Apple/Google
  sign-in needs native SDKs (`sign_in_with_apple`, `google_sign_in`) to obtain the `id_token`,
  then call `AuthRepository.loginSocial(provider, idToken)`. The backend verifier is ready.
- **Background sync.** `syncOnce()` currently runs after a kept trip and when enabling cloud.
  A periodic/background trigger (e.g. on app resume or WorkManager) is a nice follow-up.
- **Two-way sync / multi-device** is out of scope (Phase 4).
- Request-body gzip for very large trips depends on server config; JSON body is the default.

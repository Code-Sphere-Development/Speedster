# Speedster Phase 2 — Cloud Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Laravel push-only cloud backend (auth + trip upload + GDPR) and the Flutter sync client so a user can optionally back up trips to the cloud.

**Architecture:** A new `backend/` Laravel 11 app exposes a Sanctum-guarded JSON API. Trips upload idempotently (client-generated UUID, `unique(user_id, client_uuid)` upsert). All GPS points travel in the request and are stored as one gzip-compressed JSON blob per trip; aggregated stats live as indexed columns for future ranking queries. On the app side, a `CloudSyncService` watches unsynced `kept` trips and pushes them; local drift schema gains `client_uuid` + `synced_at`.

**Tech Stack:** Backend — Laravel 11, Sanctum, MySQL (SQLite in-memory for tests), Pest. App — Flutter, dio, flutter_secure_storage, uuid.

## Global Constraints

- Backend lives in `backend/` (sibling of the Flutter `lib/`); do not mix into the Flutter package.
- Laravel 11, PHP `>=8.2`. Tests use SQLite in-memory (`:memory:`) so no MySQL needed in CI.
- All `/api/trips`, `/api/me`, `/api/account*` routes sit behind `auth:sanctum`.
- Trip idempotency key is `(user_id, client_uuid)`; re-upload = upsert, never duplicate.
- GPS points are stored gzip-compressed (`gzencode(json_encode(points))`) in `trips.route` (LONGBLOB); stats are stored as their own columns, never derived from the blob at query time.
- Anti-cheat floor: reject `max_speed > 150` (m/s) or negative distances/durations at validation.
- Never trust a social `id_token` from the client — verify it server-side against the provider JWKS.
- App stores the Sanctum token only in `flutter_secure_storage`.
- Commit after every task with a `feat:`/`test:`/`chore:` prefixed message.

---

### Task 1: Scaffold Laravel backend + Sanctum + Pest

**Files:**
- Create: `backend/` (Laravel skeleton)
- Modify: `backend/phpunit.xml` (SQLite in-memory), `backend/.gitignore`
- Modify: root `.gitignore` (ignore `backend/vendor`, `backend/.env`)

- [ ] **Step 1: Create the app.**

```bash
cd /Users/colilg/PhpstormProjects/Speedster
composer create-project laravel/laravel backend
cd backend
composer require laravel/sanctum
php artisan install:api
composer require --dev pestphp/pest pestphp/pest-plugin-laravel
./vendor/bin/pest --init
```

- [ ] **Step 2: Point tests at in-memory SQLite.** In `backend/phpunit.xml`, uncomment/set:

```xml
<env name="DB_CONNECTION" value="sqlite"/>
<env name="DB_DATABASE" value=":memory:"/>
```

- [ ] **Step 3: Verify default tests pass.**

Run: `cd backend && ./vendor/bin/pest`
Expected: PASS (default example tests).

- [ ] **Step 4: Commit.**

```bash
cd /Users/colilg/PhpstormProjects/Speedster
git add backend .gitignore
git commit -m "chore: scaffold Laravel backend with Sanctum and Pest"
```

---

### Task 2: User schema for email + social auth

**Files:**
- Create: `backend/database/migrations/*_extend_users_for_speedster.php`
- Modify: `backend/app/Models/User.php`

**Interfaces:**
- Produces: `users` gains `country` (nullable string 2), `provider` (nullable), `provider_id` (nullable), and `password` becomes nullable (pure social users). `User` model `$fillable` includes these.

- [ ] **Step 1: Write a migration** adding the columns and making `password` nullable.

```php
Schema::table('users', function (Blueprint $t) {
    $t->string('country', 2)->nullable();
    $t->string('provider')->nullable();
    $t->string('provider_id')->nullable();
});
// password nullable via a second Schema::table change() (requires doctrine/dbal on MySQL;
// on SQLite tests the column is recreated). For portability, set password default '' in model.
```

- [ ] **Step 2: Add columns to `User::$fillable`** (`name, email, password, country, provider, provider_id`).

- [ ] **Step 3: Run migrations against SQLite test DB in a throwaway check.**

Run: `cd backend && php artisan migrate --env=testing`
Expected: migrations run without error.

- [ ] **Step 4: Commit.**

```bash
git add backend
git commit -m "feat: extend users table for social + country"
```

---

### Task 3: Register + login (email/password)

**Files:**
- Create: `backend/app/Http/Controllers/Api/AuthController.php`
- Create: `backend/routes/api.php` entries
- Test: `backend/tests/Feature/AuthTest.php`

**Interfaces:**
- Produces:
  - `POST /api/auth/register` {name,email,password} → 201 `{token, user}`
  - `POST /api/auth/login` {email,password} → 200 `{token, user}`; wrong creds → 422.
  - Token via `$user->createToken('app')->plainTextToken`.

- [ ] **Step 1: Write the failing feature test.**

```php
// backend/tests/Feature/AuthTest.php
it('registers a user and returns a token', function () {
    $res = $this->postJson('/api/auth/register', [
        'name' => 'Ada', 'email' => 'ada@example.com', 'password' => 'secret12',
    ]);
    $res->assertCreated()->assertJsonStructure(['token', 'user' => ['id', 'email']]);
    $this->assertDatabaseHas('users', ['email' => 'ada@example.com']);
});

it('logs in with valid credentials', function () {
    \App\Models\User::factory()->create([
        'email' => 'ada@example.com', 'password' => bcrypt('secret12'),
    ]);
    $this->postJson('/api/auth/login', ['email' => 'ada@example.com', 'password' => 'secret12'])
        ->assertOk()->assertJsonStructure(['token']);
});

it('rejects bad credentials', function () {
    $this->postJson('/api/auth/login', ['email' => 'x@y.z', 'password' => 'nope'])
        ->assertStatus(422);
});
```

- [ ] **Step 2: Run to verify failure.**

Run: `cd backend && ./vendor/bin/pest --filter=AuthTest`
Expected: FAIL (routes 404).

- [ ] **Step 3: Implement `AuthController@register` and `@login`** with FormRequest-style inline validation, `Hash::make`, token issuance, and register routes in `routes/api.php`.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: email register and login"
```

---

### Task 4: Logout + me (auth guard)

**Files:**
- Modify: `backend/app/Http/Controllers/Api/AuthController.php`
- Modify: `backend/routes/api.php`
- Test: `backend/tests/Feature/MeTest.php`

**Interfaces:**
- Produces: `GET /api/me` (auth) → `{id,name,email,country}`; `POST /api/auth/logout` (auth) revokes current token; unauthenticated → 401.

- [ ] **Step 1: Write failing tests.**

```php
it('returns the authenticated user', function () {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user, 'sanctum')->getJson('/api/me')
        ->assertOk()->assertJsonPath('email', $user->email);
});

it('blocks /api/me without a token', function () {
    $this->getJson('/api/me')->assertStatus(401);
});
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `@me`, `@logout`, and wrap routes in `Route::middleware('auth:sanctum')`.**

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: me and logout endpoints"
```

---

### Task 5: Social login (Apple/Google) with verifiable token

**Files:**
- Create: `backend/app/Services/SocialTokenVerifier.php` (interface + real impl)
- Create: `backend/app/Services/FakeSocialTokenVerifier.php` (test double, bound in tests)
- Modify: `backend/app/Http/Controllers/Api/AuthController.php`
- Test: `backend/tests/Feature/SocialAuthTest.php`

**Interfaces:**
- Produces:
  - `interface SocialTokenVerifier { public function verify(string $provider, string $idToken): ?SocialIdentity; }`
  - `class SocialIdentity { public string $providerId; public string $email; public ?string $name; }`
  - `POST /api/auth/social` {provider, id_token} → finds/creates user by (`provider`,`provider_id`) or verified email → `{token, user}`. Invalid token → 422.
  - In tests, the container binds `SocialTokenVerifier` to `FakeSocialTokenVerifier` returning a fixed identity for `id_token = 'valid'`, null otherwise.

- [ ] **Step 1: Write failing tests.**

```php
beforeEach(function () {
    $this->app->bind(\App\Services\SocialTokenVerifier::class, \App\Services\FakeSocialTokenVerifier::class);
});

it('creates a user from a valid social token', function () {
    $this->postJson('/api/auth/social', ['provider' => 'google', 'id_token' => 'valid'])
        ->assertOk()->assertJsonStructure(['token', 'user']);
    $this->assertDatabaseHas('users', ['provider' => 'google']);
});

it('rejects an invalid social token', function () {
    $this->postJson('/api/auth/social', ['provider' => 'google', 'id_token' => 'bad'])
        ->assertStatus(422);
});
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement** the interface, `FakeSocialTokenVerifier` (returns a `SocialIdentity` for `'valid'`), a real JWKS-based verifier (fetch provider public keys, verify signature+aud+exp — real impl, guarded behind the interface), `AuthController@social`, and the route.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: social login with token verification"
```

---

### Task 6: Trips migration + model

**Files:**
- Create: `backend/database/migrations/*_create_trips_table.php`
- Create: `backend/app/Models/Trip.php`
- Create: `backend/database/factories/TripFactory.php`
- Test: `backend/tests/Unit/TripModelTest.php`

**Interfaces:**
- Produces: `trips` table per spec §4.4 (stats columns + `route` binary + `client_uuid` + `point_count`, `unique(user_id, client_uuid)`, indexes on `max_speed`, `distance`, `duration_seconds`). `Trip` model with `$fillable`, `user()` relation, `route` cast handled manually (binary).

- [ ] **Step 1: Write failing model test.**

```php
it('stores and retrieves a trip for a user', function () {
    $user = \App\Models\User::factory()->create();
    $trip = \App\Models\Trip::factory()->for($user)->create(['max_speed' => 30.0]);
    expect($trip->user->id)->toBe($user->id);
    expect($trip->max_speed)->toBe(30.0);
});
```

- [ ] **Step 2: Run to verify failure.** → FAIL (no table/model).

- [ ] **Step 3: Write the migration, `Trip` model, and `TripFactory`.**

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: trips table and model"
```

---

### Task 7: Trip upload (idempotent, gzip, anti-cheat validation)

**Files:**
- Create: `backend/app/Http/Controllers/Api/TripController.php`
- Create: `backend/app/Http/Requests/StoreTripRequest.php`
- Modify: `backend/routes/api.php`
- Test: `backend/tests/Feature/TripUploadTest.php`

**Interfaces:**
- Consumes: auth from Task 4, `Trip` from Task 6.
- Produces: `POST /api/trips` (auth) upserts on `(user_id, client_uuid)`, gzips `points` into `route`, sets `point_count`, stores stats; returns 201 (new) / 200 (updated). Validation rejects `max_speed>150`, negatives, missing fields (422).

- [ ] **Step 1: Write failing tests.**

```php
function payload(array $over = []): array {
    return array_merge([
        'client_uuid' => (string) \Illuminate\Support\Str::uuid(),
        'start_time' => '2026-07-25T10:00:00Z', 'end_time' => '2026-07-25T10:30:00Z',
        'max_speed' => 30.0, 'avg_speed' => 12.0, 'distance' => 15400.0,
        'duration_seconds' => 1800, 'zero_to_hundred_seconds' => 8.2, 'elevation_gain' => 120.0,
        'points' => [['lat'=>50,'lng'=>6,'speed'=>10,'altitude'=>100,'accuracy'=>3,'t'=>'2026-07-25T10:00:00Z']],
    ], $over);
}

it('uploads a trip', function () {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload())
        ->assertCreated();
    expect(\App\Models\Trip::count())->toBe(1);
});

it('is idempotent on client_uuid', function () {
    $user = \App\Models\User::factory()->create();
    $uuid = (string) \Illuminate\Support\Str::uuid();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload(['client_uuid'=>$uuid]));
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload(['client_uuid'=>$uuid, 'max_speed'=>40.0]));
    expect(\App\Models\Trip::count())->toBe(1);
    expect(\App\Models\Trip::first()->max_speed)->toBe(40.0);
});

it('rejects unrealistic max_speed', function () {
    $user = \App\Models\User::factory()->create();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload(['max_speed'=>999]))
        ->assertStatus(422);
});

it('requires auth', function () {
    $this->postJson('/api/trips', payload())->assertStatus(401);
});
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `StoreTripRequest`** (rules incl. `max_speed` ≤ 150, `distance`/`duration_seconds` ≥ 0, `points` array) and `TripController@store` using `Trip::updateOrCreate(['user_id'=>.., 'client_uuid'=>..], [...stats, 'route'=>gzencode(json_encode($points)), 'point_count'=>count($points)])`, returning 201/200.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: idempotent trip upload with gzip storage"
```

---

### Task 8: Trip list, detail (decompress), delete

**Files:**
- Modify: `backend/app/Http/Controllers/Api/TripController.php`
- Modify: `backend/routes/api.php`
- Test: `backend/tests/Feature/TripReadTest.php`

**Interfaces:**
- Produces: `GET /api/trips` (auth, own only, paginated, stats without route); `GET /api/trips/{client_uuid}` (own, returns decompressed `points`); `DELETE /api/trips/{client_uuid}` (own).

- [ ] **Step 1: Write failing tests** covering: list returns only the caller's trips; detail returns decoded points; a user cannot fetch another user's trip (404); delete removes it.

```php
it('lists only my trips', function () {
    $me = \App\Models\User::factory()->create();
    \App\Models\Trip::factory()->for($me)->count(2)->create();
    \App\Models\Trip::factory()->for(\App\Models\User::factory())->create();
    $this->actingAs($me, 'sanctum')->getJson('/api/trips')
        ->assertOk()->assertJsonCount(2, 'data');
});

it('returns decoded points on detail', function () {
    $me = \App\Models\User::factory()->create();
    $points = [['lat'=>50,'lng'=>6,'speed'=>10,'altitude'=>100,'accuracy'=>3,'t'=>'2026-07-25T10:00:00Z']];
    $trip = \App\Models\Trip::factory()->for($me)->create([
        'route' => gzencode(json_encode($points)), 'point_count' => 1,
    ]);
    $this->actingAs($me, 'sanctum')->getJson("/api/trips/{$trip->client_uuid}")
        ->assertOk()->assertJsonPath('points.0.lat', 50);
});
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `@index`, `@show` (gzdecode → json), `@destroy`**, scoping every query to `auth()->id()`.

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: trip list, detail and delete"
```

---

### Task 9: Account delete (cascade) + data export (GDPR)

**Files:**
- Create: `backend/app/Http/Controllers/Api/AccountController.php`
- Modify: `backend/routes/api.php`
- Test: `backend/tests/Feature/AccountTest.php`

**Interfaces:**
- Produces: `DELETE /api/account` (auth) deletes user + trips; `GET /api/account/export` (auth) returns `{user, trips:[...with points...]}`.

- [ ] **Step 1: Write failing tests.**

```php
it('deletes account and trips', function () {
    $user = \App\Models\User::factory()->create();
    \App\Models\Trip::factory()->for($user)->count(3)->create();
    $this->actingAs($user, 'sanctum')->deleteJson('/api/account')->assertOk();
    expect(\App\Models\User::count())->toBe(0);
    expect(\App\Models\Trip::count())->toBe(0);
});

it('exports all my data', function () {
    $user = \App\Models\User::factory()->create();
    \App\Models\Trip::factory()->for($user)->create();
    $this->actingAs($user, 'sanctum')->getJson('/api/account/export')
        ->assertOk()->assertJsonStructure(['user', 'trips']);
});
```

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `AccountController@destroy` (cascade delete) and `@export`.** Ensure the migration sets `trips.user_id` FK `onDelete('cascade')` (or delete trips explicitly).

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: account delete and data export"
```

---

### Task 10: Rate limiting + full backend suite

**Files:**
- Modify: `backend/routes/api.php` (throttle on auth + upload)
- Test: `backend/tests/Feature/ThrottleTest.php`

- [ ] **Step 1: Write a failing test** that hammers `/api/auth/login` past the limit and expects 429.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Apply `throttle:` middleware** to auth and upload route groups.

- [ ] **Step 4: Run the full backend suite.**

Run: `cd backend && ./vendor/bin/pest`
Expected: all PASS.

- [ ] **Step 5: Commit.**

```bash
git add backend
git commit -m "feat: rate limiting on auth and upload"
```

---

### Task 11: App — drift schema v2 (client_uuid + synced_at)

**Files:**
- Modify: `lib/data/database.dart` (add columns, bump schemaVersion, migration)
- Modify: `lib/data/trip_repository.dart` (interface: `unsyncedTrips()`, `markSynced(clientUuid)`, generate `client_uuid` on create)
- Modify: `lib/domain/trip.dart` (add `clientUuid`, `syncedAt`)
- Test: `test/data/sync_columns_test.dart`

**Interfaces:**
- Produces: `Trips` table gains `clientUuid` (text, unique) + `syncedAt` (datetime nullable). `TripRepository` gains `Future<List<Trip>> unsyncedTrips()` (kept && syncedAt==null) and `Future<void> markSynced(String clientUuid)`. `createTrip` assigns a v4 uuid when `clientUuid` is empty.

- [ ] **Step 1: Add `uuid` package.** `flutter pub add uuid`.

- [ ] **Step 2: Write the failing test** — create a trip, expect a non-empty `clientUuid`; `unsyncedTrips()` returns it; after `markSynced`, it is excluded.

```dart
test('new trips are unsynced then marked synced', () async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = DriftTripRepository(db);
  final id = await repo.createTrip(/* trip with kept:true */);
  final trip = (await repo.keptTrips()).single;
  expect(trip.clientUuid, isNotEmpty);
  expect(await repo.unsyncedTrips(), hasLength(1));
  await repo.markSynced(trip.clientUuid);
  expect(await repo.unsyncedTrips(), isEmpty);
  await db.close();
});
```

- [ ] **Step 3: Run to verify failure.** Run: `flutter test test/data/sync_columns_test.dart` → FAIL.

- [ ] **Step 4: Implement** the drift columns, `schemaVersion = 2` with a `MigrationStrategy` adding the columns, regenerate (`dart run build_runner build`), extend the domain `Trip` and repository methods.

- [ ] **Step 5: Run to verify pass + existing data tests.** Run: `flutter test test/data/` → PASS.

- [ ] **Step 6: Commit.**

```bash
git add lib test pubspec.yaml
git commit -m "feat: local sync columns (client_uuid, synced_at)"
```

---

### Task 12: App — auth client + secure token storage

**Files:**
- Create: `lib/cloud/api_client.dart` (dio + auth interceptor)
- Create: `lib/cloud/auth_repository.dart` (register/login/social/logout/me)
- Create: `lib/cloud/token_store.dart` (flutter_secure_storage wrapper + fake)
- Test: `test/cloud/auth_repository_test.dart`

**Interfaces:**
- Produces:
  - `abstract class TokenStore { Future<String?> read(); Future<void> write(String token); Future<void> clear(); }` + `SecureTokenStore` + `InMemoryTokenStore` (tests).
  - `class AuthRepository { Future<void> register(...); Future<void> login(email, password); Future<void> loginSocial(provider, idToken); Future<void> logout(); }` storing the token via `TokenStore`.
  - `ApiClient` wraps dio, base URL from a `--dart-define=API_BASE_URL`, attaches `Authorization: Bearer` from `TokenStore`.

- [ ] **Step 1: Add packages.** `flutter pub add dio flutter_secure_storage`.

- [ ] **Step 2: Write failing tests** with a mocked dio (mocktail) + `InMemoryTokenStore`: successful login stores token; 401 surfaces an `AuthException`.

- [ ] **Step 3: Run to verify failure.** → FAIL.

- [ ] **Step 4: Implement** `TokenStore` variants, `ApiClient`, `AuthRepository`.

- [ ] **Step 5: Run to verify pass.** → PASS.

- [ ] **Step 6: Commit.**

```bash
git add lib test pubspec.yaml
git commit -m "feat: app auth client and token storage"
```

---

### Task 13: App — CloudSyncService (upload queue)

**Files:**
- Create: `lib/cloud/cloud_sync_service.dart`
- Modify: `lib/app/providers.dart` (wire providers)
- Test: `test/cloud/cloud_sync_service_test.dart`

**Interfaces:**
- Consumes: `TripRepository` (Task 11), `ApiClient`/`TokenStore` (Task 12).
- Produces: `class CloudSyncService { Future<void> syncOnce(); }` — for each `unsyncedTrips()`, builds the payload (stats + `pointsFor`), `POST /api/trips`; on 2xx calls `markSynced`; on 401 stops and clears token; on network error leaves it unsynced for retry.

- [ ] **Step 1: Write failing tests** with a fake API: two unsynced trips → both marked synced after `syncOnce`; a 401 → sync stops and token cleared; a 500 → trip stays unsynced.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement `CloudSyncService`.**

- [ ] **Step 4: Run to verify pass.** → PASS.

- [ ] **Step 5: Commit.**

```bash
git add lib test
git commit -m "feat: cloud sync upload service"
```

---

### Task 14: App — auth UI + settings cloud toggle

**Files:**
- Create: `lib/ui/auth_screen.dart`
- Modify: `lib/ui/settings_screen.dart` (cloud toggle, login state, account delete)
- Modify: `lib/settings/settings_controller.dart` (add `cloudEnabled`)
- Test: `test/ui/auth_screen_test.dart`, extend `test/ui/settings_screen_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `CloudSyncService`, settings.
- Produces: `AuthScreen` (email login/register + Apple/Google buttons); settings gains a "Cloud-Sync aktivieren" switch (persisted `cloudEnabled`) that, when enabled and logged out, routes to `AuthScreen`; an "Account löschen" action calling `DELETE /api/account`. When `cloudEnabled` && logged in, `syncOnce()` runs after each finalized trip.

- [ ] **Step 1: Write failing widget test** — the cloud switch renders; toggling it on while logged out shows the auth screen.

- [ ] **Step 2: Run to verify failure.** → FAIL.

- [ ] **Step 3: Implement** `cloudEnabled` in settings, `AuthScreen`, and the settings wiring; trigger `syncOnce()` from the recorder's finalize path when cloud is enabled.

- [ ] **Step 4: Run to verify pass + full app suite.** Run: `flutter test` → all PASS. `flutter analyze` → clean.

- [ ] **Step 5: Commit.**

```bash
git add lib test
git commit -m "feat: auth UI and cloud sync toggle"
```

---

### Task 15: End-to-end smoke (documented)

**Files:**
- Create: `docs/qa/phase2-e2e-checklist.md`

- [ ] **Step 1: Run backend locally** (`cd backend && php artisan serve`) against a real MySQL from `.env`; run `php artisan migrate`.
- [ ] **Step 2: Run the app** with `--dart-define=API_BASE_URL=http://<host>:8000`.
- [ ] **Step 3: Walk:** register → enable cloud → record a trip → confirm it appears via `GET /api/trips` → export → delete account → verify data gone.
- [ ] **Step 4: Record results** and any gaps in the checklist. Commit.

---

## Self-Review

**Spec coverage:**
- Auth email+social → Tasks 3, 5. ✓
- Sanctum tokens / me / logout → Tasks 3, 4. ✓
- Push-only idempotent upload + gzip blob → Task 7. ✓
- List/detail/delete → Task 8. ✓
- GDPR delete + export → Task 9. ✓
- Anti-cheat validation → Task 7. ✓
- Rate limiting → Task 10. ✓
- MySQL + indexed stats / route blob schema → Task 6. ✓
- App sync columns → Task 11. ✓
- App auth client + secure storage → Task 12. ✓
- CloudSyncService push + retry + 401 handling → Task 13. ✓
- Cloud toggle + auth UI + account delete → Task 14. ✓

**Placeholder scan:** UI tasks (14) describe test intent in prose; interfaces are concrete. Backend tasks carry real code. The real JWKS social verifier (Task 5) is described, not fully coded — its interface + fake are concrete so the endpoint and tests are unambiguous; the production verifier is a bounded implementation detail.

**Type consistency:** `client_uuid` / `clientUuid`, `synced_at` / `syncedAt`, `route`, `point_count`, `SocialTokenVerifier`, `TokenStore`, `AuthRepository`, `CloudSyncService`, `unsyncedTrips`, `markSynced` are used consistently across tasks. ✓

<?php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;

it('faltet eine hochgeladene Fahrt in die Aggregate', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();

    expect(DB::table('heat_edges')->where('user_id', $user->id)->count())
        ->toBeGreaterThan(0);
    expect(maxEdgeCount($user->id))->toBe(1);
});

it('zaehlt zwei Fahrten ueber dieselbe Strecke doppelt', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('uuid-2'))->assertCreated();

    expect(maxEdgeCount($user->id))->toBe(2);
});

it('zaehlt einen erneuten Upload derselben Fahrt nicht doppelt', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertOk();

    expect(maxEdgeCount($user->id))->toBe(1);
});

it('bucketet nach dem Monat der Startzeit', function () {
    Sanctum::actingAs($user = User::factory()->create());

    $this->postJson('/api/trips', tripPayload('a', '2026-01-15T10:00:00Z'))->assertCreated();
    $this->postJson('/api/trips', tripPayload('b', '2026-03-15T10:00:00Z'))->assertCreated();

    $months = DB::table('heat_edges')->where('user_id', $user->id)
        ->distinct()->pluck('month')->sort()->values()->all();
    expect($months)->toBe([202601, 202603]);
});

it('haelt die Daten zweier Nutzer getrennt', function () {
    Sanctum::actingAs($a = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-a'))->assertCreated();

    Sanctum::actingAs($b = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-b'))->assertCreated();

    expect(maxEdgeCount($a->id))->toBe(1);
    expect(maxEdgeCount($b->id))->toBe(1);
});

it('behaelt Zeitstempel und Genauigkeit in der gespeicherten Route', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('mit-zeit'))->assertCreated();

    $point = \App\Models\Trip::first()->points()[0];

    // Ohne diese Felder kann die serverseitige Faltung weder Mess-Luecken
    // noch ungenaue Punkte erkennen und wiche vom lokalen Ergebnis ab.
    expect($point)->toHaveKeys(['lat', 'lng', 't', 'accuracy']);
});

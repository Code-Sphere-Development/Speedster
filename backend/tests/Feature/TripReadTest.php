<?php

use App\Models\Trip;
use App\Models\User;

it('lists only my trips', function () {
    $me = User::factory()->create();
    Trip::factory()->for($me)->count(2)->create();
    Trip::factory()->for(User::factory())->create();

    $this->actingAs($me, 'sanctum')->getJson('/api/trips')
        ->assertOk()->assertJsonCount(2, 'data');
});

it('returns decoded points on detail', function () {
    $me = User::factory()->create();
    $points = [['lat' => 50, 'lng' => 6, 'speed' => 10, 'altitude' => 100, 'accuracy' => 3, 't' => '2026-07-25T10:00:00Z']];
    $trip = Trip::factory()->for($me)->create([
        'route' => gzencode(json_encode($points)),
        'point_count' => 1,
    ]);

    $this->actingAs($me, 'sanctum')->getJson("/api/trips/{$trip->client_uuid}")
        ->assertOk()->assertJsonPath('points.0.lat', 50);
});

it('cannot read another users trip', function () {
    $me = User::factory()->create();
    $other = Trip::factory()->for(User::factory())->create();

    $this->actingAs($me, 'sanctum')->getJson("/api/trips/{$other->client_uuid}")
        ->assertStatus(404);
});

it('deletes my trip', function () {
    $me = User::factory()->create();
    $trip = Trip::factory()->for($me)->create();

    $this->actingAs($me, 'sanctum')->deleteJson("/api/trips/{$trip->client_uuid}")
        ->assertOk();
    expect(Trip::count())->toBe(0);
});

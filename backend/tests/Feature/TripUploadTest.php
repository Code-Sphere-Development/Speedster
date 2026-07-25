<?php

use App\Models\Trip;
use App\Models\User;
use Illuminate\Support\Str;

function payload(array $over = []): array
{
    return array_merge([
        'client_uuid' => (string) Str::uuid(),
        'start_time' => '2026-07-25T10:00:00Z',
        'end_time' => '2026-07-25T10:30:00Z',
        'max_speed' => 30.0,
        'avg_speed' => 12.0,
        'distance' => 15400.0,
        'duration_seconds' => 1800,
        'zero_to_hundred_seconds' => 8.2,
        'elevation_gain' => 120.0,
        'points' => [
            ['lat' => 50, 'lng' => 6, 'speed' => 10, 'altitude' => 100, 'accuracy' => 3, 't' => '2026-07-25T10:00:00Z'],
        ],
    ], $over);
}

it('uploads a trip', function () {
    $user = User::factory()->create();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload())
        ->assertCreated();
    expect(Trip::count())->toBe(1);
});

it('is idempotent on client_uuid', function () {
    $user = User::factory()->create();
    $uuid = (string) Str::uuid();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload(['client_uuid' => $uuid]))
        ->assertCreated();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload(['client_uuid' => $uuid, 'max_speed' => 40.0]))
        ->assertOk();
    expect(Trip::count())->toBe(1);
    expect(Trip::first()->max_speed)->toBe(40.0);
});

it('rejects unrealistic max_speed', function () {
    $user = User::factory()->create();
    $this->actingAs($user, 'sanctum')->postJson('/api/trips', payload(['max_speed' => 999]))
        ->assertStatus(422);
});

it('requires auth to upload', function () {
    $this->postJson('/api/trips', payload())->assertStatus(401);
});

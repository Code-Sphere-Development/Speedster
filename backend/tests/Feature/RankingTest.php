<?php

use App\Models\Trip;
use App\Models\User;

function userWithTrips(array $attrs, array $maxSpeeds): User
{
    $user = User::factory()->create($attrs);
    foreach ($maxSpeeds as $s) {
        Trip::factory()->for($user)->create(['max_speed' => $s, 'distance' => 1000]);
    }

    return $user;
}

it('ranks users by max speed descending', function () {
    userWithTrips(['name' => 'Slow'], [20.0]);
    userWithTrips(['name' => 'Fast'], [50.0, 30.0]);
    $me = User::factory()->create(['country' => 'DE']);

    $res = $this->actingAs($me, 'sanctum')->getJson('/api/rankings?metric=max_speed')
        ->assertOk();

    $entries = $res->json('entries');
    expect($entries[0]['display_name'])->toBe('Fast');
    expect($entries[0]['value'])->toEqual(50.0);
    expect($entries[1]['display_name'])->toBe('Slow');
});

it('scopes to the callers country', function () {
    userWithTrips(['name' => 'DEuser', 'country' => 'DE'], [40.0]);
    userWithTrips(['name' => 'FRuser', 'country' => 'FR'], [60.0]);
    $me = User::factory()->create(['country' => 'DE']);

    $entries = $this->actingAs($me, 'sanctum')
        ->getJson('/api/rankings?scope=country&metric=max_speed')
        ->assertOk()->json('entries');

    expect(collect($entries)->pluck('display_name'))->toContain('DEuser');
    expect(collect($entries)->pluck('display_name'))->not->toContain('FRuser');
});

it('excludes opted-out users', function () {
    userWithTrips(['name' => 'Hidden', 'ranking_opt_in' => false], [99.0]);
    userWithTrips(['name' => 'Shown'], [40.0]);
    $me = User::factory()->create();

    $entries = $this->actingAs($me, 'sanctum')
        ->getJson('/api/rankings?metric=max_speed')
        ->assertOk()->json('entries');

    expect(collect($entries)->pluck('display_name'))->not->toContain('Hidden');
});

it('uses display_name over name when set', function () {
    userWithTrips(['name' => 'Real', 'display_name' => 'Speedy'], [40.0]);
    $me = User::factory()->create();

    $entries = $this->actingAs($me, 'sanctum')
        ->getJson('/api/rankings?metric=max_speed')
        ->assertOk()->json('entries');

    expect($entries[0]['display_name'])->toBe('Speedy');
});

it('returns the callers own rank', function () {
    userWithTrips(['name' => 'A'], [80.0]);
    userWithTrips(['name' => 'B'], [60.0]);
    $me = User::factory()->create(['name' => 'Me']);
    Trip::factory()->for($me)->create(['max_speed' => 70.0]);

    $me_data = $this->actingAs($me, 'sanctum')
        ->getJson('/api/rankings?metric=max_speed')
        ->assertOk()->json('me');

    expect($me_data['rank'])->toBe(2); // 80 > 70 > 60
    expect($me_data['value'])->toEqual(70.0);
});

it('ranks best 0-100 ascending', function () {
    $fast = userWithTrips(['name' => 'Quick'], []);
    Trip::factory()->for($fast)->create(['zero_to_hundred_seconds' => 5.0]);
    $slow = userWithTrips(['name' => 'Sluggish'], []);
    Trip::factory()->for($slow)->create(['zero_to_hundred_seconds' => 9.0]);
    $me = User::factory()->create();

    $entries = $this->actingAs($me, 'sanctum')
        ->getJson('/api/rankings?metric=best_zero_to_hundred')
        ->assertOk()->json('entries');

    expect($entries[0]['display_name'])->toBe('Quick');
    expect($entries[0]['value'])->toEqual(5.0);
});

it('requires auth', function () {
    $this->getJson('/api/rankings')->assertStatus(401);
});

<?php

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('stores and retrieves a trip for a user', function () {
    $user = User::factory()->create();
    $trip = Trip::factory()->for($user)->create(['max_speed' => 30.0]);

    expect($trip->user->id)->toBe($user->id);
    expect($trip->max_speed)->toBe(30.0);
});

it('decodes gzip route into points', function () {
    $points = [['lat' => 50, 'lng' => 6, 'speed' => 10]];
    $trip = Trip::factory()->create([
        'route' => gzencode(json_encode($points)),
        'point_count' => 1,
    ]);

    expect($trip->points())->toBe($points);
});

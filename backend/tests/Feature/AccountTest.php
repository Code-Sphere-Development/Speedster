<?php

use App\Models\Trip;
use App\Models\User;

it('deletes account and trips', function () {
    $user = User::factory()->create();
    Trip::factory()->for($user)->count(3)->create();

    $this->actingAs($user, 'sanctum')->deleteJson('/api/account')->assertOk();

    expect(User::count())->toBe(0);
    expect(Trip::count())->toBe(0);
});

it('exports all my data', function () {
    $user = User::factory()->create();
    Trip::factory()->for($user)->create();

    $this->actingAs($user, 'sanctum')->getJson('/api/account/export')
        ->assertOk()->assertJsonStructure(['user' => ['email'], 'trips']);
});

it('blocks account actions without auth', function () {
    $this->deleteJson('/api/account')->assertStatus(401);
});

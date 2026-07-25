<?php

use App\Models\User;

it('returns the authenticated user', function () {
    $user = User::factory()->create();
    $this->actingAs($user, 'sanctum')->getJson('/api/me')
        ->assertOk()->assertJsonPath('email', $user->email);
});

it('blocks /api/me without a token', function () {
    $this->getJson('/api/me')->assertStatus(401);
});

it('logs out and revokes the token', function () {
    $user = User::factory()->create();
    $token = $user->createToken('app')->plainTextToken;

    $this->withToken($token)->postJson('/api/auth/logout')->assertOk();
    expect($user->fresh()->tokens()->count())->toBe(0);
});

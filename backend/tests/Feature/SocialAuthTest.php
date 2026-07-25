<?php

use App\Services\FakeSocialTokenVerifier;
use App\Services\SocialTokenVerifier;

beforeEach(function () {
    $this->app->bind(SocialTokenVerifier::class, FakeSocialTokenVerifier::class);
});

it('creates a user from a valid social token', function () {
    $this->postJson('/api/auth/social', ['provider' => 'google', 'id_token' => 'valid'])
        ->assertOk()->assertJsonStructure(['token', 'user']);
    $this->assertDatabaseHas('users', ['provider' => 'google', 'email' => 'social@example.com']);
});

it('reuses the same user on repeated social login', function () {
    $this->postJson('/api/auth/social', ['provider' => 'google', 'id_token' => 'valid']);
    $this->postJson('/api/auth/social', ['provider' => 'google', 'id_token' => 'valid']);
    expect(\App\Models\User::where('provider', 'google')->count())->toBe(1);
});

it('rejects an invalid social token', function () {
    $this->postJson('/api/auth/social', ['provider' => 'google', 'id_token' => 'bad'])
        ->assertStatus(422);
});

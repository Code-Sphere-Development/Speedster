<?php

use App\Models\User;

it('registers a user and returns a token', function () {
    $res = $this->postJson('/api/auth/register', [
        'name' => 'Ada',
        'email' => 'ada@example.com',
        'password' => 'secret12',
    ]);
    $res->assertCreated()->assertJsonStructure(['token', 'user' => ['id', 'email']]);
    $this->assertDatabaseHas('users', ['email' => 'ada@example.com']);
});

it('rejects duplicate email on register', function () {
    User::factory()->create(['email' => 'ada@example.com']);
    $this->postJson('/api/auth/register', [
        'name' => 'Ada',
        'email' => 'ada@example.com',
        'password' => 'secret12',
    ])->assertStatus(422);
});

it('logs in with valid credentials', function () {
    User::factory()->create([
        'email' => 'ada@example.com',
        'password' => bcrypt('secret12'),
    ]);
    $this->postJson('/api/auth/login', [
        'email' => 'ada@example.com',
        'password' => 'secret12',
    ])->assertOk()->assertJsonStructure(['token']);
});

it('rejects bad credentials', function () {
    $this->postJson('/api/auth/login', [
        'email' => 'x@y.z',
        'password' => 'nope',
    ])->assertStatus(422);
});

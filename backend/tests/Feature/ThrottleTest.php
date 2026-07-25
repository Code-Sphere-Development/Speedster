<?php

it('throttles repeated login attempts', function () {
    $last = null;
    for ($i = 0; $i < 12; $i++) {
        $last = $this->postJson('/api/auth/login', [
            'email' => 'x@y.z',
            'password' => 'nope',
        ]);
    }
    $last->assertStatus(429);
});

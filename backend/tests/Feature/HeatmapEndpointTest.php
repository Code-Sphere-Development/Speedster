<?php

// tripPayload() und maxEdgeCount() stehen in tests/Pest.php.

use App\Models\User;
use Laravel\Sanctum\Sanctum;

it('verlangt Authentifizierung', function () {
    $this->getJson('/api/heatmap')->assertUnauthorized();
});

it('liefert Kanten mit aufgeloesten Koordinaten', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();

    $res = $this->getJson('/api/heatmap?level=0')->assertOk();

    $res->assertJsonStructure([
        'range', 'level', 'max_count',
        'edges' => [['a', 'b', 'c']],
    ]);
    expect($res->json('max_count'))->toBe(1);

    $edge = $res->json('edges.0');
    expect($edge['a'][0])->toBeGreaterThan(49.9)->toBeLessThan(50.1);
    expect($edge['c'])->toBe(1);
});

it('filtert ueber die Monatsbuckets', function () {
    Sanctum::actingAs(User::factory()->create());
    // Bewusst an anderer Stelle: laege sie auf derselben Strecke, senkte
    // der Filter nur die Zaehler, nicht die Zahl der Kanten.
    $this->postJson('/api/trips', tripPayload('alt', '2020-01-15T10:00:00Z', 48.0))
        ->assertCreated();
    $this->postJson('/api/trips', tripPayload('neu', now()->toIso8601String()))
        ->assertCreated();

    $all = $this->getJson('/api/heatmap?range=all')->assertOk();
    $recent = $this->getJson('/api/heatmap?range=3m')->assertOk();

    expect(count($recent->json('edges')))
        ->toBeLessThan(count($all->json('edges')));
    expect(count($recent->json('edges')))->toBeGreaterThan(0);
});

it('grenzt auf den Viewport ein, laesst max_count aber global', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('nah', '2026-01-15T10:00:00Z', 50.0))
        ->assertCreated();
    $this->postJson('/api/trips', tripPayload('nah2', '2026-01-16T10:00:00Z', 50.0))
        ->assertCreated();
    $this->postJson('/api/trips', tripPayload('fern', '2026-01-15T10:00:00Z', 51.0))
        ->assertCreated();

    $all = $this->getJson('/api/heatmap')->assertOk();
    $box = $this->getJson(
        '/api/heatmap?min_lat=49.9&min_lng=5.9&max_lat=50.1&max_lng=6.1'
    )->assertOk();

    expect(count($box->json('edges')))->toBeLessThan(count($all->json('edges')));
    expect(count($box->json('edges')))->toBeGreaterThan(0);
    expect($box->json('max_count'))->toBe($all->json('max_count'));
});

it('zeigt niemals fremde Daten', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/trips', tripPayload('fremd'))->assertCreated();

    Sanctum::actingAs(User::factory()->create());
    expect($this->getJson('/api/heatmap')->assertOk()->json('edges'))->toBe([]);
});

it('weist unzulaessige Parameter zurueck', function () {
    Sanctum::actingAs(User::factory()->create());
    $this->getJson('/api/heatmap?level=9')->assertStatus(422);
    $this->getJson('/api/heatmap?range=gestern')->assertStatus(422);
});

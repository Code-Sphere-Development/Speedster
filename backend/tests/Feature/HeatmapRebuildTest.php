<?php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;

/** Versetzt die Daten in den Zustand vor Einfuehrung der Heatmap. */
function forgetHeatAggregates(): void
{
    DB::table('heat_edges')->delete();
    DB::table('heat_cells')->delete();
    DB::table('trips')->update(['heat_folded_at' => null]);
}

it('baut die Aggregate aus vorhandenen Fahrten neu auf', function () {
    Sanctum::actingAs($user = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('uuid-1'))->assertCreated();

    $before = maxEdgeCount($user->id);
    expect($before)->toBe(1);

    forgetHeatAggregates();
    $this->artisan('heatmap:rebuild')->assertSuccessful();

    expect(maxEdgeCount($user->id))->toBe($before);
});

it('kann auf einen Nutzer eingegrenzt werden', function () {
    Sanctum::actingAs($a = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('a'))->assertCreated();
    Sanctum::actingAs($b = User::factory()->create());
    $this->postJson('/api/trips', tripPayload('b'))->assertCreated();

    forgetHeatAggregates();
    $this->artisan('heatmap:rebuild', ['--user' => $a->id])->assertSuccessful();

    expect(DB::table('heat_edges')->where('user_id', $a->id)->count())
        ->toBeGreaterThan(0);
    expect(DB::table('heat_edges')->where('user_id', $b->id)->count())->toBe(0);
});

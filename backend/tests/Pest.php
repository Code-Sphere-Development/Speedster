<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
|
| The closure you provide to your test functions is always bound to a specific PHPUnit test
| case class. By default, that class is "PHPUnit\Framework\TestCase". Of course, you may
| need to change it using the "pest()" function to bind different classes or traits.
|
*/

pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');

/*
|--------------------------------------------------------------------------
| Expectations
|--------------------------------------------------------------------------
|
| When you're writing tests, you often need to check that values meet certain conditions. The
| "expect()" function gives you access to a set of "expectations" methods that you can use
| to assert different things. Of course, you may extend the Expectation API at any time.
|
*/

expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

/*
|--------------------------------------------------------------------------
| Functions
|--------------------------------------------------------------------------
|
| While Pest is very powerful out-of-the-box, you may have some testing code specific to your
| project that you don't want to repeat in every file. Here you can also expose helpers as
| global functions to help you to reduce the number of lines of code in your test files.
|
*/

function something()
{
    // ..
}

/** Deterministische, gueltige UUID aus einem beliebigen Namen. */
function testUuid(string $seed): string
{
    $h = md5($seed);

    return sprintf(
        '%s-%s-4%s-a%s-%s',
        substr($h, 0, 8), substr($h, 8, 4), substr($h, 13, 3),
        substr($h, 17, 3), substr($h, 20, 12)
    );
}

/**
 * Payload einer geraden Testfahrt: 20 Punkte, 12 m auseinander.
 * Wird von den Heatmap-Feature-Tests geteilt.
 */
function tripPayload(
    string $uuid,
    string $start = '2026-01-15T10:00:00Z',
    float $startLat = 50.0
): array {
    $points = [];
    for ($i = 0; $i < 20; $i++) {
        $points[] = [
            'lat' => $startLat + ($i * 12) / 111320.0,
            'lng' => 6.0,
            'speed' => 20,
            'altitude' => 100,
            'accuracy' => 5,
            't' => gmdate('c', strtotime($start) + $i),
        ];
    }

    return [
        'client_uuid' => testUuid($uuid),
        'start_time' => $start,
        'end_time' => gmdate('c', strtotime($start) + 20),
        'max_speed' => 20,
        'avg_speed' => 15,
        'distance' => 240,
        'duration_seconds' => 20,
        'elevation_gain' => 0,
        'points' => $points,
    ];
}

function maxEdgeCount(int $userId): int
{
    return (int) \Illuminate\Support\Facades\DB::table('heat_edges')
        ->where('user_id', $userId)->where('level', 0)->max('count');
}

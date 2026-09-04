<?php

use App\Services\HeatGrid;

function heatFixture(string $relative): array
{
    return json_decode(file_get_contents(__DIR__.'/../../../'.$relative), true);
}

/** Kanonische Darstellung, identisch zu canonical() im Dart-Test. */
function heatCanonical(array $fold): array
{
    $out = [];
    foreach ($fold as $level => $data) {
        $edges = $data['edges'];
        $cells = [];
        foreach ($data['cells'] as $key => $cell) {
            $cells[$key] = $cell['n'];
        }
        ksort($edges, SORT_STRING);
        ksort($cells, SORT_STRING);
        $out[(string) $level] = ['edges' => $edges, 'cells' => $cells];
    }

    return $out;
}

it('rechnet identisch zur Dart-Implementierung', function () {
    $fixtures = heatFixture('test/fixtures/heat_parity.json');
    $expected = heatFixture('test/fixtures/heat_parity_expected.json');

    foreach ($fixtures['cases'] as $case) {
        $actual = heatCanonical(HeatGrid::foldTrip($case['points']));
        expect($actual)->toEqual(
            $expected[$case['name']],
            "Fall {$case['name']} weicht ab"
        );
    }
});

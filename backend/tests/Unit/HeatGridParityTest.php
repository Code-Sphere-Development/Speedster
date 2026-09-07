<?php

use App\Services\HeatGrid;

/**
 * Die Fixtures liegen bewusst hier im Repo und nicht in der App: beide
 * Seiten pruefen gegen dieselbe festgeschriebene Referenz. Aendert sich die
 * Rasterung, werden die Dateien in der App neu erzeugt und hierher kopiert
 * -- siehe README.
 */
function heatFixture(string $name): array
{
    return json_decode(
        file_get_contents(__DIR__.'/../fixtures/'.$name),
        true
    );
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
    $fixtures = heatFixture('heat_parity.json');
    $expected = heatFixture('heat_parity_expected.json');

    foreach ($fixtures['cases'] as $case) {
        $actual = heatCanonical(HeatGrid::foldTrip($case['points']));
        expect($actual)->toEqual(
            $expected[$case['name']],
            "Fall {$case['name']} weicht ab"
        );
    }
});

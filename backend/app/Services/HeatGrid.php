<?php

namespace App\Services;

/**
 * Rasterlogik der Heatmap. Zeilengetreuer Spiegel von
 * `lib/heat/heat_grid.dart` — weicht eine Seite ab, sieht die
 * Cloud-Heatmap anders aus als die lokale. HeatGridParityTest belegt die
 * Gleichheit anhand gemeinsamer Fixtures.
 */
class HeatGrid
{
    public const CELL_METERS = [25.0, 100.0, 400.0];

    public const LEVEL_COUNT = 3;

    public const METERS_PER_DEG_LAT = 111320.0;

    public const COS_CLAMP = 0.01;

    public const MAX_ACCURACY_METERS = 50.0;

    public const MAX_GAP_METERS = 200.0;

    public const MAX_GAP_SECONDS = 30;

    public const RESAMPLE_METERS = 10.0;

    private const EARTH_RADIUS_METERS = 6371000.0;

    public static function latStep(int $level): float
    {
        return self::CELL_METERS[$level] / self::METERS_PER_DEG_LAT;
    }

    /**
     * Quantisiert eine Koordinate.
     *
     * @return array{0:int,1:int} [row, col]
     */
    public static function cellFor(float $lat, float $lng, int $level): array
    {
        $step = self::latStep($level);
        $row = (int) floor($lat / $step);
        $rowLat = ($row + 0.5) * $step;
        $lngStep = $step / max(cos($rowLat * M_PI / 180.0), self::COS_CLAMP);
        $col = (int) floor($lng / $lngStep);

        return [$row, $col];
    }

    public static function haversineMeters(
        float $lat1,
        float $lng1,
        float $lat2,
        float $lng2
    ): float {
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return self::EARTH_RADIUS_METERS * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * @param  array<int, array<string, mixed>>  $points
     * @return array<int, array{cells: array<string, array{lat_sum:float,lng_sum:float,n:int}>, edges: array<string,int>}>
     */
    public static function foldTrip(array $points): array
    {
        $fold = [];
        for ($level = 0; $level < self::LEVEL_COUNT; $level++) {
            $fold[$level] = ['cells' => [], 'edges' => []];
        }

        foreach (self::segments($points) as $segment) {
            for ($level = 0; $level < self::LEVEL_COUNT; $level++) {
                self::foldSegment($segment, $level, $fold[$level]);
            }
        }

        return $fold;
    }

    /**
     * Wirft ungenaue Punkte weg und trennt die Spur an Mess-Luecken. Ohne
     * die Trennung zieht ein GPS-Ausfall im Tunnel eine Gerade quer durch
     * die Stadt, die sich bei jeder Fahrt aufsummieren wuerde.
     *
     * @return array<int, array<int, array<string, mixed>>>
     */
    private static function segments(array $points): array
    {
        $result = [];
        $current = [];

        foreach ($points as $p) {
            if (($p['accuracy'] ?? 0) > self::MAX_ACCURACY_METERS) {
                continue;
            }
            if ($current === []) {
                $current = [$p];

                continue;
            }
            $prev = $current[count($current) - 1];
            $gap = self::haversineMeters(
                $prev['lat'], $prev['lng'], $p['lat'], $p['lng']
            );
            // Altbestand vor dieser Version wurde ohne Zeitstempel abgelegt;
            // dann greift nur die Distanzpruefung.
            $timed = isset($p['t'], $prev['t']);
            $seconds = $timed
                ? abs(strtotime($p['t']) - strtotime($prev['t']))
                : 0;

            if ($gap > self::MAX_GAP_METERS
                || ($timed && $seconds > self::MAX_GAP_SECONDS)) {
                if (count($current) > 1) {
                    $result[] = $current;
                }
                $current = [$p];
            } else {
                $current[] = $p;
            }
        }
        if (count($current) > 1) {
            $result[] = $current;
        }

        return $result;
    }

    private static function foldSegment(array $segment, int $level, array &$acc): void
    {
        // Schwerpunkte nur aus echten Messungen.
        foreach ($segment as $p) {
            [$row, $col] = self::cellFor($p['lat'], $p['lng'], $level);
            $key = "$row:$col";
            if (! isset($acc['cells'][$key])) {
                $acc['cells'][$key] = ['lat_sum' => 0.0, 'lng_sum' => 0.0, 'n' => 0];
            }
            $acc['cells'][$key]['lat_sum'] += $p['lat'];
            $acc['cells'][$key]['lng_sum'] += $p['lng'];
            $acc['cells'][$key]['n']++;
        }

        $path = [];
        $count = count($segment);
        for ($i = 0; $i < $count - 1; $i++) {
            $from = $segment[$i];
            $to = $segment[$i + 1];
            self::appendCell($path, self::cellFor($from['lat'], $from['lng'], $level));

            // Nachverdichten, damit bei hohem Tempo keine Zelle uebersprungen wird.
            $distance = self::haversineMeters(
                $from['lat'], $from['lng'], $to['lat'], $to['lng']
            );
            $steps = (int) floor($distance / self::RESAMPLE_METERS);
            for ($s = 1; $s <= $steps; $s++) {
                $f = $s / ($steps + 1);
                self::appendCell($path, self::cellFor(
                    $from['lat'] + ($to['lat'] - $from['lat']) * $f,
                    $from['lng'] + ($to['lng'] - $from['lng']) * $f,
                    $level
                ));
            }
        }
        if ($count > 0) {
            $last = $segment[$count - 1];
            self::appendCell($path, self::cellFor($last['lat'], $last['lng'], $level));
        }

        $previous = null;
        $pathLength = count($path);
        for ($i = 0; $i < $pathLength - 1; $i++) {
            $edge = self::normalizedEdge($path[$i], $path[$i + 1]);
            // Direkt wiederholte Kante = GPS-Zittern ueber die Zellgrenze.
            if ($edge === $previous) {
                continue;
            }
            $acc['edges'][$edge] = ($acc['edges'][$edge] ?? 0) + 1;
            $previous = $edge;
        }
    }

    private static function appendCell(array &$path, array $cell): void
    {
        $last = $path === [] ? null : $path[count($path) - 1];
        if ($last !== null && $last[0] === $cell[0] && $last[1] === $cell[1]) {
            return;
        }
        $path[] = $cell;
    }

    private static function normalizedEdge(array $x, array $y): string
    {
        $xFirst = $x[0] < $y[0] || ($x[0] === $y[0] && $x[1] <= $y[1]);
        [$a, $b] = $xFirst ? [$x, $y] : [$y, $x];

        return "{$a[0]}:{$a[1]}:{$b[0]}:{$b[1]}";
    }
}

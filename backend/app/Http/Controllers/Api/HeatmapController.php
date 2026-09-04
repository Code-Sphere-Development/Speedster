<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HeatmapController extends Controller
{
    public function index(Request $request)
    {
        $data = $request->validate([
            'range' => 'sometimes|in:all,12m,3m',
            'level' => 'sometimes|integer|between:0,2',
            'min_lat' => 'sometimes|numeric|between:-90,90',
            'max_lat' => 'sometimes|numeric|between:-90,90',
            'min_lng' => 'sometimes|numeric|between:-180,180',
            'max_lng' => 'sometimes|numeric|between:-180,180',
        ]);

        $userId = $request->user()->id;
        $level = (int) ($data['level'] ?? 0);
        $range = $data['range'] ?? 'all';

        $edges = DB::table('heat_edges')
            ->select(
                'a_row', 'a_col', 'b_row', 'b_col',
                DB::raw('SUM(count) as total')
            )
            ->where('user_id', $userId)
            ->where('level', $level)
            ->when(
                $this->monthFloor($range),
                fn ($q, $month) => $q->where('month', '>=', $month)
            )
            ->groupBy('a_row', 'a_col', 'b_row', 'b_col')
            ->get();

        // Global ueber den gewaehlten Zeitraum, nicht ueber den Viewport:
        // sonst wuerden sich die Farben beim Verschieben der Karte aendern.
        $maxCount = (int) $edges->max('total');

        $cells = DB::table('heat_cells')
            ->where('user_id', $userId)
            ->where('level', $level)
            ->where('n', '>', 0)
            ->get()
            ->keyBy(fn ($c) => "{$c->cell_row}:{$c->cell_col}");

        $out = [];
        foreach ($edges as $edge) {
            $a = $cells->get("{$edge->a_row}:{$edge->a_col}");
            $b = $cells->get("{$edge->b_row}:{$edge->b_col}");
            if (! $a || ! $b) {
                continue;
            }

            $aLat = $a->lat_sum / $a->n;
            $aLng = $a->lng_sum / $a->n;
            $bLat = $b->lat_sum / $b->n;
            $bLng = $b->lng_sum / $b->n;

            if (! $this->inBox($data, $aLat, $aLng)
                && ! $this->inBox($data, $bLat, $bLng)) {
                continue;
            }

            $out[] = [
                'a' => [$aLat, $aLng],
                'b' => [$bLat, $bLng],
                'c' => (int) $edge->total,
            ];
        }

        return response()->json([
            'range' => $range,
            'level' => $level,
            'max_count' => $maxCount,
            'edges' => $out,
        ]);
    }

    /** Kleinster einzuschliessender Monatsbucket, null bei `all`. */
    private function monthFloor(string $range): ?int
    {
        return match ($range) {
            '3m' => (int) now()->subMonths(3)->format('Ym'),
            '12m' => (int) now()->subMonths(12)->format('Ym'),
            default => null,
        };
    }

    private function inBox(array $data, float $lat, float $lng): bool
    {
        if (! isset($data['min_lat'], $data['max_lat'], $data['min_lng'], $data['max_lng'])) {
            return true;
        }

        return $lat >= $data['min_lat'] && $lat <= $data['max_lat']
            && $lng >= $data['min_lng'] && $lng <= $data['max_lng'];
    }
}

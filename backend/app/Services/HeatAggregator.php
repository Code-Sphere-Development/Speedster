<?php

namespace App\Services;

use App\Models\Trip;
use Illuminate\Support\Facades\DB;

/**
 * Faltet Fahrten in die Aggregattabellen und nimmt sie wieder heraus.
 *
 * Die Ruecknahme ist noetig, weil `POST /trips` idempotent ist: dieselbe
 * client_uuid darf erneut hochgeladen werden, ohne dass die Heatmap
 * doppelt zaehlt.
 */
class HeatAggregator
{
    /** @param  array<int, array<string, mixed>>  $points */
    public function fold(Trip $trip, array $points): void
    {
        DB::transaction(function () use ($trip, $points) {
            if ($trip->heat_folded_at !== null) {
                $this->unfold($trip);
            }

            $month = (int) $trip->start_time->format('Ym');
            $this->apply($trip->user_id, $month, HeatGrid::foldTrip($points), 1);

            $trip->forceFill(['heat_folded_at' => now()])->save();
        });
    }

    /** Subtrahiert den Beitrag einer bereits gefalteten Fahrt. */
    public function unfold(Trip $trip): void
    {
        if ($trip->heat_folded_at === null) {
            return;
        }

        $month = (int) $trip->start_time->format('Ym');
        $this->apply($trip->user_id, $month, HeatGrid::foldTrip($trip->points()), -1);

        DB::table('heat_cells')->where('user_id', $trip->user_id)
            ->where('n', '<=', 0)->delete();
        DB::table('heat_edges')->where('user_id', $trip->user_id)
            ->where('count', '<=', 0)->delete();

        $trip->forceFill(['heat_folded_at' => null])->save();
    }

    /** @param  int  $sign  +1 zum Falten, -1 zum Herausrechnen. */
    private function apply(int $userId, int $month, array $fold, int $sign): void
    {
        foreach ($fold as $level => $data) {
            foreach ($data['cells'] as $key => $cell) {
                [$row, $col] = array_map('intval', explode(':', $key));
                $this->addCell(
                    $userId, $level, $row, $col,
                    $sign * $cell['lat_sum'],
                    $sign * $cell['lng_sum'],
                    $sign * $cell['n']
                );
            }
            foreach ($data['edges'] as $key => $count) {
                [$aRow, $aCol, $bRow, $bCol] = array_map('intval', explode(':', $key));
                $this->addEdge(
                    $userId, $level, $month,
                    $aRow, $aCol, $bRow, $bCol, $sign * $count
                );
            }
        }
    }

    private function addCell(
        int $userId, int $level, int $row, int $col,
        float $latSum, float $lngSum, int $n
    ): void {
        $affected = DB::table('heat_cells')
            ->where([
                'user_id' => $userId, 'level' => $level,
                'cell_row' => $row, 'cell_col' => $col,
            ])
            ->update([
                'lat_sum' => DB::raw('lat_sum + '.$this->num($latSum)),
                'lng_sum' => DB::raw('lng_sum + '.$this->num($lngSum)),
                'n' => DB::raw('n + '.$n),
            ]);

        if ($affected === 0 && $n > 0) {
            DB::table('heat_cells')->insert([
                'user_id' => $userId, 'level' => $level,
                'cell_row' => $row, 'cell_col' => $col,
                'lat_sum' => $latSum, 'lng_sum' => $lngSum, 'n' => $n,
            ]);
        }
    }

    private function addEdge(
        int $userId, int $level, int $month,
        int $aRow, int $aCol, int $bRow, int $bCol, int $count
    ): void {
        $affected = DB::table('heat_edges')
            ->where([
                'user_id' => $userId, 'level' => $level, 'month' => $month,
                'a_row' => $aRow, 'a_col' => $aCol,
                'b_row' => $bRow, 'b_col' => $bCol,
            ])
            ->update(['count' => DB::raw('count + '.$count)]);

        if ($affected === 0 && $count > 0) {
            DB::table('heat_edges')->insert([
                'user_id' => $userId, 'level' => $level, 'month' => $month,
                'a_row' => $aRow, 'a_col' => $aCol,
                'b_row' => $bRow, 'b_col' => $bCol,
                'count' => $count,
            ]);
        }
    }

    /** Locale-unabhaengige Zahl fuer den SQL-Ausdruck. */
    private function num(float $value): string
    {
        return number_format($value, 10, '.', '');
    }
}

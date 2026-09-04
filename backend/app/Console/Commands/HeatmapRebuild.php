<?php

namespace App\Console\Commands;

use App\Models\Trip;
use App\Services\HeatAggregator;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Baut die Heatmap-Aggregate aus den gespeicherten Routen-Blobs neu.
 * Noetig fuer Fahrten, die vor Einfuehrung des Features hochgeladen
 * wurden, und als Reparaturweg.
 */
class HeatmapRebuild extends Command
{
    protected $signature = 'heatmap:rebuild {--user= : Nur diesen Nutzer}';

    protected $description = 'Baut die Heatmap-Aggregate neu auf';

    public function handle(HeatAggregator $aggregator): int
    {
        $userId = $this->option('user');

        DB::table('heat_cells')
            ->when($userId, fn ($q) => $q->where('user_id', $userId))->delete();
        DB::table('heat_edges')
            ->when($userId, fn ($q) => $q->where('user_id', $userId))->delete();
        Trip::query()
            ->when($userId, fn ($q) => $q->where('user_id', $userId))
            ->update(['heat_folded_at' => null]);

        $count = 0;
        Trip::query()
            ->when($userId, fn ($q) => $q->where('user_id', $userId))
            ->orderBy('id')
            ->chunkById(100, function ($trips) use ($aggregator, &$count) {
                foreach ($trips as $trip) {
                    $points = $trip->points();
                    if ($points === []) {
                        continue;
                    }
                    $aggregator->fold($trip, $points);
                    $count++;
                }
            });

        $this->info("Heatmap neu aufgebaut: {$count} Fahrten.");

        return self::SUCCESS;
    }
}

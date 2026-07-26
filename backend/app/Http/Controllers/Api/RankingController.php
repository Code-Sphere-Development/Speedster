<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RankingController extends Controller
{
    private const METRICS = [
        'max_speed' => 'MAX(trips.max_speed)',
        'total_distance' => 'SUM(trips.distance)',
        'trip_count' => 'COUNT(trips.id)',
        'best_zero_to_hundred' => 'MIN(trips.zero_to_hundred_seconds)',
    ];

    public function index(Request $request)
    {
        $data = $request->validate([
            'scope' => ['nullable', 'in:world,country'],
            'metric' => ['nullable', 'in:max_speed,total_distance,trip_count,best_zero_to_hundred'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $scope = $data['scope'] ?? 'world';
        $metric = $data['metric'] ?? 'max_speed';
        $limit = $data['limit'] ?? 50;
        $asc = $metric === 'best_zero_to_hundred';
        $expr = self::METRICS[$metric];

        $country = $request->user()->country;

        $board = $this->aggregate($scope, $country, $expr);

        $entries = (clone $board)
            ->when($asc, fn ($q) => $q->orderBy('value'), fn ($q) => $q->orderByDesc('value'))
            ->limit($limit)
            ->get();

        $ranked = $entries->values()->map(fn ($row, $i) => [
            'rank' => $i + 1,
            'display_name' => $row->display_name,
            'country' => $row->country,
            'value' => (float) $row->value,
        ]);

        return response()->json([
            'scope' => $scope,
            'metric' => $metric,
            'entries' => $ranked,
            'me' => $this->me($request, $scope, $country, $expr, $asc),
        ]);
    }

    /**
     * Base per-user aggregate query, restricted to opted-in users (and country for country scope).
     */
    private function aggregate(string $scope, ?string $country, string $expr)
    {
        return DB::table('trips')
            ->join('users', 'users.id', '=', 'trips.user_id')
            ->where('users.ranking_opt_in', true)
            ->when($scope === 'country', fn ($q) => $q->where('users.country', $country))
            ->when($expr === self::METRICS['best_zero_to_hundred'],
                fn ($q) => $q->whereNotNull('trips.zero_to_hundred_seconds'))
            ->groupBy('users.id', 'users.name', 'users.display_name', 'users.country')
            ->selectRaw('users.id as user_id')
            ->selectRaw('COALESCE(users.display_name, users.name) as display_name')
            ->selectRaw('users.country as country')
            ->selectRaw("$expr as value")
            ->havingRaw('value IS NOT NULL');
    }

    private function me(Request $request, string $scope, ?string $country, string $expr, bool $asc): ?array
    {
        $user = $request->user();
        // Default is opt-in; only an explicit false excludes the caller.
        if ($user->ranking_opt_in === false || $user->ranking_opt_in === 0) {
            return null;
        }
        if ($scope === 'country' && $user->country === null) {
            return null;
        }

        $mine = DB::table('trips')
            ->where('trips.user_id', $user->id)
            ->when($expr === self::METRICS['best_zero_to_hundred'],
                fn ($q) => $q->whereNotNull('trips.zero_to_hundred_seconds'))
            ->selectRaw("$expr as value")
            ->value('value');

        if ($mine === null) {
            return null;
        }

        // Count better aggregates in PHP: nesting the aggregate as a subquery and
        // adding an outer where scrambles the bound-parameter order in this driver.
        $values = $this->aggregate($scope, $country, $expr)->pluck('value');
        $better = $values
            ->filter(fn ($v) => $asc ? $v < $mine : $v > $mine)
            ->count();

        return ['rank' => $better + 1, 'value' => (float) $mine];
    }
}

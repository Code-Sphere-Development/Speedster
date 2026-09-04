<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTripRequest;
use App\Models\Trip;
use App\Services\HeatAggregator;
use Illuminate\Http\Request;

class TripController extends Controller
{
    public function store(StoreTripRequest $request)
    {
        $data = $request->validated();
        $points = $data['points'];

        $existing = Trip::where('user_id', $request->user()->id)
            ->where('client_uuid', $data['client_uuid'])
            ->exists();

        $trip = Trip::updateOrCreate(
            ['user_id' => $request->user()->id, 'client_uuid' => $data['client_uuid']],
            [
                'start_time' => $data['start_time'],
                'end_time' => $data['end_time'] ?? null,
                'max_speed' => $data['max_speed'],
                'avg_speed' => $data['avg_speed'],
                'distance' => $data['distance'],
                'elevation_gain' => $data['elevation_gain'],
                'duration_seconds' => $data['duration_seconds'],
                'zero_to_hundred_seconds' => $data['zero_to_hundred_seconds'] ?? null,
                'route' => gzencode(json_encode($points)),
                'point_count' => count($points),
            ],
        );

        // Heatmap-Aggregate mitziehen, solange die Punkte schon vorliegen —
        // sonst muesste der Endpoint spaeter jeden Blob neu entpacken.
        app(HeatAggregator::class)->fold($trip, $points);

        return response()->json(
            ['client_uuid' => $trip->client_uuid],
            $existing ? 200 : 201,
        );
    }

    public function index(Request $request)
    {
        $trips = Trip::where('user_id', $request->user()->id)
            ->orderByDesc('start_time')
            ->paginate(50, [
                'client_uuid', 'start_time', 'end_time', 'max_speed', 'avg_speed',
                'distance', 'elevation_gain', 'duration_seconds',
                'zero_to_hundred_seconds', 'point_count',
            ]);

        return response()->json($trips);
    }

    public function show(Request $request, string $clientUuid)
    {
        $trip = Trip::where('user_id', $request->user()->id)
            ->where('client_uuid', $clientUuid)
            ->firstOrFail();

        return response()->json([
            'client_uuid' => $trip->client_uuid,
            'start_time' => $trip->start_time,
            'end_time' => $trip->end_time,
            'max_speed' => $trip->max_speed,
            'avg_speed' => $trip->avg_speed,
            'distance' => $trip->distance,
            'elevation_gain' => $trip->elevation_gain,
            'duration_seconds' => $trip->duration_seconds,
            'zero_to_hundred_seconds' => $trip->zero_to_hundred_seconds,
            'points' => $trip->points(),
        ]);
    }

    public function destroy(Request $request, string $clientUuid)
    {
        $trip = Trip::where('user_id', $request->user()->id)
            ->where('client_uuid', $clientUuid)
            ->firstOrFail();
        $trip->delete();

        return response()->json(['message' => 'Gelöscht.']);
    }
}

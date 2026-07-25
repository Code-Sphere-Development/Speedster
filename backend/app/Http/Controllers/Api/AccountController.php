<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    public function destroy(Request $request)
    {
        // Trips cascade via the foreign key; delete the user explicitly.
        $request->user()->delete();

        return response()->json(['message' => 'Account gelöscht.']);
    }

    public function export(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'country' => $user->country,
                'created_at' => $user->created_at,
            ],
            'trips' => $user->trips()->get()->map(fn ($trip) => [
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
            ]),
        ]);
    }
}

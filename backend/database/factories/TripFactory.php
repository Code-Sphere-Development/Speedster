<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<\App\Models\Trip>
 */
class TripFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'client_uuid' => (string) Str::uuid(),
            'start_time' => now()->subMinutes(30),
            'end_time' => now(),
            'max_speed' => 30.0,
            'avg_speed' => 12.0,
            'distance' => 15400.0,
            'elevation_gain' => 120.0,
            'duration_seconds' => 1800,
            'zero_to_hundred_seconds' => 8.2,
            'route' => null,
            'point_count' => 0,
        ];
    }
}

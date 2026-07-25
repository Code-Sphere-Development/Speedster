<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTripRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'client_uuid' => ['required', 'uuid'],
            'start_time' => ['required', 'date'],
            'end_time' => ['nullable', 'date'],
            // Anti-cheat floor: 150 m/s = 540 km/h.
            'max_speed' => ['required', 'numeric', 'min:0', 'max:150'],
            'avg_speed' => ['required', 'numeric', 'min:0', 'max:150'],
            'distance' => ['required', 'numeric', 'min:0'],
            'duration_seconds' => ['required', 'integer', 'min:0'],
            'zero_to_hundred_seconds' => ['nullable', 'numeric', 'min:0'],
            'elevation_gain' => ['required', 'numeric', 'min:0'],
            'points' => ['required', 'array'],
            'points.*.lat' => ['required', 'numeric'],
            'points.*.lng' => ['required', 'numeric'],
        ];
    }
}

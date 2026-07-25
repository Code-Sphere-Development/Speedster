<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Trip extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'client_uuid',
        'start_time',
        'end_time',
        'max_speed',
        'avg_speed',
        'distance',
        'elevation_gain',
        'duration_seconds',
        'zero_to_hundred_seconds',
        'route',
        'point_count',
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'max_speed' => 'float',
        'avg_speed' => 'float',
        'distance' => 'float',
        'elevation_gain' => 'float',
        'zero_to_hundred_seconds' => 'float',
        'duration_seconds' => 'integer',
        'point_count' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Decode the gzip-compressed JSON route back into an array of points.
     *
     * @return array<int, array<string, mixed>>
     */
    public function points(): array
    {
        if (! $this->route) {
            return [];
        }

        return json_decode(gzdecode($this->route), true) ?? [];
    }
}

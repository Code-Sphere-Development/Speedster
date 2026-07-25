<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->char('client_uuid', 36);
            $table->dateTime('start_time');
            $table->dateTime('end_time')->nullable();
            $table->double('max_speed')->default(0);
            $table->double('avg_speed')->default(0);
            $table->double('distance')->default(0);
            $table->double('elevation_gain')->default(0);
            $table->unsignedInteger('duration_seconds')->default(0);
            $table->double('zero_to_hundred_seconds')->nullable();
            $table->binary('route')->nullable();
            $table->unsignedInteger('point_count')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'client_uuid']);
            $table->index('max_speed');
            $table->index('distance');
            $table->index('duration_seconds');
        });

        // Widen the route blob on MySQL so long trips fit (BLOB is only 64 KB).
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE trips MODIFY route LONGBLOB');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};

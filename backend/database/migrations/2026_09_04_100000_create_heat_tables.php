<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Schwerpunkte je Zelle. Bewusst ohne Monatsbucket: der Schwerpunkt
        // einer Zelle ist zeitlich stabil.
        Schema::create('heat_cells', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('level');
            // cell_row/cell_col statt row/col: ROW ist in MySQL 8 reserviert.
            $table->integer('cell_row');
            $table->integer('cell_col');
            $table->double('lat_sum')->default(0);
            $table->double('lng_sum')->default(0);
            $table->unsignedInteger('n')->default(0);

            $table->primary(
                ['user_id', 'level', 'cell_row', 'cell_col'],
                'heat_cells_pk'
            );
        });

        // Befahrungen je Kante und Monat. Der Monatsbucket ist der Grund,
        // warum die Cloud Zeitraeume filtern kann, ohne neu zu aggregieren.
        Schema::create('heat_edges', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('level');
            $table->unsignedInteger('month'); // YYYYMM
            $table->integer('a_row');
            $table->integer('a_col');
            $table->integer('b_row');
            $table->integer('b_col');
            $table->unsignedInteger('count')->default(0);

            $table->primary(
                ['user_id', 'level', 'month', 'a_row', 'a_col', 'b_row', 'b_col'],
                'heat_edges_pk'
            );
            $table->index(['user_id', 'level', 'month'], 'heat_edges_scope_idx');
        });

        Schema::table('trips', function (Blueprint $table) {
            $table->dateTime('heat_folded_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('heat_edges');
        Schema::dropIfExists('heat_cells');
        Schema::table('trips', function (Blueprint $table) {
            $table->dropColumn('heat_folded_at');
        });
    }
};

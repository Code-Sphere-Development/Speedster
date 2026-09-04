<?php

use Illuminate\Support\Facades\Schema;

it('legt die Heat-Tabellen und die Faltungsmarkierung an', function () {
    expect(Schema::hasTable('heat_cells'))->toBeTrue();
    expect(Schema::hasTable('heat_edges'))->toBeTrue();
    expect(Schema::hasColumn('trips', 'heat_folded_at'))->toBeTrue();

    expect(Schema::hasColumns('heat_cells', [
        'user_id', 'level', 'cell_row', 'cell_col', 'lat_sum', 'lng_sum', 'n',
    ]))->toBeTrue();

    expect(Schema::hasColumns('heat_edges', [
        'user_id', 'level', 'month', 'a_row', 'a_col', 'b_row', 'b_col', 'count',
    ]))->toBeTrue();
});

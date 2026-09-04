<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Moves the temple's address out of site_settings and into temple_profiles.
 *
 * A move, not a copy. Phase 1 put the address in site_settings as a stopgap and
 * said so (PHASE_1_PLAN assumption B2); leaving both would give one address two
 * sources of truth, which is the defect this phase exists to remove.
 *
 * The values are carried across before the columns are dropped, and `down()`
 * carries them back, so the pair is reversible with no data loss in either
 * direction.
 */
return new class extends Migration
{
    /** The columns that change owner. @var list<string> */
    private const MOVED = [
        'address_line1', 'address_line2', 'village', 'panchayat',
        'police_station', 'district', 'state', 'postal_code', 'country',
        'map_url',
    ];

    public function up(): void
    {
        $this->carry(from: 'site_settings', to: 'temple_profiles');

        Schema::table('site_settings', function (Blueprint $table) {
            $table->dropColumn(self::MOVED);
        });
    }

    public function down(): void
    {
        Schema::table('site_settings', function (Blueprint $table) {
            $table->string('address_line1', 200)->nullable();
            $table->string('address_line2', 200)->nullable();
            $table->string('village', 120)->nullable();
            $table->string('panchayat', 120)->nullable();
            $table->string('police_station', 120)->nullable();
            $table->string('district', 120)->nullable();
            $table->string('state', 120)->nullable();
            $table->string('postal_code', 20)->nullable();
            $table->string('country', 120)->nullable();
            $table->string('map_url', 500)->nullable();
        });

        $this->carry(from: 'temple_profiles', to: 'site_settings');
    }

    /**
     * Copy the moved columns from one singleton table to the other.
     *
     * Only blank destination columns are written, so re-running the move can
     * never overwrite an address the committee has since corrected on the
     * authoritative side.
     */
    private function carry(string $from, string $to): void
    {
        $source = DB::table($from)->orderBy('id')->first();

        if ($source === null) {
            return;
        }

        $values = [];
        foreach (self::MOVED as $column) {
            $value = $source->{$column} ?? null;

            if ($value !== null && trim((string) $value) !== '') {
                $values[$column] = $value;
            }
        }

        if ($values === []) {
            return;
        }

        $destination = DB::table($to)->orderBy('id')->first();

        if ($destination === null) {
            DB::table($to)->insert($values + [
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return;
        }

        // Never clobber a value already present on the destination.
        $values = array_filter(
            $values,
            static fn (string $column): bool => ($destination->{$column} ?? null) === null,
            ARRAY_FILTER_USE_KEY,
        );

        if ($values !== []) {
            DB::table($to)
                ->where('id', $destination->id)
                ->update($values + ['updated_at' => now()]);
        }
    }
};

<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The temple's address in both languages.
 *
 * Every other piece of content in this system is stored as `*_hi` and `*_en`
 * and resolved on read. The address was the one exception, and it showed: the
 * strip above a Hindi page read `Amarpur Pankhoriya, Kurma, Rasulpur Ekchari,
 * Bhagalpur, Bihar` because one column cannot hold both `अमरपुर पंखोरिया` and
 * `Amarpur Pankhoriya`. These are proper nouns written in two scripts, not a
 * translation somebody can skip.
 *
 * The existing columns are **renamed** to `_hi` rather than dropped: whatever a
 * site has already recorded is its primary address and must survive. Hindi is
 * the source language everywhere else, so that is the half it becomes.
 *
 * `postal_code` is deliberately left alone — `813204` is `813204` in both.
 */
return new class extends Migration
{
    /**
     * The address parts that exist in two scripts.
     *
     * @var list<string>
     */
    private const BILINGUAL = [
        'address_line1', 'address_line2', 'village', 'panchayat',
        'police_station', 'district', 'state', 'country',
    ];

    public function up(): void
    {
        Schema::table('temple_profiles', function (Blueprint $table) {
            foreach (self::BILINGUAL as $column) {
                $table->renameColumn($column, $column.'_hi');
            }
        });

        Schema::table('temple_profiles', function (Blueprint $table) {
            // Optional, like every other `_en` column: an English address that
            // has not been written falls back to the Hindi one on read, and the
            // response says it fell back.
            $table->string('address_line1_en', 200)->nullable()->after('address_line1_hi');
            $table->string('address_line2_en', 200)->nullable()->after('address_line2_hi');
            $table->string('village_en', 120)->nullable()->after('village_hi');
            $table->string('panchayat_en', 120)->nullable()->after('panchayat_hi');
            $table->string('police_station_en', 120)->nullable()->after('police_station_hi');
            $table->string('district_en', 120)->nullable()->after('district_hi');
            $table->string('state_en', 120)->nullable()->after('state_hi');
            $table->string('country_en', 120)->nullable()->after('country_hi');
        });
    }

    /**
     * Rolling back drops the English half.
     *
     * That is a real loss of content and the only honest reverse of this
     * change: the single column it goes back to can hold one language, and the
     * Hindi is the one the site is built on.
     */
    public function down(): void
    {
        Schema::table('temple_profiles', function (Blueprint $table) {
            $table->dropColumn([
                'address_line1_en', 'address_line2_en', 'village_en', 'panchayat_en',
                'police_station_en', 'district_en', 'state_en', 'country_en',
            ]);
        });

        Schema::table('temple_profiles', function (Blueprint $table) {
            foreach (self::BILINGUAL as $column) {
                $table->renameColumn($column.'_hi', $column);
            }
        });
    }
};

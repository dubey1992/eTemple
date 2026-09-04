<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Closes the circle between `albums` and `media`.
 *
 * An album's cover is one of its photographs and a photograph belongs to an
 * album, so the two tables reference each other. The cover key is added here,
 * once both tables exist, and dropped first on the way down — otherwise
 * `migrate:rollback` cannot drop `media` while `albums` still points at it.
 *
 * `nullOnDelete` rather than cascade: deleting the cover photograph leaves the
 * album, coverless. (In practice the Phase 5 deletion guard refuses to delete a
 * photograph that is in use as a cover at all — this is the database's own
 * backstop, for a row removed by any other route.)
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('albums', function (Blueprint $table) {
            $table->foreign('cover_media_id')
                ->references('id')->on('media')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('albums', function (Blueprint $table) {
            $table->dropForeign(['cover_media_id']);
        });
    }
};

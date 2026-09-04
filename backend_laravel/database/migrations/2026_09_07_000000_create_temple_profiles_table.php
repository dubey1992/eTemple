<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Singleton row holding the temple's own identity: its name, address, history
 * and mission.
 *
 * This is the authoritative source for all of it. Phase 1 kept the address in
 * site_settings as a stopgap and Phase 0-2 rendered the name from the Flutter
 * ARB files; the follow-up migration moves the address here and the Flutter
 * client now reads the name from this row (PHASE_3_PLAN assumptions D2 and D3).
 *
 * Every column is nullable: the specification forbids shipping invented temple
 * content, so an unconfigured site shows empty states until the committee fills
 * it in.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('temple_profiles', function (Blueprint $table) {
            $table->id();

            $table->string('name_hi', 200)->nullable();
            $table->string('name_en', 200)->nullable();
            $table->text('history_hi')->nullable();
            $table->text('history_en')->nullable();
            $table->text('mission_hi')->nullable();
            $table->text('mission_en')->nullable();

            // The address arrives here from site_settings in the next migration.
            $table->string('address_line1', 200)->nullable();
            $table->string('address_line2', 200)->nullable();
            $table->string('village', 120)->nullable();
            $table->string('panchayat', 120)->nullable();
            $table->string('police_station', 120)->nullable();
            $table->string('district', 120)->nullable();
            $table->string('state', 120)->nullable();
            $table->string('postal_code', 20)->nullable();
            $table->string('country', 120)->nullable();

            // URLs, not uploads: file handling with its own MIME and size
            // validation is Phase 5, and these columns will point at uploaded
            // media then without a schema change (assumption D10).
            $table->string('logo_url', 500)->nullable();
            $table->string('map_url', 500)->nullable();

            $table->unsignedSmallInteger('established_year')->nullable();

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('temple_profiles');
    }
};

<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Photograph albums (spec Phase 5, the "optional `albums`" half of the entity).
 *
 * Built rather than skipped because the first Janmashtami produces sixty
 * photographs, and a flat library is unusable from that day onward
 * (PHASE_5_PLAN assumption M6).
 *
 * `cover_media_id` is declared here but constrained in a later migration: the
 * two tables reference each other, so the foreign key cannot exist until
 * `media` does.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('albums', function (Blueprint $table) {
            $table->id();

            // Hindi is the source language and is always required on content.
            $table->string('title_hi', 200);
            $table->string('title_en', 200)->nullable();
            $table->text('description_hi')->nullable();
            $table->text('description_en')->nullable();

            // Shareable: /gallery?album=janmashtami-2026.
            $table->string('slug', 120)->unique();

            $table->unsignedBigInteger('cover_media_id')->nullable();

            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->string('status', 20)->default('draft');

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['status', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('albums');
    }
};

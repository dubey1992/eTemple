<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Bilingual CMS pages (spec Phase 1 entity fields).
 *
 * Hindi is the source language and is required; every English field is nullable
 * so a page can be published in Hindi alone and fall back cleanly.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pages', function (Blueprint $table) {
            $table->id();
            $table->string('slug', 120)->unique();

            $table->string('title_hi', 200);
            $table->string('title_en', 200)->nullable();
            $table->longText('content_hi');
            $table->longText('content_en')->nullable();

            $table->string('meta_title_hi', 200)->nullable();
            $table->string('meta_title_en', 200)->nullable();
            $table->string('meta_description_hi', 320)->nullable();
            $table->string('meta_description_en', 320)->nullable();

            $table->enum('status', ['draft', 'published'])->default('draft');
            $table->timestamp('published_at')->nullable();

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The public lookup is always (slug, status = published).
            $table->index(['status', 'slug']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pages');
    }
};

<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Configurable public navigation menu (spec Phase 1 feature).
 *
 * A dedicated table rather than a JSON blob so entries can be reordered and
 * hidden individually without rewriting the whole menu.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('navigation_items', function (Blueprint $table) {
            $table->id();
            $table->string('label_hi', 120);
            $table->string('label_en', 120)->nullable();
            // Internal path such as /about, or an absolute URL.
            $table->string('route', 300);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_visible')->default(true);
            $table->timestamps();

            $table->index(['is_visible', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('navigation_items');
    }
};

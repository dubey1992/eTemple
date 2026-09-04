<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Puja, aarti, bhajan-kirtan and festivals (spec Phase 4 entity).
 *
 * A row describes **when the event happens**, not one instance of it. The daily
 * aarti is one row with `recurrence = daily`, not a row a day: `start_at` fixes
 * the first occurrence, the time of day and the duration, and the rule columns
 * say how it repeats. Occurrences are expanded on read across a bounded window
 * (PHASE_4_PLAN assumptions E1 and E2).
 *
 * Storing expanded rows instead would mean an indefinite daily event generating
 * rows forever, and changing its time meaning a rewrite of thousands of them.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('events', function (Blueprint $table) {
            $table->id();

            $table->string('event_type', 40);

            // Hindi is the source language and is always required on content.
            $table->string('title_hi', 200);
            $table->string('title_en', 200)->nullable();
            $table->text('description_hi')->nullable();
            $table->text('description_en')->nullable();
            $table->string('venue_hi', 200)->nullable();
            $table->string('venue_en', 200)->nullable();

            // Stored UTC by Laravel's datetime cast; served with the temple's
            // offset so a client that ignores timezones still shows the right
            // local time (assumption E3).
            $table->dateTime('start_at');
            $table->dateTime('end_at')->nullable();

            $table->string('recurrence', 20)->default('none');
            $table->json('recurrence_days')->nullable();
            $table->date('recurrence_until')->nullable();

            // A URL, not an upload: file handling with its own MIME and size
            // validation is Phase 5 (assumption E8).
            $table->string('poster_url', 500)->nullable();

            $table->boolean('is_featured')->default(false);
            $table->string('status', 20)->default('draft');

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The public query filters on status and orders by start.
            $table->index(['status', 'start_at']);
            $table->index('is_featured');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('events');
    }
};

<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Notices the temple puts out (spec Phase 8 entity).
 *
 * Two things about this table are worth reading twice:
 *
 *  * **`status` and the schedule are different questions.** `status` is what a
 *    person decided — draft, published, archived. Whether an announcement is
 *    *currently showing* is computed on read from `start_at`, `end_at` and the
 *    clock, never written by a scheduler: a status changed by cron goes live
 *    only if cron is installed, and on modest hosting it may not be
 *    (PHASE_8_PLAN assumption N3).
 *
 *  * **Publishing and sending are separate columns because they are separate
 *    acts.** An unpublished announcement is invisible and fixable; a sent one
 *    is gone. `sent_at`, `sent_by` and `recipient_count` exist so that months
 *    later "was this ever sent, and to how many?" has an answer (N1, N6).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('announcements', function (Blueprint $table) {
            $table->id();

            // Hindi is the source language and is required; English is optional
            // and falls back to Hindi on read, as everywhere since Phase 1.
            $table->string('title_hi', 200);
            $table->string('title_en', 200)->nullable();
            $table->text('message_hi');
            $table->text('message_en')->nullable();

            // Prominence, not permission: an urgent announcement obeys exactly
            // the same schedule and publication rules as any other (N8).
            $table->string('priority', 20)->default('normal');

            $table->timestamp('start_at');
            // Null means "until somebody archives it".
            $table->timestamp('end_at')->nullable();

            // Which channels were chosen when it was sent. Stored as given, so
            // the record of what happened does not change when the catalogue
            // does.
            $table->json('channels')->nullable();

            $table->string('status', 20)->default('draft');

            // Optional "read more" — an internal route or an external link.
            $table->string('link_url', 500)->nullable();

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();

            // The send, recorded once. A second send is refused (N6).
            $table->timestamp('sent_at')->nullable();
            $table->foreignId('sent_by')->nullable()->constrained('users')->nullOnDelete();
            // What the queue was handed — not a delivery guarantee, which no
            // mail system can offer (N7).
            $table->unsignedInteger('recipient_count')->nullable();

            $table->timestamps();

            // The public query's shape: published, and inside its window.
            $table->index(['status', 'start_at']);
            $table->index('priority');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcements');
    }
};

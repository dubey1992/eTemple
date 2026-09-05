<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Messages devotees send the temple (spec Phase 7 entity).
 *
 * The first table in this project written to by somebody who is not signed in,
 * which changes what the columns are for:
 *
 *  * every row holds a stranger's name and a way to reach them, so nothing here
 *    is ever served to the public — there is no public read of an enquiry at
 *    any status (PHASE_7_PLAN assumption N1);
 *  * `submitted_ip_hash` is an HMAC, not an address. Recognising that thirty
 *    messages came from one place does not require knowing the place (N10);
 *  * there is no delete. `spam` moves noise out of the inbox and keeps the row,
 *    because a complaint that its subject can erase is not a complaint (N8).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('enquiries', function (Blueprint $table) {
            $table->id();

            // Given to the visitor on submission, and the only thing about the
            // enquiry the public response contains.
            $table->string('reference', 24)->unique();

            $table->string('name', 120);

            // Individually optional, but the request refuses a submission that
            // has neither: an enquiry nobody can answer is not an enquiry (N6).
            $table->string('mobile', 20)->nullable();
            $table->string('email', 190)->nullable();

            $table->string('category', 40);
            $table->text('message');

            // Which language the devotee asked to be *answered* in — an
            // instruction to whoever replies, not a display setting (N5).
            $table->string('preferred_language', 5)->default('hi');

            $table->string('status', 20)->default('new');

            // Null on delete rather than cascade: a committee member leaving
            // must not take the temple's enquiries with them.
            $table->foreignId('assigned_to')->nullable()
                ->constrained('users')->nullOnDelete();

            $table->timestamp('resolved_at')->nullable();
            $table->foreignId('resolved_by')->nullable()
                ->constrained('users')->nullOnDelete();

            // Abuse forensics that identify nobody outside this installation.
            $table->string('submitted_ip_hash', 64)->nullable();
            $table->string('submitted_user_agent', 255)->nullable();

            // When the acknowledgement was queued, so it is queued once.
            $table->timestamp('acknowledged_at')->nullable();

            $table->timestamps();

            // The inbox's default ordering: unanswered first, newest first.
            $table->index(['status', 'created_at']);
            $table->index('category');
            $table->index('submitted_ip_hash');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('enquiries');
    }
};

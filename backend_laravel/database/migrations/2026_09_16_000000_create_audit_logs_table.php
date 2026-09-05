<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Who did what, to which record, and when (spec Phase 11).
 *
 * Three things about this table are worth reading twice:
 *
 *  * **It is append-only.** Nothing in the application updates or deletes a
 *    row: the model refuses, there is no endpoint, and there is no service
 *    method. The single exception is `audit:prune`, which is a deliberate
 *    retention decision and writes a row saying what it removed
 *    (PHASE_11_PLAN assumptions S3 and S4).
 *
 *  * **`before_data` and `after_data` hold only what changed**, with passwords,
 *    hashes and tokens removed on the way in. They do carry personal details
 *    when personal details are what changed — "the amount on this donation was
 *    edited" is the question the log exists to answer, and a redacted log
 *    answers nothing. That makes this table itself a store of personal data,
 *    which is why reading it needs its own permission and there is no export
 *    (S5).
 *
 *  * **The actor's IP is stored raw**, unlike an enquirer's, which is hashed.
 *    A committee member is a named account-holder acting administratively, and
 *    "which machine approved this payment" is a question the temple may need
 *    to answer. An anonymous villager filling in a form is not the same case
 *    (S6).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();

            // Nullable, and deliberately `nullOnDelete`: the trail outlives the
            // account. Deleting a member must not erase what they approved, and
            // `actor_name` keeps the row readable once the account is gone.
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_name', 200)->nullable();
            $table->string('actor_role', 60)->nullable();

            // A code from App\Support\AuditAction, not free text: a log whose
            // vocabulary drifts cannot be filtered.
            $table->string('action', 60);

            // The record it happened to. `entity_type` is a short code
            // ("donation", "transaction") rather than a class name, so renaming
            // a class does not rewrite history.
            $table->string('entity_type', 40)->nullable();
            $table->unsignedBigInteger('entity_id')->nullable();

            // Something a person can read without joining anything: the receipt
            // number, the donor's name, the page title.
            $table->string('entity_label', 200)->nullable();

            $table->json('before_data')->nullable();
            $table->json('after_data')->nullable();

            // Free text for the cases where the change is not a diff: a
            // reversal reason, the filters an export was run under.
            $table->text('context')->nullable();

            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 500)->nullable();

            // `created_at` only. There is no `updated_at` because there is no
            // update — the absence of the column is itself a statement.
            $table->timestamp('created_at')->useCurrent();

            // The three questions actually asked of this table: what happened
            // recently, what happened to this record, and what did this person
            // do.
            $table->index('created_at');
            $table->index(['entity_type', 'entity_id']);
            $table->index(['user_id', 'created_at']);
            $table->index(['action', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};

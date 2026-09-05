<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Donations received by the temple (spec Phase 6 entity).
 *
 * This is the first table whose rows an outside auditor may one day read, and
 * three of the phase's four requirements are about **not being able to change
 * history**. That shapes the whole shape of it:
 *
 *  * `amount_paise` is an integer, never a float — a rupee total that is exact
 *    until it is summed is not exact (PHASE_6_PLAN assumption N1);
 *  * `receipt_number` is null until the donation is verified, then assigned
 *    once and never changed; the unique index, not the application, is what
 *    guarantees two treasurers confirming at the same moment cannot produce the
 *    same number (N2);
 *  * there is no delete. Reversal writes a reason, a time and an actor onto the
 *    row and the row stays (N4).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donations', function (Blueprint $table) {
            $table->id();

            // Null while pending: a number that exists corresponds to a receipt
            // that was really given, so the sequence has no gaps to explain.
            $table->string('receipt_number', 40)->nullable()->unique();

            $table->string('donor_name', 200);

            // Never public, at any status, in any aggregate (assumption N5).
            $table->string('donor_phone', 20)->nullable();
            $table->string('donor_address', 500)->nullable();

            // The donor asked not to be named in any future listing. Their own
            // receipt still names them — it is their receipt.
            $table->boolean('is_anonymous')->default(false);

            // Paise, not rupees, and an integer, not a decimal read back into
            // PHP arithmetic. Every total in this phase and in Phase 9 is exact
            // addition.
            $table->unsignedBigInteger('amount_paise');

            // The day the money was given, which may be before it was entered.
            $table->date('donation_date');

            $table->string('payment_mode', 30);

            // Required for every mode except cash: without it a bank entry
            // cannot be matched to a donation, which is the whole point of the
            // pending → confirmed step (assumption N9).
            $table->string('reference_number', 100)->nullable();

            $table->string('purpose', 30)->default('general');
            $table->text('notes')->nullable();

            $table->string('status', 20)->default('pending');

            $table->timestamp('confirmed_at')->nullable();
            $table->foreignId('confirmed_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamp('reversed_at')->nullable();
            $table->foreignId('reversed_by')->nullable()->constrained('users')->nullOnDelete();

            // Required when reversing: "why was five thousand rupees removed
            // from the books" is the first question an auditor asks, and the
            // answer must not depend on somebody's memory.
            $table->string('reversal_reason', 500)->nullable();

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The admin list filters on status and orders by date; the totals
            // sum over the same pair.
            $table->index(['status', 'donation_date']);
            $table->index('donation_date');
            $table->index('payment_mode');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('donations');
    }
};

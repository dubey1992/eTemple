<?php

declare(strict_types=1);

use App\Support\DonationPurpose;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * What the temple's money is received for and spent on (spec Phase 9 entity).
 *
 * Codes rather than free text, for the reason {@see DonationPurpose}
 * gives: "how much went on electricity this year" is not a question you can
 * answer over a text box that has held "bijli", "Electricity" and "बिजली".
 *
 * A category belongs to **one side of the books**. "Maintenance" as both an
 * income and an expense category would make a breakdown ambiguous, and the one
 * question the public page has to answer without ambiguity is which way the
 * money went.
 *
 * There is no delete: a category that has ever been used is deactivated
 * instead, so historical rows keep their meaning (PHASE_9_PLAN assumption N4).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounting_categories', function (Blueprint $table) {
            $table->id();

            // `donation` is reserved: donated income is counted from the
            // donation register, never re-entered here (assumption N1).
            $table->string('code', 50)->unique();

            $table->string('type', 20);

            // Stored independently, as every other pair in this project. An
            // absent English name falls back to the Hindi on read; it is never
            // filled in with a copy of it.
            $table->string('name_hi', 150);
            $table->string('name_en', 150)->nullable();
            $table->string('description_hi', 500)->nullable();
            $table->string('description_en', 500)->nullable();

            $table->unsignedInteger('sort_order')->default(0);

            // Deactivation, not deletion: the picker stops offering it and
            // every transaction that used it still reads correctly.
            $table->boolean('is_active')->default(true);

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The shape of every picker query.
            $table->index(['type', 'is_active', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('accounting_categories');
    }
};

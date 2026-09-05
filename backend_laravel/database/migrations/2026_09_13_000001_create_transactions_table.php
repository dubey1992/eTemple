<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The temple's income and expenditure (spec Phase 9 entity).
 *
 * Sibling to `donations`, and shaped by the same three rules: the amount is an
 * integer number of paise, the row is never deleted, and a figure that has been
 * published cannot be quietly edited afterwards.
 *
 * Two columns are worth reading twice:
 *
 *  * **`attachment_path`, not `attachment_url`.** The specification names the
 *    column `attachment_url`; it is a path on a private disk here, and the
 *    rename is deliberate. A column called `_url` is eventually rendered as
 *    one — that is what the name invites — and these files are shop bills
 *    carrying a trader's name, telephone number and signature. They are served
 *    only by an authenticated endpoint that streams the bytes, and the path is
 *    never serialized (PHASE_9_PLAN assumption N5).
 *
 *  * **`payee_name` reaches no public response.** The public page publishes
 *    category totals, not a list of who the temple paid (assumption N6).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();

            // Denormalised from the category on purpose: every summary query
            // filters or groups on it, and the service keeps the two in step by
            // refusing a transaction whose type disagrees with its category's.
            $table->string('type', 20);

            // restrictOnDelete, so the database refuses what the service
            // refuses: a category in use cannot be removed from under its rows.
            $table->foreignId('category_id')->constrained('accounting_categories')->restrictOnDelete();

            // Paise, integer. Every total in this phase is exact addition.
            $table->unsignedBigInteger('amount_paise');

            // The day the money moved, which may be before it was entered.
            $table->date('transaction_date');

            // Reuses Phase 6's catalogue. Everything but cash carries a
            // reference the treasurer can match against a statement.
            $table->string('payment_mode', 30);
            $table->string('reference_number', 100)->nullable();

            // A treasurer's working note about one payment. Not bilingual and
            // not published: it is written once, for the books.
            $table->text('description')->nullable();

            // Who was paid, or who paid. Never public.
            $table->string('payee_name', 200)->nullable();

            // The bill. Private disk; see the class docblock.
            $table->string('attachment_path', 500)->nullable();
            $table->string('attachment_name', 255)->nullable();
            $table->unsignedBigInteger('attachment_size')->nullable();
            $table->string('attachment_mime', 100)->nullable();

            $table->string('status', 20)->default('pending');

            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamp('reversed_at')->nullable();
            $table->foreignId('reversed_by')->nullable()->constrained('users')->nullOnDelete();

            // Required when reversing, exactly as for a donation: the money has
            // already been counted in a published total, so its removal needs a
            // stated reason and not somebody's memory.
            $table->string('reversal_reason', 500)->nullable();

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The four shapes the register, the summary and the public
            // transparency query actually use.
            $table->index(['status', 'transaction_date']);
            $table->index('transaction_date');
            $table->index(['type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};

<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The singleton row that decides whether the temple's books are public, and
 * where they start (spec Phase 9).
 *
 * Two things live here and both are refusals of a default:
 *
 *  * **`is_published` is false.** A ledger that publishes itself the moment the
 *    first row is saved is only ever built by accident. Half-entered books are
 *    not transparency, they are a misstatement with the temple's name on it
 *    (PHASE_9_PLAN assumption N7).
 *
 *  * **`opening_balance_paise`.** The temple did not begin with an empty cash
 *    box on the day this software was installed. Without it, the published
 *    balance understates what the temple holds by whatever was already there
 *    (assumption N8).
 *
 * Read through `AccountingSettingService::current()` so exactly one row exists,
 * as with `site_settings`, `temple_profiles` and `donation_settings`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounting_settings', function (Blueprint $table) {
            $table->id();

            $table->boolean('is_published')->default(false);

            // Signed: a temple that starts in deficit should be able to say so.
            $table->bigInteger('opening_balance_paise')->default(0);
            $table->date('opening_balance_date')->nullable();

            $table->text('intro_hi')->nullable();
            $table->text('intro_en')->nullable();
            $table->text('note_hi')->nullable();
            $table->text('note_en')->nullable();

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('accounting_settings');
    }
};

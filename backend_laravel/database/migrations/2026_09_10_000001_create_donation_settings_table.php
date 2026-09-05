<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Where devotees may send money (spec Phase 6, `donation_settings`).
 *
 * A singleton row like `site_settings` and `temple_profiles`, read through a
 * service so exactly one exists.
 *
 * `is_published` gates the whole block and every detail is optional, so an
 * unconfigured site shows the approved prototype's card with an empty state
 * rather than invented bank details (PHASE_6_PLAN assumption N7).
 *
 * `account_number` is stored **exactly as the committee types it**. The
 * prototype masks it (`XXXX XXXX 1234`); whether to mask, and how, is their
 * decision and their bank's policy, not ours to guess.
 *
 * Editing this row needs `donations.manage`, not `content.manage`: changing the
 * published UPI id is the single most valuable attack on this site, so it sits
 * behind the money permission (assumption N6).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donation_settings', function (Blueprint $table) {
            $table->id();

            $table->string('upi_id', 120)->nullable();
            $table->string('bank_name', 150)->nullable();
            $table->string('account_name', 150)->nullable();
            $table->string('account_number', 60)->nullable();
            $table->string('ifsc', 20)->nullable();

            // Chosen from the media library, so the Phase 5 deletion guard can
            // refuse to delete a QR code the donation page is still showing
            // (assumption N13).
            $table->string('qr_url', 500)->nullable();

            // Hindi is the source language and English is optional, as
            // everywhere else in this application.
            $table->text('intro_hi')->nullable();
            $table->text('intro_en')->nullable();
            $table->text('note_hi')->nullable();
            $table->text('note_en')->nullable();

            $table->boolean('is_published')->default(false);

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('donation_settings');
    }
};

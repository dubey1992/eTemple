<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The temple management committee.
 *
 * These rows describe named villagers, not staff of a company, so the personal
 * columns are governed by a recorded consent rather than a checkbox:
 *
 *   - `is_published`        does this person appear on the public site at all;
 *   - `contact_consent_at`  the stored fact that they agreed their personal
 *                           details may be published, with the account that
 *                           recorded it;
 *   - `show_*_publicly`     which specific details may be shown.
 *
 * A `show_*_publicly` flag is honoured publicly only while consent is recorded.
 * That rule is enforced in the service, on withdrawal, and again in the public
 * resource (PHASE_3_PLAN assumption D4) — this is the one table in the project
 * where a bug publishes somebody's phone number.
 *
 * Everything defaults to unpublished and unconsented. Publishing a person is a
 * decision somebody has to make on purpose.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('committee_members', function (Blueprint $table) {
            $table->id();

            // Hindi is the source language and is always required on content.
            $table->string('name_hi', 160);
            $table->string('name_en', 160)->nullable();
            $table->string('designation_hi', 160);
            $table->string('designation_en', 160)->nullable();
            $table->text('bio_hi')->nullable();
            $table->text('bio_en')->nullable();

            // Personal details — never public without recorded consent.
            $table->string('phone', 40)->nullable();
            $table->string('email', 191)->nullable();
            $table->string('photo_url', 500)->nullable();

            $table->date('tenure_start')->nullable();
            $table->date('tenure_end')->nullable();

            $table->boolean('is_published')->default(false);
            $table->timestamp('contact_consent_at')->nullable();
            $table->foreignId('consent_recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->boolean('show_phone_publicly')->default(false);
            $table->boolean('show_email_publicly')->default(false);
            $table->boolean('show_photo_publicly')->default(false);

            $table->unsignedInteger('sort_order')->default(0);

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The public list filters on publication and orders by sort_order.
            $table->index(['is_published', 'sort_order']);
            // A tenure that has ended drops off the public list.
            $table->index('tenure_end');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('committee_members');
    }
};

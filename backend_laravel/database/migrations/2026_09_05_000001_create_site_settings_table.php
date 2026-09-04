<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Singleton row holding the site-wide configurable content: hero tagline,
 * footer, contact/address block and default SEO metadata.
 *
 * The specification names the endpoint but not the fields; see PHASE_1_PLAN
 * assumption B1. The address lives here for Phase 1 and moves to the
 * authoritative temple_profile in Phase 3 (assumption B2).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('site_settings', function (Blueprint $table) {
            $table->id();

            $table->string('tagline_hi', 200)->nullable();
            $table->string('tagline_en', 200)->nullable();
            $table->string('footer_text_hi', 400)->nullable();
            $table->string('footer_text_en', 400)->nullable();

            $table->string('address_line1', 200)->nullable();
            $table->string('address_line2', 200)->nullable();
            $table->string('village', 120)->nullable();
            $table->string('panchayat', 120)->nullable();
            $table->string('police_station', 120)->nullable();
            $table->string('district', 120)->nullable();
            $table->string('state', 120)->nullable();
            $table->string('postal_code', 20)->nullable();
            $table->string('country', 120)->nullable();

            $table->string('contact_phone', 40)->nullable();
            $table->string('contact_email', 191)->nullable();
            $table->string('map_url', 500)->nullable();
            $table->json('social_links')->nullable();

            $table->string('default_meta_title_hi', 200)->nullable();
            $table->string('default_meta_title_en', 200)->nullable();
            $table->string('default_meta_description_hi', 320)->nullable();
            $table->string('default_meta_description_en', 320)->nullable();

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('site_settings');
    }
};

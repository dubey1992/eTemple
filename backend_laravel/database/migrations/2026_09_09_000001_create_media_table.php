<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The media library (spec Phase 5 entity).
 *
 * A row is either an uploaded **photograph** or a linked **video**, never both
 * (PHASE_5_PLAN assumption M1). Videos are links because a ten-minute aarti
 * recording is hundreds of megabytes, and village shared hosting has neither
 * the disk nor the outbound bandwidth to serve it.
 *
 * Photographs are stored as three re-encoded variants and no original: nothing
 * on this site ever displays a 4000-pixel phone photograph, so keeping one
 * costs disk for a view that never happens (assumption M4).
 *
 * `mime_type` is the type the server **detected** from the bytes, never the one
 * the browser claimed (assumption M2), and `file_path` is a generated name — no
 * value derived from user input reaches a filesystem path.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media', function (Blueprint $table) {
            $table->id();

            // Nullable and nullOnDelete: an album is an arrangement, and losing
            // an arrangement must never lose the photographs (assumption M6).
            $table->foreignId('album_id')->nullable()->constrained('albums')->nullOnDelete();

            $table->string('media_type', 20);

            $table->string('title_hi', 200);
            $table->string('title_en', 200)->nullable();
            $table->text('caption_hi')->nullable();
            $table->text('caption_en')->nullable();

            // Disk-relative, never absolute: the API builds URLs from the disk
            // so changing domain is not a data migration (assumption M5).
            $table->string('file_path', 500)->nullable();
            $table->string('thumb_path', 500)->nullable();
            $table->string('medium_path', 500)->nullable();
            $table->string('large_path', 500)->nullable();

            // Videos only. The provider is allow-listed and the reference is a
            // validated id, so nothing user-supplied is ever interpolated into
            // an embed URL.
            $table->string('external_url', 500)->nullable();
            $table->string('provider', 30)->nullable();
            $table->string('provider_ref', 100)->nullable();
            $table->string('thumbnail_url', 500)->nullable();

            $table->string('mime_type', 100)->nullable();
            $table->unsignedInteger('byte_size')->nullable();
            $table->unsignedSmallInteger('width')->nullable();
            $table->unsignedSmallInteger('height')->nullable();

            // Kept as a label to show the uploader what they picked. It is
            // escaped on output and is never used to build a path.
            $table->string('original_name', 255)->nullable();

            // sha-256 of the stored image, so re-uploading the same photograph
            // can be recognised instead of silently duplicated.
            $table->char('checksum', 64)->nullable();

            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->string('status', 20)->default('draft');

            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            // The public gallery filters on status and type, then orders.
            $table->index(['status', 'media_type', 'sort_order']);
            $table->index(['album_id', 'sort_order']);
            $table->index('checksum');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media');
    }
};

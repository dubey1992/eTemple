<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Login history (spec Phase 2 feature).
 *
 * Every attempt is recorded, not only the successful ones — a trail of failures
 * is what makes the history useful for spotting someone probing an account.
 * `user_id` is null when the e-mail matched no account, and the typed e-mail is
 * kept so those attempts are still visible.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('login_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('email', 191);
            $table->enum('outcome', ['success', 'invalid_credentials', 'inactive', 'blocked']);
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 500)->nullable();
            $table->timestamp('created_at')->nullable();

            $table->index(['user_id', 'created_at']);
            $table->index(['email', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('login_attempts');
    }
};

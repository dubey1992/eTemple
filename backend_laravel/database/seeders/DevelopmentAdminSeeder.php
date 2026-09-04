<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * DEVELOPMENT / DEMO DATA ONLY.
 *
 * Creates a single Super Admin account so the Flutter admin shell can be exercised
 * locally. It refuses to run in production and it refuses to invent a password:
 * DEV_ADMIN_EMAIL and DEV_ADMIN_PASSWORD must be set in the local .env.
 *
 * This seeder must never be part of a production seed run.
 */
class DevelopmentAdminSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            $this->command?->warn('[dev-seed] Skipped: DevelopmentAdminSeeder never runs in production.');

            return;
        }

        $email = (string) env('DEV_ADMIN_EMAIL', '');
        $password = (string) env('DEV_ADMIN_PASSWORD', '');

        if ($email === '' || $password === '') {
            $this->command?->warn(
                '[dev-seed] Skipped: set DEV_ADMIN_EMAIL and DEV_ADMIN_PASSWORD in .env to create a local admin.'
            );

            return;
        }

        $role = Role::query()->where('slug', Role::SUPER_ADMIN)->firstOrFail();

        User::query()->updateOrCreate(
            ['email' => $email],
            [
                'first_name' => 'Development',
                'last_name' => 'Admin',
                'password' => $password,
                'role_id' => $role->id,
                'status' => User::STATUS_ACTIVE,
            ],
        );

        $this->command?->info("[dev-seed] Development Super Admin ready: {$email}");
    }
}

<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Reference data and structure required in every environment, including
        // production. Both are idempotent and contain no invented content.
        $this->call(RoleSeeder::class);
        $this->call(PageStructureSeeder::class);

        // Clearly separated development/demo data — both no-op in production.
        $this->call(DevelopmentAdminSeeder::class);
        $this->call(DevelopmentContentSeeder::class);
    }
}

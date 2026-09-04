<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\DevelopmentAdminSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RoleSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_seeds_exactly_the_five_specified_roles(): void
    {
        $this->seed(RoleSeeder::class);

        $this->assertSame(5, Role::query()->count());
        $this->assertEqualsCanonicalizing(
            Role::ALL,
            Role::query()->pluck('slug')->all(),
        );
    }

    public function test_it_is_idempotent(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(RoleSeeder::class);

        $this->assertSame(5, Role::query()->count());
    }

    public function test_it_does_not_grant_permission_keys_in_phase_zero(): void
    {
        $this->seed(RoleSeeder::class);

        $this->assertNull(Role::query()->where('slug', Role::SUPER_ADMIN)->value('permissions'));
    }

    public function test_development_admin_seeder_creates_nothing_without_explicit_credentials(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(DevelopmentAdminSeeder::class);

        $this->assertSame(0, User::query()->count());
    }
}

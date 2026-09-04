<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
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

    public function test_super_admin_stores_no_permission_set(): void
    {
        $this->seed(RoleSeeder::class);

        // Computed, never stored: a stored set could drift from the catalogue
        // and lock the temple out of its own administration.
        $superAdmin = Role::query()->where('slug', Role::SUPER_ADMIN)->firstOrFail();

        $this->assertNull($superAdmin->permissions);
        $this->assertSame(Permission::all(), $superAdmin->effectivePermissions());
    }

    public function test_it_seeds_the_default_permission_matrix(): void
    {
        $this->seed(RoleSeeder::class);

        $contentManager = Role::query()->where('slug', Role::CONTENT_MANAGER)->firstOrFail();
        $treasurer = Role::query()->where('slug', Role::TREASURER)->firstOrFail();

        $this->assertContains(Permission::CONTENT_MANAGE, $contentManager->effectivePermissions());
        $this->assertNotContains(Permission::ACCOUNTS_VIEW, $contentManager->effectivePermissions());
        $this->assertContains(Permission::ACCOUNTS_MANAGE, $treasurer->effectivePermissions());
    }

    public function test_reseeding_does_not_undo_customised_permissions(): void
    {
        $this->seed(RoleSeeder::class);

        $viewer = Role::query()->where('slug', Role::VIEWER)->firstOrFail();
        $viewer->forceFill(['permissions' => [Permission::CONTENT_MANAGE]])->save();

        // A routine deploy re-runs seeders; it must not silently reverse the
        // committee's access decisions.
        $this->seed(RoleSeeder::class);

        $this->assertSame([Permission::CONTENT_MANAGE], $viewer->fresh()->effectivePermissions());
    }

    public function test_development_admin_seeder_creates_nothing_without_explicit_credentials(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(DevelopmentAdminSeeder::class);

        $this->assertSame(0, User::query()->count());
    }
}

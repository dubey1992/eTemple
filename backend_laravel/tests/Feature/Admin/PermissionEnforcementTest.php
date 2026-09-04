<?php

declare(strict_types=1);

namespace Tests\Feature\Admin;

use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The specification's central rule for this phase: "Hiding a Flutter button is
 * never the authorization control; backend authorization remains mandatory."
 *
 * Every case here calls the API directly with a role that should be refused, so
 * a passing UI test could never stand in for these.
 */
class PermissionEnforcementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function actingAsRole(string $slug): User
    {
        $user = User::factory()->withRole($slug)->create();
        $this->actingAs($user, 'web');

        return $user;
    }

    /** @return array<string, array{string}> */
    public static function rolesWithoutUserManagement(): array
    {
        return [
            'treasurer' => [Role::TREASURER],
            'content manager' => [Role::CONTENT_MANAGER],
            'viewer' => [Role::VIEWER],
        ];
    }

    /** @return array<string, array{string}> */
    public static function rolesWithoutRoleManagement(): array
    {
        return [
            'admin' => [Role::ADMIN],
            'treasurer' => [Role::TREASURER],
            'content manager' => [Role::CONTENT_MANAGER],
            'viewer' => [Role::VIEWER],
        ];
    }

    #[DataProvider('rolesWithoutUserManagement')]
    public function test_a_role_without_users_view_cannot_list_accounts(string $slug): void
    {
        $this->actingAsRole($slug);

        $this->getJson('/api/admin/users')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    #[DataProvider('rolesWithoutUserManagement')]
    public function test_a_role_without_users_manage_cannot_create_an_account(string $slug): void
    {
        $this->actingAsRole($slug);

        $this->postJson('/api/admin/users', [
            'first_name' => 'Intruder',
            'email' => 'intruder@thakurbari.test',
            'role_id' => Role::query()->where('slug', Role::SUPER_ADMIN)->value('id'),
        ])->assertForbidden();

        $this->assertSame(0, User::query()->where('email', 'intruder@thakurbari.test')->count());
    }

    #[DataProvider('rolesWithoutRoleManagement')]
    public function test_a_role_without_roles_manage_cannot_rewrite_the_matrix(string $slug): void
    {
        $this->actingAsRole($slug);
        $viewer = Role::query()->where('slug', Role::VIEWER)->firstOrFail();

        $this->putJson("/api/admin/roles/{$viewer->id}/permissions", [
            'permissions' => Permission::all(),
        ])->assertForbidden();

        // The attempt changed nothing.
        $this->assertNotContains(
            Permission::USERS_MANAGE,
            $viewer->fresh()->effectivePermissions(),
        );
    }

    public function test_an_admin_may_manage_users_but_not_roles(): void
    {
        $this->actingAsRole(Role::ADMIN);
        $viewer = Role::query()->where('slug', Role::VIEWER)->firstOrFail();

        $this->getJson('/api/admin/users')->assertOk();
        $this->putJson("/api/admin/roles/{$viewer->id}/permissions", ['permissions' => []])
            ->assertForbidden();
    }

    public function test_a_super_admin_passes_every_check(): void
    {
        $this->actingAsRole(Role::SUPER_ADMIN);
        $viewer = Role::query()->where('slug', Role::VIEWER)->firstOrFail();

        $this->getJson('/api/admin/users')->assertOk();
        $this->getJson('/api/admin/roles')->assertOk();
        $this->getJson('/api/admin/permissions')->assertOk();
        $this->getJson('/api/admin/pages')->assertOk();
        $this->putJson("/api/admin/roles/{$viewer->id}/permissions", ['permissions' => []])
            ->assertOk();
    }

    public function test_login_history_is_gated_separately_from_user_administration(): void
    {
        // Being able to administer accounts is not the same right as seeing who
        // tried to sign in to them. The default roles happen to grant both
        // together, so this configures a role that has one and not the other -
        // which is exactly what the matrix exists to make possible.
        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();
        $role->forceFill([
            'permissions' => [Permission::USERS_VIEW, Permission::USERS_MANAGE],
        ])->save();

        $user = $this->actingAsRole(Role::VIEWER);
        $target = User::factory()->withRole(Role::ADMIN)->create();

        $this->assertTrue($user->hasPermission(Permission::USERS_MANAGE));
        $this->assertFalse($user->hasPermission(Permission::SECURITY_VIEW));

        $this->getJson('/api/admin/users')->assertOk();
        $this->getJson("/api/admin/users/{$target->id}/login-history")->assertForbidden();
    }

    public function test_a_guest_reaches_none_of_the_admin_endpoints(): void
    {
        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();
        $user = User::factory()->withRole(Role::VIEWER)->create();

        $this->getJson('/api/admin/users')->assertUnauthorized();
        $this->getJson('/api/admin/roles')->assertUnauthorized();
        $this->getJson('/api/admin/permissions')->assertUnauthorized();
        $this->putJson("/api/admin/roles/{$role->id}/permissions", ['permissions' => []])
            ->assertUnauthorized();
        $this->getJson("/api/admin/users/{$user->id}/login-history")->assertUnauthorized();
    }

    public function test_a_blocked_super_admin_is_refused_before_any_permission_check(): void
    {
        // Gate::before must not resurrect a disabled account.
        $user = User::factory()->withRole(Role::SUPER_ADMIN)->blocked()->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/admin/users')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_BLOCKED');

        $this->assertFalse($user->hasPermission(Permission::USERS_MANAGE));
        $this->assertSame([], $user->effectivePermissions());
    }

    public function test_effective_permissions_ignore_stale_keys(): void
    {
        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();
        $role->forceFill(['permissions' => [Permission::CONTENT_VIEW, 'legacy.removed', 42]])->save();

        $this->assertSame([Permission::CONTENT_VIEW], $role->fresh()->effectivePermissions());
    }
}

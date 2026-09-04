<?php

declare(strict_types=1);

namespace Tests\Feature\Admin;

use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RoleMatrixTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->superAdmin = User::factory()->withRole(Role::SUPER_ADMIN)->create();
    }

    public function test_the_catalogue_is_exposed_grouped_by_module(): void
    {
        $response = $this->actingAs($this->superAdmin, 'web')
            ->getJson('/api/admin/permissions')
            ->assertOk()
            ->assertJsonStructure([
                'data' => ['modules' => [['module', 'label', 'phase', 'permissions' => [['key', 'label']]]]],
            ]);

        $keys = [];
        foreach ($response->json('data.modules') as $module) {
            foreach ($module['permissions'] as $permission) {
                $keys[] = $permission['key'];
            }
        }

        $this->assertEqualsCanonicalizing(Permission::all(), $keys);
    }

    public function test_roles_are_listed_with_their_effective_permissions(): void
    {
        $response = $this->actingAs($this->superAdmin, 'web')
            ->getJson('/api/admin/roles')
            ->assertOk()
            ->assertJsonCount(5, 'data');

        $bySlug = collect($response->json('data'))->keyBy('slug');

        // Super Admin is reported as holding everything, and as not editable.
        $this->assertSame(Permission::all(), $bySlug[Role::SUPER_ADMIN]['permissions']);
        $this->assertFalse($bySlug[Role::SUPER_ADMIN]['is_editable']);
        $this->assertTrue($bySlug[Role::VIEWER]['is_editable']);

        $this->assertContains(Permission::CONTENT_MANAGE, $bySlug[Role::CONTENT_MANAGER]['permissions']);
        $this->assertNotContains(Permission::DONATIONS_VIEW, $bySlug[Role::CONTENT_MANAGER]['permissions']);
    }

    public function test_the_role_list_reports_how_many_accounts_hold_each_role(): void
    {
        User::factory()->withRole(Role::VIEWER)->count(2)->create();

        $response = $this->actingAs($this->superAdmin, 'web')->getJson('/api/admin/roles')->assertOk();
        $bySlug = collect($response->json('data'))->keyBy('slug');

        $this->assertSame(2, $bySlug[Role::VIEWER]['user_count']);
        $this->assertSame(1, $bySlug[Role::SUPER_ADMIN]['user_count']);
    }

    public function test_a_permission_set_can_be_replaced(): void
    {
        $viewer = Role::query()->where('slug', Role::VIEWER)->firstOrFail();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$viewer->id}/permissions", [
                'permissions' => [Permission::CONTENT_MANAGE, Permission::CONTENT_VIEW],
            ])
            ->assertOk()
            ->assertJsonPath('data.slug', Role::VIEWER);

        // Stored in catalogue order, de-duplicated - not in whatever order the UI sent.
        $this->assertSame(
            [Permission::CONTENT_VIEW, Permission::CONTENT_MANAGE],
            $viewer->fresh()->effectivePermissions(),
        );
    }

    public function test_granting_a_permission_immediately_changes_what_a_user_may_do(): void
    {
        $viewer = User::factory()->withRole(Role::VIEWER)->create();

        $this->actingAs($viewer, 'web')->getJson('/api/admin/pages')->assertForbidden();

        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();
        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$role->id}/permissions", [
                'permissions' => [Permission::CONTENT_VIEW, Permission::CONTENT_MANAGE],
            ])
            ->assertOk();

        $this->actingAs($viewer->fresh(), 'web')->getJson('/api/admin/pages')->assertOk();
    }

    public function test_revoking_a_permission_immediately_closes_the_door(): void
    {
        $manager = User::factory()->withRole(Role::CONTENT_MANAGER)->create();

        $this->actingAs($manager, 'web')->getJson('/api/admin/pages')->assertOk();

        $role = Role::query()->where('slug', Role::CONTENT_MANAGER)->firstOrFail();
        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$role->id}/permissions", [
                'permissions' => [Permission::CONTENT_VIEW],
            ])
            ->assertOk();

        $this->actingAs($manager->fresh(), 'web')->getJson('/api/admin/pages')->assertForbidden();
    }

    public function test_an_empty_set_is_accepted_and_means_no_access(): void
    {
        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$role->id}/permissions", ['permissions' => []])
            ->assertOk();

        $this->assertSame([], $role->fresh()->effectivePermissions());
    }

    public function test_unknown_keys_are_rejected_by_name_rather_than_stored(): void
    {
        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();
        $before = $role->effectivePermissions();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$role->id}/permissions", [
                'permissions' => [Permission::CONTENT_VIEW, 'content.destroy', 'made.up'],
            ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonFragment(['permissions' => ['Unknown permission keys: content.destroy, made.up']]);

        $this->assertSame($before, $role->fresh()->effectivePermissions());
    }

    public function test_the_permissions_field_is_required(): void
    {
        $role = Role::query()->where('slug', Role::VIEWER)->firstOrFail();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$role->id}/permissions", [])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['permissions']]]);
    }
}

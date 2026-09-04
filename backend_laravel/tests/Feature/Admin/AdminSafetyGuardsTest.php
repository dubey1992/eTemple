<?php

declare(strict_types=1);

namespace Tests\Feature\Admin;

use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * The refusals that keep the temple in control of its own site.
 *
 * A permission system that lets the last administrator demote themselves, or
 * lets someone strip Super Admin, is not a security feature — it is an outage
 * waiting for a bad afternoon. Each guard is proven to block **and** proven not
 * to over-block.
 */
class AdminSafetyGuardsTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        Notification::fake();
        $this->superAdmin = User::factory()->withRole(Role::SUPER_ADMIN)->create();
    }

    private function roleId(string $slug): int
    {
        return (int) Role::query()->where('slug', $slug)->value('id');
    }

    /** @param array<string, mixed> $overrides */
    private function payloadFor(User $user, array $overrides = []): array
    {
        return array_merge([
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'email' => $user->email,
            'mobile' => $user->mobile,
            'role_id' => $user->role_id,
            'status' => $user->status,
        ], $overrides);
    }

    public function test_the_last_active_super_admin_cannot_be_demoted(): void
    {
        $second = User::factory()->withRole(Role::SUPER_ADMIN)->create();

        // Demoting one of two is fine.
        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/users/{$second->id}", $this->payloadFor($second, [
                'role_id' => $this->roleId(Role::VIEWER),
            ]))
            ->assertOk();

        // Now only one remains, and it may not be demoted.
        $this->actingAs($second->fresh(), 'web');
        $this->actingAs(User::factory()->withRole(Role::SUPER_ADMIN)->create(), 'web');

        $onlySuper = $this->superAdmin;
        $extra = User::query()->whereRelation('role', 'slug', Role::SUPER_ADMIN)
            ->whereKeyNot($onlySuper->getKey())->get();
        foreach ($extra as $user) {
            $user->forceFill(['status' => User::STATUS_INACTIVE])->save();
        }

        $this->actingAs($onlySuper, 'web')
            ->putJson("/api/admin/users/{$onlySuper->id}", $this->payloadFor($onlySuper, [
                'role_id' => $this->roleId(Role::ADMIN),
            ]))
            ->assertStatus(422);

        $this->assertTrue($onlySuper->fresh()->isSuperAdmin());
    }

    public function test_the_last_active_super_admin_cannot_be_deactivated(): void
    {
        $other = User::factory()->withRole(Role::ADMIN)->create();

        $this->actingAs($other, 'web');
        // Give the acting admin the right to manage users, then try to disable
        // the only Super Admin.
        $adminRole = Role::query()->where('slug', Role::ADMIN)->firstOrFail();
        $this->assertTrue($other->hasPermission(Permission::USERS_MANAGE), 'precondition');
        $this->assertNotNull($adminRole);

        $this->actingAs($other, 'web')
            ->putJson("/api/admin/users/{$this->superAdmin->id}", $this->payloadFor($this->superAdmin, [
                'status' => User::STATUS_BLOCKED,
            ]))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['status']]]);

        $this->assertTrue($this->superAdmin->fresh()->isActive());
    }

    public function test_a_super_admin_may_be_deactivated_when_another_remains(): void
    {
        $second = User::factory()->withRole(Role::SUPER_ADMIN)->create();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/users/{$second->id}", $this->payloadFor($second, [
                'status' => User::STATUS_INACTIVE,
            ]))
            ->assertOk();

        $this->assertFalse($second->fresh()->isActive());
    }

    public function test_an_administrator_cannot_change_their_own_role(): void
    {
        $admin = User::factory()->withRole(Role::ADMIN)->create();

        $this->actingAs($admin, 'web')
            ->putJson("/api/admin/users/{$admin->id}", $this->payloadFor($admin, [
                'role_id' => $this->roleId(Role::SUPER_ADMIN),
            ]))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['role_id']]]);

        $this->assertTrue($admin->fresh()->hasRole(Role::ADMIN));
    }

    public function test_an_administrator_cannot_deactivate_themselves(): void
    {
        $admin = User::factory()->withRole(Role::ADMIN)->create();

        $this->actingAs($admin, 'web')
            ->putJson("/api/admin/users/{$admin->id}", $this->payloadFor($admin, [
                'status' => User::STATUS_INACTIVE,
            ]))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['status']]]);

        $this->assertTrue($admin->fresh()->isActive());
    }

    public function test_an_administrator_may_still_edit_their_own_profile(): void
    {
        // The guards must not make self-service impossible.
        $admin = User::factory()->withRole(Role::ADMIN)->create();

        $this->actingAs($admin, 'web')
            ->putJson("/api/admin/users/{$admin->id}", $this->payloadFor($admin, [
                'first_name' => 'बदला हुआ',
                'mobile' => '9111111111',
            ]))
            ->assertOk()
            ->assertJsonPath('data.first_name', 'बदला हुआ');
    }

    public function test_super_admin_permissions_cannot_be_restricted(): void
    {
        $superRole = Role::query()->where('slug', Role::SUPER_ADMIN)->firstOrFail();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/roles/{$superRole->id}/permissions", ['permissions' => []])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['permissions']]]);

        // Still holds the whole catalogue.
        $this->assertSame(Permission::all(), $superRole->fresh()->effectivePermissions());
        $this->assertTrue($this->superAdmin->fresh()->hasPermission(Permission::USERS_MANAGE));
    }

    public function test_stripping_every_other_role_still_leaves_super_admin_working(): void
    {
        foreach ([Role::ADMIN, Role::TREASURER, Role::CONTENT_MANAGER, Role::VIEWER] as $slug) {
            $role = Role::query()->where('slug', $slug)->firstOrFail();
            $this->actingAs($this->superAdmin, 'web')
                ->putJson("/api/admin/roles/{$role->id}/permissions", ['permissions' => []])
                ->assertOk();
        }

        $this->actingAs($this->superAdmin->fresh(), 'web')
            ->getJson('/api/admin/users')
            ->assertOk();
    }
}

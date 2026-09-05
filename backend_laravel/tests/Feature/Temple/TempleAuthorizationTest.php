<?php

declare(strict_types=1);

namespace Tests\Feature\Temple;

use App\Models\CommitteeMember;
use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Server-side authorization for the Phase 3 endpoints.
 *
 * Every case calls the API directly with a role that should be refused. The
 * specification is explicit that hiding a Flutter control is never the access
 * control, so a passing widget test could not stand in for any of these.
 */
class TempleAuthorizationTest extends TestCase
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

    /** Roles the seeded matrix does not grant `temple.manage`. @return array<string, array{string}> */
    public static function rolesWithoutTempleManage(): array
    {
        return [
            'treasurer' => [Role::TREASURER],
            'viewer' => [Role::VIEWER],
        ];
    }

    public function test_the_public_endpoints_need_no_authentication(): void
    {
        $this->getJson('/api/public/temple-profile')->assertOk();
        $this->getJson('/api/public/committee')->assertOk();
    }

    public function test_a_guest_cannot_reach_the_admin_endpoints(): void
    {
        $this->getJson('/api/admin/temple-profile')->assertUnauthorized();
        $this->putJson('/api/admin/temple-profile', [])->assertUnauthorized();
        $this->getJson('/api/admin/committee-members')->assertUnauthorized();
        $this->postJson('/api/admin/committee-members', [])->assertUnauthorized();
    }

    #[DataProvider('rolesWithoutTempleManage')]
    public function test_a_role_without_temple_manage_cannot_edit_the_profile(string $slug): void
    {
        $this->actingAsRole($slug);

        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Somewhere'])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    #[DataProvider('rolesWithoutTempleManage')]
    public function test_a_role_without_temple_manage_cannot_create_a_member(string $slug): void
    {
        $this->actingAsRole($slug);

        $this->postJson('/api/admin/committee-members', [
            'name_hi' => 'घुसपैठिया',
            'designation_hi' => 'सदस्य',
        ])->assertForbidden();

        $this->assertSame(0, CommitteeMember::query()->count());
    }

    #[DataProvider('rolesWithoutTempleManage')]
    public function test_a_role_without_temple_manage_cannot_edit_or_delete_a_member(string $slug): void
    {
        $member = CommitteeMember::factory()->create();
        $this->actingAsRole($slug);

        $this->putJson("/api/admin/committee-members/{$member->id}", [
            'name_hi' => 'बदला',
            'designation_hi' => 'सदस्य',
        ])->assertForbidden();

        $this->deleteJson("/api/admin/committee-members/{$member->id}")->assertForbidden();

        $this->assertSame(1, CommitteeMember::query()->count());
    }

    public function test_a_content_manager_holds_temple_manage_by_default(): void
    {
        // The seeded matrix encodes the specification's role prose: the person
        // who runs the website's content also maintains the temple's profile.
        $this->actingAsRole(Role::CONTENT_MANAGER);

        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Amarpur Pankhoriya'])->assertOk();
        $this->postJson('/api/admin/committee-members', [
            'name_hi' => 'सदस्य',
            'designation_hi' => 'सदस्य',
        ])->assertStatus(201);
    }

    public function test_a_viewer_may_read_the_committee_but_not_change_it(): void
    {
        // Reading is gated on content.view, writing on temple.manage, so the
        // committee can be shown to someone who cannot edit it.
        CommitteeMember::factory()->create();
        $this->actingAsRole(Role::VIEWER);

        $this->getJson('/api/admin/committee-members')->assertOk();
        $this->getJson('/api/admin/temple-profile')->assertOk();
        $this->putJson('/api/admin/temple-profile', [])->assertForbidden();
    }

    public function test_granting_temple_manage_takes_effect_immediately(): void
    {
        $user = $this->actingAsRole(Role::VIEWER);

        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Nowhere'])->assertForbidden();

        $role = $user->role;
        $role->permissions = [...$role->effectivePermissions(), Permission::TEMPLE_MANAGE];
        $role->save();

        $this->actingAs($user->refresh(), 'web');
        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Amarpur Pankhoriya'])->assertOk();
    }

    public function test_a_deactivated_account_loses_access_even_with_the_permission(): void
    {
        $user = User::factory()->withRole(Role::CONTENT_MANAGER)->create();
        $this->actingAs($user, 'web');
        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Amarpur'])->assertOk();

        $user->forceFill(['status' => User::STATUS_INACTIVE])->save();

        $this->actingAs($user->refresh(), 'web');
        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Elsewhere'])
            ->assertStatus(403);
    }

    public function test_a_super_admin_passes_every_check(): void
    {
        $this->actingAsRole(Role::SUPER_ADMIN);

        $this->putJson('/api/admin/temple-profile', ['village_en' => 'Amarpur Pankhoriya'])->assertOk();
        $this->postJson('/api/admin/committee-members', [
            'name_hi' => 'सदस्य',
            'designation_hi' => 'अध्यक्ष',
        ])->assertStatus(201);
    }
}

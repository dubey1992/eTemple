<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Covers GET /api/auth/me and POST /api/auth/logout.
 */
class SessionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_me_returns_the_authenticated_user_with_its_role(): void
    {
        $user = User::factory()->withRole(Role::TREASURER)->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.full_name', $user->fullName())
            ->assertJsonPath('data.role.slug', Role::TREASURER)
            ->assertJsonMissingPath('data.password');
    }

    public function test_me_requires_authentication(): void
    {
        $this->getJson('/api/auth/me')
            ->assertUnauthorized()
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    public function test_a_user_deactivated_mid_session_loses_access_immediately(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'web')->getJson('/api/auth/me')->assertOk();

        $user->forceFill(['status' => User::STATUS_INACTIVE])->save();

        $this->actingAs($user->fresh(), 'web')
            ->getJson('/api/auth/me')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_INACTIVE');
    }

    public function test_a_user_blocked_mid_session_loses_access_immediately(): void
    {
        $user = User::factory()->blocked()->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/auth/me')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_BLOCKED');
    }

    public function test_a_signed_in_user_can_sign_out(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'web')
            ->postJson('/api/auth/logout')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.message', 'Signed out successfully.');

        $this->assertGuest();
    }

    public function test_logout_requires_authentication(): void
    {
        $this->postJson('/api/auth/logout')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }
}

<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The admin surface must be closed on the server. A Flutter route guard is a
 * convenience, never the control (spec Phase 2 rule, enforced from Phase 0).
 */
class AdminRouteProtectionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_a_guest_is_rejected(): void
    {
        $this->getJson('/api/admin/ping')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    public function test_a_blocked_user_is_rejected(): void
    {
        $user = User::factory()->withRole(Role::ADMIN)->blocked()->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/admin/ping')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_BLOCKED');
    }

    public function test_an_inactive_user_is_rejected(): void
    {
        $user = User::factory()->withRole(Role::ADMIN)->inactive()->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/admin/ping')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_INACTIVE');
    }

    /**
     * Phase 0 only proves the group is authenticated and active-checked; per-role
     * permissions arrive in Phase 2.
     *
     * One case per role rather than a loop: Sanctum's RequestGuard caches the
     * user it resolves for the lifetime of the PHP process, so several sign-ins
     * inside a single test would all be answered as the first one. A separate
     * test case gets a fresh application, which is what a real request gets too.
     */
    #[DataProvider('seededRoles')]
    public function test_an_active_user_of_a_seeded_role_reaches_the_admin_group(string $slug): void
    {
        $user = User::factory()->withRole($slug)->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/admin/ping')
            ->assertOk()
            ->assertJsonPath('data.status', 'ok')
            ->assertJsonPath('data.user.id', $user->id)
            ->assertJsonPath('data.user.role.slug', $slug);
    }

    /** @return array<string, array{string}> */
    public static function seededRoles(): array
    {
        return array_combine(
            Role::ALL,
            array_map(static fn (string $slug) => [$slug], Role::ALL),
        );
    }
}

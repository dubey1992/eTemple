<?php

declare(strict_types=1);

namespace Tests\Feature\Content;

use App\Models\Page;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Who may edit public content.
 *
 * Phase 2 replaces the `manage-content` gate with the permission matrix; until
 * then a Treasurer and a Viewer must not be able to rewrite the temple's public
 * pages, and the server is what enforces that.
 *
 * One test case per role rather than a loop: Sanctum's RequestGuard caches the
 * user it resolves for the life of the PHP process.
 */
class AdminContentAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    /** @return array<string, array{string}> */
    public static function allowedRoles(): array
    {
        return [
            'super admin' => [Role::SUPER_ADMIN],
            'admin' => [Role::ADMIN],
            'content manager' => [Role::CONTENT_MANAGER],
        ];
    }

    /** @return array<string, array{string}> */
    public static function deniedRoles(): array
    {
        return [
            'treasurer' => [Role::TREASURER],
            'viewer' => [Role::VIEWER],
        ];
    }

    private function payload(): array
    {
        return [
            'title_hi' => 'नया शीर्षक',
            'content_hi' => 'नई सामग्री',
            'status' => Page::STATUS_DRAFT,
        ];
    }

    #[DataProvider('allowedRoles')]
    public function test_a_content_role_may_list_and_edit_pages(string $slug): void
    {
        $user = User::factory()->withRole($slug)->create();
        $page = Page::factory()->create();

        $this->actingAs($user, 'web')->getJson('/api/admin/pages')->assertOk();

        $this->actingAs($user, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload())
            ->assertOk()
            ->assertJsonPath('data.title_hi', 'नया शीर्षक');
    }

    #[DataProvider('deniedRoles')]
    public function test_a_non_content_role_may_not_list_pages(string $slug): void
    {
        $user = User::factory()->withRole($slug)->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/admin/pages')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    #[DataProvider('deniedRoles')]
    public function test_a_non_content_role_may_not_edit_a_page(string $slug): void
    {
        $user = User::factory()->withRole($slug)->create();
        $page = Page::factory()->create(['title_hi' => 'मूल शीर्षक']);

        $this->actingAs($user, 'web')
            ->putJson("/api/admin/pages/{$page->id}", $this->payload())
            ->assertForbidden();

        $this->assertSame('मूल शीर्षक', $page->fresh()->title_hi);
    }

    #[DataProvider('deniedRoles')]
    public function test_a_non_content_role_may_not_change_site_settings(string $slug): void
    {
        $user = User::factory()->withRole($slug)->create();

        $this->actingAs($user, 'web')
            ->putJson('/api/admin/site-settings', ['tagline_hi' => 'बदलाव'])
            ->assertForbidden();
    }

    public function test_a_guest_may_not_reach_the_admin_content_endpoints(): void
    {
        $page = Page::factory()->create();

        $this->getJson('/api/admin/pages')->assertUnauthorized();
        $this->putJson("/api/admin/pages/{$page->id}", $this->payload())->assertUnauthorized();
        $this->getJson('/api/admin/site-settings')->assertUnauthorized();
        $this->putJson('/api/admin/site-settings', [])->assertUnauthorized();
    }

    public function test_a_blocked_content_manager_is_refused_before_the_gate(): void
    {
        $user = User::factory()->withRole(Role::CONTENT_MANAGER)->blocked()->create();

        $this->actingAs($user, 'web')
            ->getJson('/api/admin/pages')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_BLOCKED');
    }
}

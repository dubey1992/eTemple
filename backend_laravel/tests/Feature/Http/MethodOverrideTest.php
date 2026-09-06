<?php

declare(strict_types=1);

namespace Tests\Feature\Http;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * POST + `X-HTTP-Method-Override` must reach the PUT and DELETE routes.
 *
 * The production host answers PUT, PATCH and DELETE with a LiteSpeed 403 raised
 * before PHP is reached, so the Flutter client sends every one of them as a
 * POST carrying the intended verb in this header. That makes a framework
 * behaviour — `Request::capture()` calling `enableHttpMethodParameterOverride()`
 * — load-bearing for every edit and every delete the committee makes.
 *
 * If an upgrade or a change to `public/index.php` ever stops honouring it, the
 * console silently loses the ability to change anything, and the browser
 * reports it as a CORS error, because the host's 403 carries no CORS header.
 * These tests exist so that failure is caught on a laptop instead.
 */
class MethodOverrideTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->withHeader('Origin', 'http://localhost:5000');
    }

    private function actor(): User
    {
        return User::factory()->withRole(Role::SUPER_ADMIN)->create();
    }

    public function test_a_post_with_the_override_header_reaches_the_put_route(): void
    {
        $this->actingAs($this->actor(), 'web')
            ->withHeader('X-HTTP-Method-Override', 'PUT')
            ->postJson('/api/admin/temple-profile', ['name_hi' => 'राधा कृष्ण ठाकुरवाड़ी'])
            ->assertOk()
            ->assertJsonPath('data.name_hi', 'राधा कृष्ण ठाकुरवाड़ी');
    }

    public function test_the_same_post_without_the_header_is_refused_as_a_post(): void
    {
        // The control. Without the header this is a genuine POST to a route
        // that answers only GET and PUT, so the 405 here is what proves the
        // test above passed because of the override and not for another reason.
        $this->actingAs($this->actor(), 'web')
            ->postJson('/api/admin/temple-profile', ['name_hi' => 'राधा कृष्ण ठाकुरवाड़ी'])
            ->assertStatus(405);
    }

    public function test_the_override_does_not_bypass_authorization(): void
    {
        // The header chooses which route runs, and nothing else. A Viewer
        // tunnelling a PUT is still a Viewer.
        $this->actingAs(User::factory()->withRole(Role::VIEWER)->create(), 'web')
            ->withHeader('X-HTTP-Method-Override', 'PUT')
            ->postJson('/api/admin/temple-profile', ['name_hi' => 'कोशिश'])
            ->assertForbidden();
    }

    public function test_the_override_cannot_be_used_by_a_guest(): void
    {
        $this->withHeader('X-HTTP-Method-Override', 'PUT')
            ->postJson('/api/admin/temple-profile', ['name_hi' => 'कोशिश'])
            ->assertUnauthorized();
    }
}

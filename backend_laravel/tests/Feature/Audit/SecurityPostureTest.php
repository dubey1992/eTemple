<?php

declare(strict_types=1);

namespace Tests\Feature\Audit;

use App\Models\Donation;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

/**
 * The controls that are supposed to be on every response and every route.
 *
 * Habits do not survive a busy afternoon. These are the properties of the code
 * that turn "we always add the permission" into something that fails the build
 * when somebody does not.
 */
class SecurityPostureTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    /**
     * Every admin route carries an authorization middleware.
     *
     * A route-table sweep rather than a request-by-request audit: it proves a
     * control is attached, not that it is the right one — the per-module
     * authorization tests from Phases 2 to 10 prove that, and they stay
     * (PHASE_11_PLAN assumption S7).
     */
    public function test_every_admin_route_is_gated_by_a_permission(): void
    {
        /**
         * Routes under `api/admin` that legitimately carry no `can:`.
         *
         * Each one must be justified here, in the test, where somebody adding
         * to the list has to write down why.
         *
         * @var array<string, string>
         */
        $exempt = [
            // The dashboard's own landing data is gated inside the controller,
            // panel by panel: a permission on the route would be all-or-nothing
            // and would hide the whole page from an account that may see part
            // of it.
            'api/admin/overview' => 'gated per panel inside OverviewController',

            // The Phase 0 canary. It carries nothing but the caller's own
            // account — the same thing /api/auth/me returns — and it exists so
            // that AdminRouteProtectionTest can prove the group's
            // authentication and active-account checks are really attached. A
            // permission on it would test the permission instead.
            'api/admin/ping' => 'the canary that proves the group is protected',
        ];

        $ungated = [];

        foreach (Route::getRoutes() as $route) {
            $uri = $route->uri();

            if (! str_starts_with($uri, 'api/admin')) {
                continue;
            }

            $middleware = $route->gatherMiddleware();
            $hasGate = false;

            foreach ($middleware as $entry) {
                if (is_string($entry) && str_starts_with($entry, 'can:')) {
                    $hasGate = true;
                    break;
                }
            }

            if (! $hasGate && ! array_key_exists($uri, $exempt)) {
                $ungated[] = $route->methods()[0].' '.$uri;
            }
        }

        $this->assertSame(
            [],
            $ungated,
            "These admin routes carry no permission:\n  ".implode("\n  ", $ungated),
        );
    }

    /** And every admin route requires a signed-in, active account. */
    public function test_every_admin_route_requires_authentication(): void
    {
        $unprotected = [];

        foreach (Route::getRoutes() as $route) {
            if (! str_starts_with($route->uri(), 'api/admin')) {
                continue;
            }

            $middleware = $route->gatherMiddleware();

            if (! in_array('auth:sanctum', $middleware, true)
                || ! in_array('active', $middleware, true)) {
                $unprotected[] = $route->methods()[0].' '.$route->uri();
            }
        }

        $this->assertSame([], $unprotected);
    }

    // --- headers -------------------------------------------------------------

    public function test_the_security_headers_are_on_every_response(): void
    {
        $response = $this->getJson('/api/health')->assertOk();

        $response->assertHeader('X-Content-Type-Options', 'nosniff');
        $response->assertHeader('X-Frame-Options', 'DENY');
        $response->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
        $this->assertStringContainsString(
            "frame-ancestors 'none'",
            (string) $response->headers->get('Content-Security-Policy'),
        );
        $this->assertStringContainsString(
            'camera=()',
            (string) $response->headers->get('Permissions-Policy'),
        );
    }

    /**
     * HSTS only over HTTPS.
     *
     * Sending it from a development site teaches the browser to refuse plain
     * HTTP for that host for a year, and the only cure is clearing the
     * browser's internal state.
     */
    public function test_hsts_is_absent_over_plain_http_and_present_over_https(): void
    {
        $this->getJson('/api/health')->assertHeaderMissing('Strict-Transport-Security');

        $this->withServerVariables(['HTTPS' => 'on'])
            ->getJson('https://localhost/api/health')
            ->assertHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    }

    /**
     * The documents the server composes get a stricter policy.
     *
     * The receipt, the bill and the printable export are the only HTML this
     * API emits, and they are assembled from stored content.
     */
    public function test_a_server_rendered_document_forbids_scripts(): void
    {
        $donation = Donation::factory()->confirmed()->create();

        $response = $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web')
            ->get("/api/admin/donations/{$donation->id}/receipt")
            ->assertOk();

        $policy = (string) $response->headers->get('Content-Security-Policy');

        $this->assertStringContainsString("default-src 'none'", $policy);
        $this->assertStringNotContainsString('script-src', $policy);
    }

    // --- the session ---------------------------------------------------------

    /**
     * The session is a cookie the browser's JavaScript cannot read.
     *
     * This is what makes "no sensitive token in browser storage" true on the
     * server's side; the Flutter side is swept by its own test.
     */
    public function test_the_session_cookie_is_http_only(): void
    {
        $this->assertTrue((bool) config('session.http_only'));
        $this->assertSame('lax', config('session.same_site'));
    }
}

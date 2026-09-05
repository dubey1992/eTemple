<?php

declare(strict_types=1);

namespace Tests\Feature\Reports;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Who may run what.
 *
 * Every case calls the API directly with the role under test. Hiding a Flutter
 * control is never the access control.
 */
class ReportCatalogueTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_an_anonymous_visitor_cannot_open_the_catalogue(): void
    {
        $this->getJson('/api/admin/reports')
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    /**
     * A Content Manager holds neither `reports.view` nor any money key: the
     * specification says they never see sensitive financial detail, and a
     * reporting module is exactly where that would leak.
     */
    public function test_a_content_manager_is_refused_the_whole_module(): void
    {
        $this->actingAs(User::factory()->withRole(Role::CONTENT_MANAGER)->create(), 'web');

        foreach ([
            '/api/admin/reports',
            '/api/admin/reports/donations',
            '/api/admin/reports/ledger',
            '/api/admin/reports/donations/export?format=csv',
            '/api/admin/overview',
        ] as $path) {
            $this->getJson($path)
                ->assertStatus(403)
                ->assertJsonPath('error.code', 'FORBIDDEN');
        }
    }

    /**
     * A **browser navigation**, not an XHR — which is how an export is opened.
     *
     * Laravel's default is to redirect a guest to a route named `login`, which
     * this API does not have, so the caller got a RouteNotFoundException and a
     * 500 where a 401 belonged. It stayed hidden because every other test and
     * every live check sends `Accept: application/json` and takes a different
     * path.
     */
    public function test_an_unauthenticated_browser_navigation_is_a_clean_401(): void
    {
        $response = $this->get(
            '/api/admin/reports/donations/export?format=pdf',
            ['Accept' => 'text/html,application/xhtml+xml'],
        );

        $response->assertStatus(401);
        $this->assertStringNotContainsString('RouteNotFoundException', $response->getContent());
        $this->assertStringNotContainsString('Route [login] not defined', $response->getContent());
    }

    public function test_the_same_holds_for_every_admin_route(): void
    {
        foreach ([
            '/api/admin/reports',
            '/api/admin/overview',
            '/api/admin/donations/1/receipt',
            '/api/admin/transactions/1/attachment',
        ] as $path) {
            $this->get($path, ['Accept' => 'text/html'])
                ->assertStatus(401);
        }
    }

    public function test_a_treasurer_is_offered_the_money_reports(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $keys = array_column(
            $this->getJson('/api/admin/reports')->assertOk()->json('data.reports'),
            'key',
        );

        $this->assertContains('donations', $keys);
        $this->assertContains('donation-summary', $keys);
        $this->assertContains('income-expenditure', $keys);
        $this->assertContains('ledger', $keys);

        // A Treasurer holds no enquiries key, so the inbox report is not even
        // listed: the console is never offered a door that will not open.
        $this->assertNotContains('enquiries', $keys);
    }

    public function test_an_admin_is_offered_every_report(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $keys = array_column(
            $this->getJson('/api/admin/reports')->assertOk()->json('data.reports'),
            'key',
        );

        $this->assertCount(6, $keys);
        $this->assertContains('enquiries', $keys);
        $this->assertContains('events', $keys);
    }

    /**
     * A report that is not listed is also refused when asked for directly — a
     * 403, not a 404: pretending it is absent would be obscurity standing in
     * for a permission.
     */
    public function test_a_report_that_is_not_listed_is_refused_when_asked_for(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $this->getJson('/api/admin/reports/enquiries')
            ->assertStatus(403)
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_an_unknown_report_is_a_404(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $this->getJson('/api/admin/reports/nonsense')->assertStatus(404);
    }

    /**
     * Reading and downloading are separate permissions: a Viewer may read a
     * report on screen and not take a copy away.
     */
    public function test_a_viewer_may_read_a_report_but_not_download_it(): void
    {
        $this->actingAs(User::factory()->withRole(Role::VIEWER)->create(), 'web');

        $this->getJson('/api/admin/reports/donations')->assertOk();

        $this->getJson('/api/admin/reports/donations/export?format=csv')
            ->assertStatus(403)
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->getJson('/api/admin/reports')
            ->assertOk()
            ->assertJsonPath('data.may_export', false);
    }

    public function test_a_treasurer_may_download(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $this->getJson('/api/admin/reports')
            ->assertOk()
            ->assertJsonPath('data.may_export', true);

        $this->get('/api/admin/reports/donations/export?format=csv')->assertOk();
    }

    /** @return array<string, array{string}> */
    public static function everyReport(): array
    {
        return [
            'donation register' => ['donations'],
            'donation summary' => ['donation-summary'],
            'income and expenditure' => ['income-expenditure'],
            'ledger' => ['ledger'],
            'events' => ['events'],
            'enquiries' => ['enquiries'],
        ];
    }

    /**
     * Every report in the catalogue runs, and in both formats that are files.
     *
     * A report that appears in the list and then fails when opened is worse
     * than one that was never offered.
     */
    #[DataProvider('everyReport')]
    public function test_every_report_runs_and_exports(string $key): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $response = $this->getJson("/api/admin/reports/{$key}")->assertOk();

        $this->assertNotEmpty($response->json('data.columns'), "{$key} has no columns");
        $this->assertIsArray($response->json('data.rows'));
        $this->assertIsArray($response->json('data.summary'));

        foreach (['csv', 'xlsx', 'pdf'] as $format) {
            $this->get("/api/admin/reports/{$key}/export?format={$format}")
                ->assertOk();
        }
    }
}

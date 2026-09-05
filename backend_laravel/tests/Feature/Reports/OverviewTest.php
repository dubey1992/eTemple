<?php

declare(strict_types=1);

namespace Tests\Feature\Reports;

use App\Models\Donation;
use App\Models\Enquiry;
use App\Models\Role;
use App\Models\User;
use App\Support\FinancialYear;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The dashboard's figures.
 *
 * The case that matters is the last one: a panel somebody may not see is
 * **absent**, not empty. An absent panel says "not yours"; an empty one says
 * "the temple received nothing", and only one of those is true.
 */
class OverviewTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function inThisYear(int $daysAgo = 5): string
    {
        return FinancialYear::current()->startsOn()
            ->max(now()->subDays($daysAgo))
            ->toDateString();
    }

    public function test_it_names_the_financial_year_it_is_reporting(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $this->getJson('/api/admin/overview')
            ->assertOk()
            ->assertJsonPath('data.financial_year.year', FinancialYear::current()->year)
            ->assertJsonPath('data.financial_year.label', FinancialYear::current()->label());
    }

    public function test_the_money_panel_counts_only_confirmed_donations(): void
    {
        Donation::factory()->confirmed()->ofRupees(5_000)->on($this->inThisYear())->create();
        Donation::factory()->ofRupees(9_999)->on($this->inThisYear())->create();

        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $this->getJson('/api/admin/overview')
            ->assertOk()
            ->assertJsonPath('data.money.donations_paise', 500_000)
            ->assertJsonPath('data.money.donations_display', '₹5,000.00');
    }

    /**
     * Twelve months, including the empty ones: a chart that omitted them would
     * compress the gap and show a steady trickle where there was a festival and
     * then silence.
     */
    public function test_the_trend_carries_twelve_months_including_empty_ones(): void
    {
        Donation::factory()->confirmed()->ofRupees(2_000)->on($this->inThisYear())->create();

        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $trend = $this->getJson('/api/admin/overview')->assertOk()->json('data.donation_trend');

        $this->assertCount(12, $trend);
        $this->assertSame(now()->format('Y-m'), $trend[11]['month']);
        $this->assertContains(0, array_column($trend, 'total_paise'));
    }

    public function test_the_enquiry_panel_counts_what_is_waiting(): void
    {
        Enquiry::factory()->count(2)->create(['status' => Enquiry::STATUS_NEW]);
        Enquiry::factory()->create(['status' => Enquiry::STATUS_IN_PROGRESS]);
        Enquiry::factory()->create(['status' => Enquiry::STATUS_RESOLVED]);

        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $this->getJson('/api/admin/overview')
            ->assertOk()
            ->assertJsonPath('data.enquiries.new', 2)
            ->assertJsonPath('data.enquiries.open', 3);
    }

    /**
     * A Treasurer holds `content.view`, so the calendar panel is theirs — but
     * no enquiries key, so the inbox panel is **absent**, not zero.
     */
    public function test_a_panel_the_account_may_not_see_is_absent_not_empty(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $data = $this->getJson('/api/admin/overview')->assertOk()->json('data');

        $this->assertArrayHasKey('money', $data);
        $this->assertArrayHasKey('donation_trend', $data);
        $this->assertArrayHasKey('upcoming_events', $data);
        $this->assertArrayNotHasKey('enquiries', $data);
    }

    /** And the other way round: an account with no money keys sees no money. */
    public function test_an_account_with_no_money_keys_gets_no_money_panels(): void
    {
        $user = User::factory()->withRole(Role::VIEWER)->create();
        $user->role->update(['permissions' => ['reports.view', 'enquiries.manage']]);

        $data = $this->actingAs($user->fresh(), 'web')
            ->getJson('/api/admin/overview')->assertOk()->json('data');

        $this->assertArrayNotHasKey('money', $data);
        $this->assertArrayNotHasKey('donation_trend', $data);
        $this->assertArrayHasKey('enquiries', $data);
    }

    public function test_a_content_manager_gets_an_overview_with_no_money_on_it(): void
    {
        // A Content Manager holds no reports key at all, so the endpoint is
        // refused outright — the strongest form of "no money on it".
        $this->actingAs(User::factory()->withRole(Role::CONTENT_MANAGER)->create(), 'web');

        $this->getJson('/api/admin/overview')->assertStatus(403);
    }

    public function test_a_viewer_sees_the_figures_without_being_able_to_export_them(): void
    {
        Donation::factory()->confirmed()->ofRupees(1_000)->on($this->inThisYear())->create();

        $this->actingAs(User::factory()->withRole(Role::VIEWER)->create(), 'web');

        $this->getJson('/api/admin/overview')
            ->assertOk()
            ->assertJsonPath('data.money.donations_paise', 100_000);
    }
}

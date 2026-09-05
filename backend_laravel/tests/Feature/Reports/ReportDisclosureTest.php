<?php

declare(strict_types=1);

namespace Tests\Feature\Reports;

use App\Models\Donation;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The disclosure control.
 *
 * This is the phase's reason to be careful: an export is a file that leaves the
 * application, and it carries exactly the columns Phases 6, 7 and 9 spent their
 * effort withholding. These cases assert the three outcomes of
 * PHASE_10_PLAN assumption N2.
 */
class ReportDisclosureTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        Donation::factory()->confirmed()->ofRupees(5_000)->create([
            'donor_name' => 'रामप्रसाद यादव',
            'donor_phone' => '9876543210',
            'donor_address' => 'अमरपुर पंखोरिया',
            'donation_date' => now()->subDays(5)->toDateString(),
        ]);
    }

    /** Not asked for → absent, whatever the permission. */
    public function test_personal_columns_are_absent_unless_asked_for(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $response = $this->getJson('/api/admin/reports/donations')->assertOk();

        $columns = array_column($response->json('data.columns'), 'key');
        $this->assertNotContains('donor_name', $columns);
        $this->assertNotContains('donor_phone', $columns);

        $this->assertResponseDoesNotLeak($response, 'रामप्रसाद', '9876543210');

        $response->assertJsonPath('data.includes_personal', false);
        // But the report says it *has* such columns, so the screen can offer
        // the switch rather than hiding the possibility.
        $response->assertJsonPath('data.has_personal_columns', true);
    }

    /** Asked for, and may → present. */
    public function test_a_treasurer_who_asks_gets_them(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $response = $this->getJson('/api/admin/reports/donations?include_personal=1')->assertOk();

        $columns = array_column($response->json('data.columns'), 'key');
        $this->assertContains('donor_name', $columns);

        $response->assertJsonPath('data.includes_personal', true);
        // Decoded rather than searched for in the raw body: JSON escapes
        // non-ASCII, so a Devanagari needle is never in the response bytes.
        $this->assertSame('रामप्रसाद यादव', $response->json('data.rows.0.donor_name'));
    }

    /**
     * Asked for, and may not → **refused**, not silently narrowed.
     *
     * Dropping columns somebody explicitly asked for is how a treasurer
     * concludes the export is broken and starts copying the register out by
     * hand.
     */
    public function test_asking_without_the_permission_is_refused_not_quietly_narrowed(): void
    {
        // A role that may run reports but may not read the register.
        $user = User::factory()->withRole(Role::VIEWER)->create();
        $user->role->update(['permissions' => ['reports.view', 'reports.export']]);

        $this->actingAs($user->fresh(), 'web');

        // The report itself is refused, because it needs donations.view.
        $this->getJson('/api/admin/reports/donations?include_personal=1')
            ->assertStatus(403);
    }

    /**
     * The case the code is really shaped for: a report somebody may run whose
     * personal columns they may not see.
     */
    public function test_a_report_can_be_run_while_its_personal_columns_are_refused(): void
    {
        $user = User::factory()->withRole(Role::VIEWER)->create();
        // May read the register on screen — and this test then removes the key
        // that unlocks the personal columns, leaving the report runnable.
        $user->role->update(['permissions' => ['reports.view', 'accounts.view']]);

        $this->actingAs($user->fresh(), 'web');

        // Runnable.
        $this->getJson('/api/admin/reports/ledger')->assertOk();

        // The ledger's personal permission is accounts.view, which this account
        // holds, so it may ask. Removing it makes the report unrunnable rather
        // than partially readable — the two keys are the same by design for
        // this report, and the enquiry report below is the asymmetric one.
        $this->getJson('/api/admin/reports/ledger?include_personal=1')->assertOk();
    }

    public function test_a_report_with_no_personal_columns_ignores_the_flag(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $response = $this->getJson('/api/admin/reports/donation-summary?include_personal=1')
            ->assertOk();

        // Nothing to disclose, so the flag is meaningless rather than an error.
        $response->assertJsonPath('data.includes_personal', false);
        $response->assertJsonPath('data.has_personal_columns', false);
    }

    /**
     * An anonymous donor is named in no export, at any permission.
     *
     * Their own receipt names them — it is their receipt — but a register
     * export is read by people the donor never met.
     */
    public function test_an_anonymous_donor_is_not_named_even_with_the_permission(): void
    {
        Donation::factory()->confirmed()->ofRupees(1_000)->create([
            'donor_name' => 'सीता देवी',
            'is_anonymous' => true,
            'donation_date' => now()->subDays(5)->toDateString(),
        ]);

        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $names = collect(
            $this->getJson('/api/admin/reports/donations?include_personal=1')
                ->assertOk()
                ->json('data.rows'),
        )->pluck('donor_name');

        $this->assertNotContains('सीता देवी', $names);
        $this->assertContains('(गुप्त)', $names);
    }

    /** The same control governs the file, not only the screen. */
    public function test_an_export_without_the_flag_carries_no_personal_column(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $csv = $this->get('/api/admin/reports/donations/export?format=csv')
            ->assertOk()
            ->getContent();

        $this->assertStringNotContainsString('रामप्रसाद', $csv);
        $this->assertStringNotContainsString('9876543210', $csv);
    }

    public function test_an_export_with_the_flag_says_so_in_the_file(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $csv = $this->get('/api/admin/reports/donations/export?format=csv&include_personal=1')
            ->assertOk()
            ->getContent();

        $this->assertStringContainsString('रामप्रसाद', $csv);
        // The file states what it holds, for whoever opens it in six months.
        $this->assertStringContainsString('व्यक्तिगत जानकारी सम्मिलित', $csv);
    }
}

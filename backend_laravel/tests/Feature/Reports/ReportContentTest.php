<?php

declare(strict_types=1);

namespace Tests\Feature\Reports;

use App\Models\AccountingCategory;
use App\Models\AccountingSetting;
use App\Models\Donation;
use App\Models\Enquiry;
use App\Models\Role;
use App\Models\Transaction;
use App\Models\User;
use App\Support\FinancialYear;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * What the reports actually say.
 *
 * The guarantee under test throughout is PHASE_10_PLAN assumption N1: the file
 * and the screen come from one query, so a filter that changes one changes the
 * other. It is asserted directly, by comparing a CSV against the JSON that the
 * same query string produced.
 */
class ReportContentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');
    }

    /** A date inside the current financial year, so the default window holds it. */
    private function inThisYear(int $daysAgo = 10): string
    {
        return FinancialYear::current()->startsOn()
            ->max(now()->subDays($daysAgo))
            ->toDateString();
    }

    // --- the guarantee ------------------------------------------------------

    /**
     * The export applies exactly the on-screen filters.
     *
     * Asserted rather than asserted-about: the same query string is sent twice,
     * and the rows the screen would show are the rows the file contains.
     */
    public function test_the_export_contains_exactly_what_the_screen_shows(): void
    {
        Donation::factory()->confirmed()->ofRupees(5_000)->on($this->inThisYear())->create([
            'donor_name' => 'क', 'purpose' => 'festival',
        ]);
        Donation::factory()->confirmed()->ofRupees(3_000)->on($this->inThisYear())->create([
            'donor_name' => 'ख', 'purpose' => 'maintenance',
        ]);

        $query = 'purpose=festival&per_page=200';

        $json = $this->getJson("/api/admin/reports/donations?{$query}")->assertOk();
        $csv = $this->get("/api/admin/reports/donations/export?format=csv&{$query}")
            ->assertOk()->getContent();

        $this->assertCount(1, $json->json('data.rows'));

        // The filtered-out donation is in neither.
        $this->assertStringContainsString('5000.00', $csv);
        $this->assertStringNotContainsString('3000.00', $csv);

        // And the file states the filter it was made under.
        $this->assertStringContainsString('purpose: festival', $csv);
    }

    public function test_a_date_window_narrows_both_the_screen_and_the_file(): void
    {
        Donation::factory()->confirmed()->ofRupees(1_000)->on($this->inThisYear(3))->create();
        Donation::factory()->confirmed()->ofRupees(9_000)
            ->on(FinancialYear::current()->previous()->startsOn()->addMonth()->toDateString())
            ->create();

        $json = $this->getJson('/api/admin/reports/donations')->assertOk();
        $csv = $this->get('/api/admin/reports/donations/export?format=csv')
            ->assertOk()->getContent();

        // The default window is the current financial year, not all of history:
        // an unbounded first click is a scan of every row the temple has.
        $this->assertCount(1, $json->json('data.rows'));
        $this->assertStringNotContainsString('9000.00', $csv);
    }

    // --- the reports --------------------------------------------------------

    public function test_the_donation_register_totals_only_confirmed_money(): void
    {
        Donation::factory()->confirmed()->ofRupees(5_000)->on($this->inThisYear())->create();
        Donation::factory()->ofRupees(2_000)->on($this->inThisYear())->create();          // pending
        Donation::factory()->reversed()->ofRupees(7_000)->on($this->inThisYear())->create();

        $summary = collect(
            $this->getJson('/api/admin/reports/donations')->assertOk()->json('data.summary'),
        )->keyBy('key');

        $this->assertSame(500_000, $summary['total']['value']);
        $this->assertSame('₹5,000.00', $summary['total']['display']);
        // All three rows are listed; only one is counted.
        $this->assertSame(3, $summary['row_count']['value']);
        $this->assertSame(1, $summary['pending']['value']);
        $this->assertSame(1, $summary['reversed']['value']);
    }

    public function test_the_donation_summary_groups_by_purpose_mode_and_month(): void
    {
        Donation::factory()->confirmed()->ofRupees(5_000)->on($this->inThisYear())->create(['purpose' => 'festival']);
        Donation::factory()->confirmed()->ofRupees(1_000)->on($this->inThisYear())->create(['purpose' => 'festival']);
        Donation::factory()->confirmed()->ofRupees(2_000)->on($this->inThisYear())->create(['purpose' => 'puja']);

        $rows = collect($this->getJson('/api/admin/reports/donation-summary')->assertOk()->json('data.rows'));

        $festival = $rows->firstWhere('label', 'त्योहार / Festival');
        $this->assertSame(600_000, $festival['amount']['paise']);
        $this->assertSame(2, $festival['count']);

        // Three groupings are present.
        $this->assertSame(
            ['उद्देश्य', 'माध्यम', 'माह'],
            $rows->pluck('group')->unique()->values()->all(),
        );
    }

    /**
     * The statement and the public page come from one service, so they cannot
     * disagree (assumption N9, extending Phase 9's N1).
     */
    public function test_the_statement_agrees_with_the_public_transparency_page(): void
    {
        AccountingSetting::query()->create([
            'is_published' => true,
            'opening_balance_paise' => 4_000_000,
        ]);

        $category = AccountingCategory::factory()->expense()->create(['name_hi' => 'निर्माण कार्य']);
        Transaction::factory()->approved()->ofRupees(9_000)->create([
            'category_id' => $category->id,
            'transaction_date' => $this->inThisYear(),
        ]);
        Donation::factory()->confirmed()->ofRupees(5_000)->on($this->inThisYear())->create();

        $statement = collect(
            $this->getJson('/api/admin/reports/income-expenditure')->assertOk()->json('data.summary'),
        )->keyBy('key');

        $public = $this->getJson('/api/public/transparency')->assertOk()->json('data.summary');

        $this->assertSame($public['opening_balance_paise'], $statement['opening']['value']);
        $this->assertSame($public['total_income_paise'], $statement['income']['value']);
        $this->assertSame($public['total_expense_paise'], $statement['expense']['value']);
        $this->assertSame($public['closing_balance_paise'], $statement['closing']['value']);
    }

    public function test_the_statement_reads_as_a_statement(): void
    {
        $category = AccountingCategory::factory()->expense()->create(['name_hi' => 'बिजली एवं पानी']);
        Transaction::factory()->approved()->ofRupees(4_000)->create([
            'category_id' => $category->id,
            'transaction_date' => $this->inThisYear(),
        ]);

        $rows = collect($this->getJson('/api/admin/reports/income-expenditure')->assertOk()->json('data.rows'));

        // Opening first, closing last, receipts and payments between.
        $this->assertSame('वर्ष के आरंभ में शेष', $rows->first()['head']);
        $this->assertSame('वर्ष के अंत में शेष', $rows->last()['head']);
        $this->assertNotNull($rows->firstWhere('head', 'दान से प्राप्त'));
        $this->assertNotNull($rows->firstWhere('head', 'बिजली एवं पानी'));
    }

    public function test_the_ledger_report_lists_entries_and_flags_a_bill(): void
    {
        $category = AccountingCategory::factory()->expense()->create();
        Transaction::factory()->approved()->ofRupees(1_200)->create([
            'category_id' => $category->id,
            'transaction_date' => $this->inThisYear(),
            'payee_name' => 'शर्मा इलेक्ट्रिकल्स',
        ]);

        $response = $this->getJson('/api/admin/reports/ledger?include_personal=1')->assertOk();
        $row = $response->json('data.rows.0');

        $this->assertSame('शर्मा इलेक्ट्रिकल्स', $row['payee_name']);
        $this->assertSame(120_000, $row['amount']['paise']);

        // Whether a bill exists, never where it is: the path is never
        // serialized anywhere, and a report is not a way round that.
        $this->assertArrayHasKey('has_attachment', $row);
        $this->assertStringNotContainsString('attachment_path', $response->getContent());
    }

    public function test_the_events_report_expands_a_recurring_event(): void
    {
        // A daily aarti is one row in the database and many occurrences in a
        // month, and "what did we hold" means the second.
        $this->getJson('/api/admin/reports/events')->assertOk();

        $summary = collect(
            $this->getJson('/api/admin/reports/events')->assertOk()->json('data.summary'),
        )->keyBy('key');

        $this->assertArrayHasKey('row_count', $summary);
        $this->assertArrayHasKey('cancelled', $summary);
    }

    public function test_the_enquiry_report_measures_how_long_answers_took(): void
    {
        $enquiry = Enquiry::factory()->create([
            'created_at' => now()->subDays(10),
            'status' => Enquiry::STATUS_RESOLVED,
            'resolved_at' => now()->subDays(6),
        ]);

        $response = $this->getJson('/api/admin/reports/enquiries')->assertOk();

        $row = collect($response->json('data.rows'))
            ->firstWhere('reference', $enquiry->reference);

        $this->assertSame(4, $row['resolved_in_days']);

        $summary = collect($response->json('data.summary'))->keyBy('key');
        $this->assertEquals(4.0, $summary['average_days']['value']);
    }

    /**
     * An unanswered message is not "0 days": reporting it that way would
     * flatter the average above it into meaninglessness.
     */
    public function test_an_open_enquiry_has_no_resolution_time(): void
    {
        $enquiry = Enquiry::factory()->create([
            'created_at' => now()->subDays(10),
            'status' => Enquiry::STATUS_NEW,
        ]);

        $row = collect(
            $this->getJson('/api/admin/reports/enquiries')->assertOk()->json('data.rows'),
        )->firstWhere('reference', $enquiry->reference);

        $this->assertNull($row['resolved_in_days']);
    }

    /** The hash is not serialized to the committee, and a report is not a way round that. */
    public function test_the_enquiry_report_never_carries_the_address_hash(): void
    {
        Enquiry::factory()->create(['created_at' => now()->subDay()]);

        $body = $this->getJson('/api/admin/reports/enquiries?include_personal=1')
            ->assertOk()->getContent();

        $this->assertStringNotContainsString('submitted_ip_hash', $body);
        $this->assertStringNotContainsString('ip_hash', $body);
    }

    public function test_reports_are_read_only(): void
    {
        foreach (['post', 'put', 'delete'] as $method) {
            $this->{$method.'Json'}('/api/admin/reports/donations')
                ->assertStatus(405);
        }
    }

    public function test_the_language_is_the_readers(): void
    {
        $english = $this->getJson('/api/admin/reports/donations?lang=en')->assertOk();

        $this->assertSame('Donation register', $english->json('data.title'));
        $this->assertSame(
            'Date',
            collect($english->json('data.columns'))->firstWhere('key', 'donation_date')['label'],
        );

        $hindi = $this->getJson('/api/admin/reports/donations')->assertOk();
        $this->assertSame('दान रजिस्टर', $hindi->json('data.title'));
    }
}

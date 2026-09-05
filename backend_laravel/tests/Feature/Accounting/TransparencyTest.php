<?php

declare(strict_types=1);

namespace Tests\Feature\Accounting;

use App\Models\AccountingCategory;
use App\Models\AccountingSetting;
use App\Models\Donation;
use App\Models\Transaction;
use App\Support\FinancialYear;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The figures the village reads.
 *
 * The arithmetic is the deliverable here. Every case below is a way the public
 * total could be wrong — unapproved money counted, a donation counted twice, a
 * reversal still counted, the wrong year, a balance that forgets what the
 * temple started with — and an assertion that it is not.
 */
class TransparencyTest extends TestCase
{
    use RefreshDatabase;

    private AccountingCategory $expense;

    private AccountingCategory $income;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        $this->expense = AccountingCategory::factory()->expense()->create([
            'name_hi' => 'निर्माण कार्य',
            'name_en' => 'Construction',
        ]);
        $this->income = AccountingCategory::factory()->income()->create([
            'name_hi' => 'हॉल किराया',
            'name_en' => 'Hall hire',
        ]);
    }

    private function publish(int $openingRupees = 0): void
    {
        AccountingSetting::query()->create([
            'is_published' => true,
            'opening_balance_paise' => $openingRupees * 100,
            'opening_balance_date' => '2026-04-01',
            'intro_hi' => 'मंदिर का आय-व्यय विवरण।',
        ]);
    }

    /** A date inside the current financial year, safe against the backdating limit. */
    private function insideThisYear(): string
    {
        return FinancialYear::current()->startsOn()->max(now()->subDays(30))->toDateString();
    }

    public function test_the_books_are_not_public_until_the_committee_says_so(): void
    {
        Transaction::factory()->approved()->ofRupees(5_000)->create([
            'category_id' => $this->expense->id,
            'transaction_date' => $this->insideThisYear(),
        ]);

        // No settings row at all: the default is not published.
        $response = $this->getJson('/api/public/transparency')->assertOk();

        $response->assertJsonPath('data.is_published', false);

        // And crucially: no figures, not even zeros. A page of zeros would read
        // as "the temple received nothing" (PHASE_9_PLAN assumption N7).
        $response->assertJsonMissingPath('data.summary');
        $this->assertStringNotContainsString('5,000', $response->getContent());
    }

    public function test_only_approved_money_reaches_the_public_totals(): void
    {
        $this->publish();
        $date = $this->insideThisYear();

        Transaction::factory()->approved()->ofRupees(3_000)->create([
            'category_id' => $this->expense->id, 'transaction_date' => $date,
        ]);
        Transaction::factory()->ofRupees(9_999)->create([              // pending
            'category_id' => $this->expense->id, 'transaction_date' => $date,
        ]);
        Transaction::factory()->reversed()->ofRupees(7_777)->create([  // reversed
            'category_id' => $this->expense->id, 'transaction_date' => $date,
        ]);

        $this->getJson('/api/public/transparency')
            ->assertOk()
            ->assertJsonPath('data.summary.total_expense_paise', 300_000);
    }

    public function test_donations_are_counted_from_their_own_register_and_reported_separately(): void
    {
        $this->publish();
        $date = $this->insideThisYear();

        Donation::factory()->confirmed()->ofRupees(5_000)->on($date)->create();
        Donation::factory()->confirmed()->ofRupees(2_500)->on($date)->create();
        Donation::factory()->ofRupees(1_000)->on($date)->create();          // pending
        Donation::factory()->reversed()->ofRupees(4_000)->on($date)->create();

        Transaction::factory()->approved()->income()->ofRupees(1_200)->create([
            'category_id' => $this->income->id, 'transaction_date' => $date,
        ]);

        $response = $this->getJson('/api/public/transparency')->assertOk();

        $response->assertJsonPath('data.summary.donations_paise', 750_000);
        $response->assertJsonPath('data.summary.other_income_paise', 120_000);
        $response->assertJsonPath('data.summary.total_income_paise', 870_000);

        // Two confirmed donations. A count, never a name.
        $response->assertJsonPath('data.summary.donation_count', 2);
    }

    public function test_the_balance_includes_the_opening_balance(): void
    {
        $this->publish(openingRupees: 40_000);
        $date = $this->insideThisYear();

        Donation::factory()->confirmed()->ofRupees(10_000)->on($date)->create();
        Transaction::factory()->approved()->ofRupees(6_000)->create([
            'category_id' => $this->expense->id, 'transaction_date' => $date,
        ]);

        $this->getJson('/api/public/transparency')
            ->assertOk()
            ->assertJsonPath('data.summary.opening_balance_paise', 4_000_000)
            ->assertJsonPath('data.summary.closing_balance_paise', 4_400_000);
    }

    /**
     * The opening balance of a year is computed from everything before it, so a
     * correction to an old entry cannot leave last year's closing and this
     * year's opening disagreeing (assumption N10).
     */
    public function test_a_years_opening_balance_carries_forward_from_the_year_before(): void
    {
        $this->publish(openingRupees: 1_000);

        $lastYear = FinancialYear::current()->previous();

        Donation::factory()
            ->confirmed()
            ->ofRupees(5_000)
            ->on($lastYear->startsOn()->addMonth()->toDateString())
            ->create();

        $response = $this->getJson('/api/public/transparency?year='.FinancialYear::current()->year)
            ->assertOk();

        // ₹1,000 stated + ₹5,000 received before this year began.
        $response->assertJsonPath('data.summary.opening_balance_paise', 600_000);

        // And last year reports the ₹5,000 as its own income, not as an opening
        // balance — the money is counted once, in the year it moved.
        $this->getJson('/api/public/transparency?year='.$lastYear->year)
            ->assertOk()
            ->assertJsonPath('data.summary.opening_balance_paise', 100_000)
            ->assertJsonPath('data.summary.donations_paise', 500_000);
    }

    public function test_the_breakdown_is_by_category_largest_first(): void
    {
        $this->publish();
        $date = $this->insideThisYear();

        $utilities = AccountingCategory::factory()->expense()->create([
            'name_hi' => 'बिजली एवं पानी', 'name_en' => 'Electricity and water',
        ]);

        Transaction::factory()->approved()->ofRupees(1_000)->create([
            'category_id' => $utilities->id, 'transaction_date' => $date,
        ]);
        Transaction::factory()->approved()->ofRupees(9_000)->create([
            'category_id' => $this->expense->id, 'transaction_date' => $date,
        ]);

        $response = $this->getJson('/api/public/transparency')->assertOk();

        $response->assertJsonPath('data.summary.expense_by_category.0.total_paise', 900_000);
        $response->assertJsonPath('data.summary.expense_by_category.0.name.value', 'निर्माण कार्य');
        $response->assertJsonPath('data.summary.expense_by_category.1.total_paise', 100_000);
    }

    public function test_a_category_with_nothing_in_it_is_omitted_rather_than_shown_at_zero(): void
    {
        $this->publish();
        AccountingCategory::factory()->expense()->create(['name_hi' => 'खाली श्रेणी']);

        Transaction::factory()->approved()->ofRupees(500)->create([
            'category_id' => $this->expense->id,
            'transaction_date' => $this->insideThisYear(),
        ]);

        $response = $this->getJson('/api/public/transparency')->assertOk();

        $this->assertCount(1, $response->json('data.summary.expense_by_category'));
    }

    public function test_the_category_name_falls_back_to_hindi_for_an_english_reader(): void
    {
        $this->publish();
        $hindiOnly = AccountingCategory::factory()->expense()->hindiOnly()->create([
            'name_hi' => 'भंडारा एवं प्रसाद',
        ]);

        Transaction::factory()->approved()->ofRupees(500)->create([
            'category_id' => $hindiOnly->id,
            'transaction_date' => $this->insideThisYear(),
        ]);

        $response = $this->getJson('/api/public/transparency?lang=en')->assertOk();

        $response->assertJsonPath('data.summary.expense_by_category.0.name.value', 'भंडारा एवं प्रसाद');
        $response->assertJsonPath('data.summary.expense_by_category.0.name.language', 'hi');
        $response->assertJsonPath('data.summary.expense_by_category.0.name.fallback_used', true);
    }

    public function test_the_english_name_is_served_when_it_exists(): void
    {
        $this->publish();
        Transaction::factory()->approved()->ofRupees(500)->create([
            'category_id' => $this->expense->id,
            'transaction_date' => $this->insideThisYear(),
        ]);

        $this->getJson('/api/public/transparency?lang=en')
            ->assertOk()
            ->assertJsonPath('data.summary.expense_by_category.0.name.value', 'Construction')
            ->assertJsonPath('data.summary.expense_by_category.0.name.fallback_used', false);
    }

    public function test_money_from_another_year_is_not_counted_in_this_one(): void
    {
        $this->publish();
        $lastYear = FinancialYear::current()->previous();

        Transaction::factory()->approved()->ofRupees(8_000)->create([
            'category_id' => $this->expense->id,
            'transaction_date' => $lastYear->startsOn()->addMonth()->toDateString(),
        ]);

        $this->getJson('/api/public/transparency?year='.FinancialYear::current()->year)
            ->assertOk()
            ->assertJsonPath('data.summary.total_expense_paise', 0);
    }

    /**
     * A stale bookmark to `?year=2019` should show the reader this year's
     * accounts, not a fault page.
     */
    public function test_an_unreasonable_year_falls_back_to_the_current_one_rather_than_erroring(): void
    {
        $this->publish();
        Transaction::factory()->approved()->ofRupees(500)->create([
            'category_id' => $this->expense->id,
            'transaction_date' => $this->insideThisYear(),
        ]);

        foreach (['1066', 'next tuesday', '9999', ''] as $year) {
            $this->getJson('/api/public/transparency?year='.urlencode($year))
                ->assertOk()
                ->assertJsonPath('data.is_published', true)
                ->assertJsonPath('data.summary.year', FinancialYear::current()->year);
        }
    }

    /**
     * The current year is offered even while empty, and is offered first: a
     * page that quietly showed last year because this one has no entries yet
     * would put one year's heading over another year's figures.
     */
    public function test_the_current_year_is_offered_first_even_when_it_is_empty(): void
    {
        $this->publish();

        Transaction::factory()->approved()->ofRupees(8_000)->create([
            'category_id' => $this->expense->id,
            'transaction_date' => FinancialYear::current()->previous()->startsOn()
                ->addMonth()->toDateString(),
        ]);

        $response = $this->getJson('/api/public/transparency')->assertOk();

        $response->assertJsonPath('data.available_years.0.year', FinancialYear::current()->year);
        $response->assertJsonPath('data.available_years.1.year', FinancialYear::current()->previous()->year);
        $response->assertJsonPath('data.summary.year', FinancialYear::current()->year);
        $response->assertJsonPath('data.summary.total_expense_paise', 0);
    }

    public function test_ten_ten_paise_entries_sum_to_exactly_one_rupee(): void
    {
        $this->publish();
        $date = $this->insideThisYear();

        for ($i = 0; $i < 10; $i++) {
            Transaction::factory()->approved()->create([
                'category_id' => $this->expense->id,
                'transaction_date' => $date,
                'amount_paise' => 10,
            ]);
        }

        $this->getJson('/api/public/transparency')
            ->assertOk()
            ->assertJsonPath('data.summary.total_expense_paise', 100);
    }
}

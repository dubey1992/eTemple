<?php

declare(strict_types=1);

namespace Tests\Feature\Donations;

use App\Models\Donation;
use App\Models\Role;
use App\Models\User;
use App\Services\Donations\DonationService;
use App\Services\Donations\ReceiptNumberGenerator;
use Database\Seeders\RoleSeeder;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/**
 * "Receipt number unique and immutable" — the specification's own words, and
 * the rule the rest of this phase leans on.
 */
class ReceiptNumberTest extends TestCase
{
    use RefreshDatabase;

    private ReceiptNumberGenerator $generator;

    private DonationService $donations;

    private User $treasurer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        $this->generator = app(ReceiptNumberGenerator::class);
        $this->donations = app(DonationService::class);
        $this->treasurer = User::factory()->withRole(Role::TREASURER)->create();
    }

    public function test_a_pending_donation_has_no_receipt_number(): void
    {
        // A number that exists corresponds to a receipt that was really given,
        // so the sequence has no gaps to explain (PHASE_6_PLAN assumption N2).
        $donation = Donation::factory()->create();

        $this->assertNull($donation->receipt_number);
        $this->assertFalse($donation->isLocked());
    }

    public function test_confirming_issues_the_first_number_of_the_year(): void
    {
        $donation = Donation::factory()->on('2026-06-15')->create();

        $confirmed = $this->donations->confirm($donation, $this->treasurer);

        $this->assertSame('RKT/2026-27/0001', $confirmed->receipt_number);
        $this->assertTrue($confirmed->isConfirmed());
        $this->assertNotNull($confirmed->confirmed_at);
        $this->assertSame($this->treasurer->id, $confirmed->confirmed_by);
    }

    public function test_numbers_run_in_sequence_within_a_financial_year(): void
    {
        $issued = [];
        foreach (['2026-04-02', '2026-09-09', '2027-03-31'] as $date) {
            $issued[] = $this->donations
                ->confirm(Donation::factory()->on($date)->create(), $this->treasurer)
                ->receipt_number;
        }

        $this->assertSame(
            ['RKT/2026-27/0001', 'RKT/2026-27/0002', 'RKT/2026-27/0003'],
            $issued,
        );
    }

    public function test_the_financial_year_turns_over_in_april(): void
    {
        // 31 March and 1 April are in different books, which is what a temple's
        // accounts in India are kept by.
        $march = $this->donations->confirm(
            Donation::factory()->on('2027-03-31')->create(),
            $this->treasurer,
        );
        $april = $this->donations->confirm(
            Donation::factory()->on('2027-04-01')->create(),
            $this->treasurer,
        );

        $this->assertSame('RKT/2026-27/0001', $march->receipt_number);
        $this->assertSame('RKT/2027-28/0001', $april->receipt_number);
    }

    public function test_the_year_comes_from_the_donation_not_from_today(): void
    {
        // Confirming a March donation in April must not move it into next
        // year's book: a donation and its receipt belong to the same year.
        Carbon::setTestNow('2027-04-20 10:00:00');

        $confirmed = $this->donations->confirm(
            Donation::factory()->on('2027-03-20')->create(),
            $this->treasurer,
        );

        $this->assertStringStartsWith('RKT/2026-27/', (string) $confirmed->receipt_number);

        Carbon::setTestNow();
    }

    public function test_a_number_is_never_reused_after_a_reversal(): void
    {
        $first = $this->donations->confirm(
            Donation::factory()->on('2026-06-01')->create(),
            $this->treasurer,
        );
        $this->donations->reverse($first, 'दोहरी प्रविष्टि', $this->treasurer);

        $second = $this->donations->confirm(
            Donation::factory()->on('2026-06-02')->create(),
            $this->treasurer,
        );

        // The reversed donation keeps 0001 — the receipt was really issued and
        // cancelling it must stay traceable.
        $this->assertSame('RKT/2026-27/0001', $first->fresh()?->receipt_number);
        $this->assertSame('RKT/2026-27/0002', $second->receipt_number);
    }

    public function test_the_sequence_survives_passing_ten(): void
    {
        // Zero padding means '0009' sorts before '0010' as a string, which a
        // naive max() would get wrong at exactly this point.
        for ($i = 0; $i < 11; $i++) {
            $last = $this->donations->confirm(
                Donation::factory()->on('2026-05-05')->create(),
                $this->treasurer,
            );
        }

        $this->assertSame('RKT/2026-27/0011', $last->receipt_number ?? null);
    }

    public function test_confirming_twice_is_refused_rather_than_issuing_a_second_number(): void
    {
        $donation = Donation::factory()->create();
        $confirmed = $this->donations->confirm($donation, $this->treasurer);

        $this->expectExceptionMessageMatches('/already been confirmed/');
        $this->donations->confirm($confirmed, $this->treasurer);
    }

    public function test_a_number_already_issued_is_returned_rather_than_replaced(): void
    {
        // The generator is idempotent per donation: whatever else happens, a
        // donation is numbered once.
        $donation = Donation::factory()->create();
        $first = $this->generator->assign($donation);
        $second = $this->generator->assign($donation->fresh());

        $this->assertSame($first, $second);
        $this->assertSame(1, Donation::query()->whereNotNull('receipt_number')->count());
    }

    public function test_the_database_refuses_a_duplicate_even_if_the_application_asks(): void
    {
        // The unique index is the guarantee, not the application's arithmetic:
        // two treasurers confirming at the same instant both read the same
        // highest sequence, and only the index can stop them.
        $this->donations->confirm(
            Donation::factory()->on('2026-06-01')->create(),
            $this->treasurer,
        );

        $this->expectException(QueryException::class);

        Donation::query()->create([
            'donor_name' => 'नकल',
            'amount_paise' => 100,
            'donation_date' => '2026-06-01',
            'payment_mode' => 'cash',
        ])->forceFill(['receipt_number' => 'RKT/2026-27/0001'])->save();
    }

    public function test_the_year_label_is_computed_from_the_start_month(): void
    {
        $this->assertSame('2026-27', $this->generator->financialYearLabel(Carbon::parse('2026-04-01')));
        $this->assertSame('2025-26', $this->generator->financialYearLabel(Carbon::parse('2026-03-31')));
        $this->assertSame('2099-00', $this->generator->financialYearLabel(Carbon::parse('2099-12-31')));
    }
}

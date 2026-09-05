<?php

declare(strict_types=1);

namespace Tests\Feature\Donations;

use App\Models\Donation;
use App\Models\Role;
use App\Models\User;
use App\Support\DonationPurpose;
use App\Support\PaymentMode;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The register as a treasurer uses it, and the four rules that keep it honest.
 */
class DonationManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');
    }

    /** @return array<string, mixed> */
    private function payload(array $overrides = []): array
    {
        return [
            'donor_name' => 'रामप्रसाद यादव',
            'amount' => '501',
            'donation_date' => now()->subDay()->toDateString(),
            'payment_mode' => PaymentMode::CASH,
            'purpose' => DonationPurpose::PUJA,
            ...$overrides,
        ];
    }

    // --- recording ----------------------------------------------------------

    public function test_a_donation_is_recorded_as_pending_with_no_receipt(): void
    {
        $response = $this->postJson('/api/admin/donations', $this->payload())
            ->assertStatus(201);

        $donation = Donation::query()->firstOrFail();

        $this->assertSame(Donation::STATUS_PENDING, $donation->status);
        $this->assertNull($donation->receipt_number);
        // 501 rupees is 50100 paise, exactly.
        $this->assertSame(50_100, $donation->amount_paise);
        $this->assertNotNull($donation->recorded_by);

        $response->assertJsonPath('data.amount_formatted', '₹501.00');
        $response->assertJsonPath('data.amount_paise', 50_100);
    }

    /** @return array<string, array{string, int}> */
    public static function amountsAsTyped(): array
    {
        return [
            'whole rupees' => ['501', 50_100],
            'with paise' => ['501.50', 50_150],
            'indian grouping' => ['1,25,500', 12_550_000],
            'with the symbol' => ['₹501', 50_100],
        ];
    }

    #[DataProvider('amountsAsTyped')]
    public function test_the_amount_is_stored_exactly_as_typed(string $typed, int $paise): void
    {
        $this->postJson('/api/admin/donations', $this->payload(['amount' => $typed]))
            ->assertStatus(201);

        $this->assertSame($paise, Donation::query()->firstOrFail()->amount_paise);
    }

    /** @return array<string, array{string}> */
    public static function refusedAmounts(): array
    {
        return [
            'zero' => ['0'],
            'negative' => ['-100'],
            'words' => ['five hundred'],
            'empty' => [''],
            'a slipped decimal beyond the limit' => ['99999999'],
        ];
    }

    #[DataProvider('refusedAmounts')]
    public function test_an_amount_that_is_not_a_positive_sum_is_refused(string $amount): void
    {
        $this->postJson('/api/admin/donations', $this->payload(['amount' => $amount]))
            ->assertStatus(422);

        $this->assertSame(0, Donation::query()->count());
    }

    public function test_a_non_cash_donation_must_carry_its_reference(): void
    {
        // Without it the entry cannot be matched against the bank statement,
        // which is the entire point of the pending → confirmed step.
        $this->postJson('/api/admin/donations', $this->payload([
            'payment_mode' => PaymentMode::UPI,
        ]))->assertStatus(422)->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->postJson('/api/admin/donations', $this->payload([
            'payment_mode' => PaymentMode::UPI,
            'reference_number' => 'UPI-2026-9931',
        ]))->assertStatus(201);
    }

    public function test_cash_needs_no_reference(): void
    {
        $this->postJson('/api/admin/donations', $this->payload())->assertStatus(201);
    }

    public function test_a_future_dated_donation_is_refused(): void
    {
        $this->postJson('/api/admin/donations', $this->payload([
            'donation_date' => now()->addDay()->toDateString(),
        ]))->assertStatus(422);
    }

    public function test_a_mistyped_year_is_refused_rather_than_stored_silently(): void
    {
        $this->postJson('/api/admin/donations', $this->payload([
            'donation_date' => now()->subYears(4)->toDateString(),
        ]))->assertStatus(422);
    }

    // --- the lifecycle ------------------------------------------------------

    public function test_confirming_issues_a_receipt_number(): void
    {
        $donation = Donation::factory()->on('2026-06-15')->create();

        $this->postJson("/api/admin/donations/{$donation->id}/confirm")
            ->assertOk()
            ->assertJsonPath('data.receipt_number', 'RKT/2026-27/0001')
            ->assertJsonPath('data.status', Donation::STATUS_CONFIRMED)
            ->assertJsonPath('data.is_locked', true);
    }

    public function test_a_pending_donation_can_still_be_corrected(): void
    {
        $donation = Donation::factory()->create();

        $this->putJson("/api/admin/donations/{$donation->id}", $this->payload([
            'donor_name' => 'सही नाम',
            'amount' => '1100',
        ]))->assertOk();

        $donation->refresh();
        $this->assertSame('सही नाम', $donation->donor_name);
        $this->assertSame(110_000, $donation->amount_paise);
    }

    public function test_a_receipted_donation_refuses_every_change_but_its_notes(): void
    {
        $donation = Donation::factory()->create();
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();

        // Changing the amount after a receipt is in somebody's hand would make
        // the paper and the database disagree.
        $this->putJson("/api/admin/donations/{$donation->id}", $this->payload([
            'donor_name' => $donation->donor_name,
            'amount' => '9999',
            'donation_date' => $donation->donation_date->toDateString(),
        ]))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'DONATION_LOCKED');

        $this->assertSame(50_100, $donation->fresh()?->amount_paise);
    }

    public function test_the_notes_on_a_receipted_donation_may_still_be_edited(): void
    {
        $donation = Donation::factory()->create();
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();
        $donation->refresh();

        $this->putJson("/api/admin/donations/{$donation->id}", [
            'donor_name' => $donation->donor_name,
            'amount' => '501',
            'donation_date' => $donation->donation_date->toDateString(),
            'payment_mode' => $donation->payment_mode,
            'notes' => 'बैंक विवरण से मिलान हो गया।',
        ])->assertOk();

        $this->assertSame('बैंक विवरण से मिलान हो गया।', $donation->fresh()?->notes);
    }

    // --- reversal, the only undo -------------------------------------------

    public function test_there_is_no_delete_endpoint_at_all(): void
    {
        // Its absence *is* the rule (PHASE_6_PLAN assumption N4).
        $donation = Donation::factory()->create();

        $this->deleteJson("/api/admin/donations/{$donation->id}")
            ->assertStatus(405);

        $this->assertSame(1, Donation::query()->count());
    }

    public function test_reversing_keeps_the_row_the_receipt_and_the_reason(): void
    {
        $donation = Donation::factory()->create();
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();

        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => 'चेक अनादरित हो गया',
        ])->assertOk()->assertJsonPath('data.status', Donation::STATUS_REVERSED);

        $donation->refresh();
        $this->assertNotNull($donation->receipt_number);
        $this->assertSame('चेक अनादरित हो गया', $donation->reversal_reason);
        $this->assertNotNull($donation->reversed_at);
        $this->assertNotNull($donation->reversed_by);
        $this->assertSame(1, Donation::query()->count());
    }

    public function test_a_reversal_without_a_reason_is_refused(): void
    {
        $donation = Donation::factory()->create();

        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => '',
        ])->assertStatus(422);

        $this->assertFalse($donation->fresh()?->isReversed());
    }

    public function test_a_pending_donation_can_be_reversed_too(): void
    {
        // The record of a mistake is itself worth keeping.
        $donation = Donation::factory()->create();

        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => 'गलती से दर्ज',
        ])->assertOk();

        $this->assertTrue($donation->fresh()?->isReversed());
        $this->assertNull($donation->fresh()?->receipt_number);
    }

    public function test_a_reversed_donation_cannot_be_confirmed_or_reversed_again(): void
    {
        $donation = Donation::factory()->create();
        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => 'गलती से दर्ज',
        ])->assertOk();

        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertStatus(409);
        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => 'फिर से',
        ])->assertStatus(409);
    }

    // --- the register and its totals ---------------------------------------

    public function test_totals_count_confirmed_donations_only(): void
    {
        Donation::factory()->confirmed()->ofRupees(1000)->create();
        Donation::factory()->confirmed()->ofRupees(500)->create();
        Donation::factory()->ofRupees(9999)->create();                 // pending
        Donation::factory()->confirmed()->reversed()->ofRupees(700)->create();

        $response = $this->getJson('/api/admin/donations')->assertOk();

        $response->assertJsonPath('meta.summary.total_paise', 150_000);
        $response->assertJsonPath('meta.summary.total_formatted', '₹1,500.00');
        $response->assertJsonPath('meta.summary.confirmed_count', 2);
        $response->assertJsonPath('meta.summary.pending_count', 1);
        $response->assertJsonPath('meta.summary.reversed_count', 1);
    }

    public function test_the_total_ignores_the_status_filter_it_is_shown_beside(): void
    {
        // Otherwise the register would report "received: ₹0.00" to anyone who
        // happened to be looking at the pending tab.
        Donation::factory()->confirmed()->ofRupees(1000)->create();
        Donation::factory()->ofRupees(250)->create();

        $this->getJson('/api/admin/donations?status=pending')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.summary.total_paise', 100_000);
    }

    public function test_the_total_is_of_everything_not_of_one_page(): void
    {
        Donation::factory()->confirmed()->ofRupees(100)->count(30)->create();

        $this->getJson('/api/admin/donations?per_page=5')
            ->assertOk()
            ->assertJsonCount(5, 'data')
            ->assertJsonPath('meta.total', 30)
            ->assertJsonPath('meta.summary.total_paise', 300_000);
    }

    public function test_the_register_can_be_searched_and_filtered(): void
    {
        Donation::factory()->confirmed()->create(['donor_name' => 'सीता देवी']);
        Donation::factory()->upi()->create(['donor_name' => 'मोहन लाल']);

        $this->getJson('/api/admin/donations?q=सीता')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/admin/donations?mode=upi')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/admin/donations?status=confirmed')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_the_date_range_filters_the_register(): void
    {
        Donation::factory()->on(now()->subDays(2)->toDateString())->create();
        Donation::factory()->on(now()->subDays(200)->toDateString())->create();

        $this->getJson('/api/admin/donations?from='.now()->subDays(30)->toDateString())
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    // --- the receipt --------------------------------------------------------

    public function test_the_receipt_is_a_printable_document(): void
    {
        $donation = Donation::factory()->ofRupees(501)->create([
            'donor_name' => 'श्री रामप्रसाद यादव',
        ]);
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();

        $response = $this->get("/api/admin/donations/{$donation->id}/receipt")->assertOk();

        $response->assertHeader('Content-Type', 'text/html; charset=UTF-8');
        // A receipt names a donor; it must not sit in a proxy or in the cache
        // of a shared computer.
        $this->assertStringContainsString('no-store', (string) $response->headers->get('Cache-Control'));

        $html = $response->getContent();
        $this->assertStringContainsString('RKT/2026-27/0001', (string) $html);
        $this->assertStringContainsString('श्री रामप्रसाद यादव', (string) $html);
        $this->assertStringContainsString('₹501.00', (string) $html);
        $this->assertStringContainsString('Rupees Five Hundred One Only', (string) $html);
    }

    public function test_the_receipt_reads_in_words_not_in_codes(): void
    {
        // A receipt that says "cash" and "festival" to a villager in Amarpur
        // Pankhoriya is not a receipt they can read. The Flutter client's
        // translations cannot help here — the server renders this document.
        $donation = Donation::factory()->create([
            'payment_mode' => PaymentMode::BANK_TRANSFER,
            'reference_number' => 'NEFT-2026-1',
            'purpose' => DonationPurpose::FESTIVAL,
        ]);
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();

        $html = (string) $this->get("/api/admin/donations/{$donation->id}/receipt")->getContent();

        $this->assertStringContainsString('त्योहार', $html);
        $this->assertStringContainsString('बैंक ट्रांसफर', $html);
        $this->assertStringNotContainsString('>bank_transfer<', $html);
    }

    public function test_a_reversed_receipt_says_cancelled(): void
    {
        // Handing somebody a receipt for money that is no longer in the books,
        // with nothing to say so, is the one genuinely dangerous thing the
        // renderer could do.
        $donation = Donation::factory()->create();
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();
        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => 'चेक अनादरित',
        ])->assertOk();

        $html = (string) $this->get("/api/admin/donations/{$donation->id}/receipt")->assertOk()->getContent();

        $this->assertStringContainsString('CANCELLED', $html);
        $this->assertStringContainsString('चेक अनादरित', $html);
    }

    public function test_a_donor_name_cannot_smuggle_markup_into_the_receipt(): void
    {
        $donation = Donation::factory()->create([
            'donor_name' => '<script>alert(1)</script>',
        ]);
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertOk();

        $html = (string) $this->get("/api/admin/donations/{$donation->id}/receipt")->getContent();

        $this->assertStringNotContainsString('<script>alert(1)</script>', $html);
        $this->assertStringContainsString('&lt;script&gt;', $html);
    }
}

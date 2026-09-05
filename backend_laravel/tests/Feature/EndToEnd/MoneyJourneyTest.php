<?php

declare(strict_types=1);

namespace Tests\Feature\EndToEnd;

use App\Models\AccountingCategory;
use App\Models\AccountingSetting;
use App\Models\AuditLog;
use App\Models\Role;
use App\Models\User;
use App\Support\AuditAction;
use App\Support\FinancialYear;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * One rupee, all the way through.
 *
 * Every module here has its own suite and every one of them passes. That is
 * exactly the problem this file exists for: **two modules can each be correct
 * and still disagree with each other**, and no per-module test can see it. The
 * Phase 9 defect was precisely that — the console's net excluded donations
 * while the public page included them, and both suites were green.
 *
 * So this walks the journey the temple actually performs, in order, and asserts
 * that the same money means the same thing at every stop: the register, the
 * receipt, the ledger, the figure the village reads, the report, the exported
 * file, and the audit trail.
 */
class MoneyJourneyTest extends TestCase
{
    use RefreshDatabase;

    private User $treasurer;

    private AccountingCategory $expense;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        $this->treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $this->expense = AccountingCategory::factory()->expense()->create([
            'code' => 'construction',
            'name_hi' => 'निर्माण कार्य',
            'name_en' => 'Construction',
        ]);
    }

    /** A date inside the current financial year and inside the backdating limit. */
    private function today(): string
    {
        return FinancialYear::current()->startsOn()->max(now()->subDays(10))->toDateString();
    }

    private function publishTheBooks(int $openingRupees = 0): void
    {
        AccountingSetting::query()->create([
            'is_published' => true,
            'opening_balance_paise' => $openingRupees * 100,
            'opening_balance_date' => FinancialYear::current()->startsOn()->toDateString(),
            'intro_hi' => 'मंदिर का आय-व्यय विवरण।',
        ]);
    }

    /**
     * ₹2,500 arrives in the donation box and ends up in six places at once.
     *
     * The assertion that matters is not any single figure — it is that they are
     * all the *same* figure, computed by different code paths for different
     * audiences.
     */
    public function test_a_donation_means_the_same_thing_in_every_place_it_appears(): void
    {
        $this->publishTheBooks(openingRupees: 10_000);
        $actor = $this->actingAs($this->treasurer, 'web');

        // 1. The treasurer records it. Pending: nothing is counted yet.
        $donation = $actor->postJson('/api/admin/donations', [
            'donor_name' => 'रामप्रसाद यादव',
            'amount' => '2500',
            'donation_date' => $this->today(),
            'purpose' => 'general',
            'payment_mode' => 'cash',
        ])->assertCreated()->json('data');

        $this->assertSame(250_000, $donation['amount_paise']);
        $this->assertNull($donation['receipt_number']);

        // Unconfirmed money is in nobody's total. A pending donation shown to
        // the village as income would be a promise, not a fact.
        $this->getJson('/api/public/transparency')
            ->assertJsonPath('data.summary.donations_paise', 0);

        // 2. It is verified, and only then does a receipt number exist.
        $confirmed = $actor->postJson("/api/admin/donations/{$donation['id']}/confirm")
            ->assertOk()->json('data');

        $this->assertNotNull($confirmed['receipt_number']);

        // 3. The receipt the donor is handed carries that number and that sum.
        $receipt = $actor->get("/api/admin/donations/{$donation['id']}/receipt")->assertOk();
        $receipt->assertSee($confirmed['receipt_number']);
        $receipt->assertSee('2,500', escape: false);

        // 4. The village reads the same rupees on the public page — computed by
        //    the transparency service, from the donation register, for an
        //    audience with no login.
        $this->getJson('/api/public/transparency')
            ->assertJsonPath('data.summary.donations_paise', 250_000)
            ->assertJsonPath('data.summary.donation_count', 1);

        // 5. The console agrees with the public page. This is the pairing the
        //    Phase 9 defect broke: the dashboard and the village must be shown
        //    the same rupees by the same service.
        $actor->getJson('/api/admin/overview')
            ->assertOk()
            ->assertJsonPath('data.money.donations_paise', 250_000);

        // 6. The report agrees with both.
        $register = $actor->getJson('/api/admin/reports/donations')->assertOk();
        $this->assertSame(1, $register->json('meta.total'));

        // 7. And the trail knows who did it, at both steps.
        $this->assertDatabaseHas('audit_logs', ['action' => AuditAction::DONATION_RECORDED]);
        $confirmedEntry = AuditLog::query()
            ->where('action', AuditAction::DONATION_CONFIRMED)->sole();
        $this->assertSame($this->treasurer->fullName(), $confirmedEntry->actor_name);
    }

    /**
     * The other half of the same promise: money that was taken back stops
     * counting everywhere, and stops counting at the same instant.
     */
    public function test_a_reversal_is_removed_from_every_total_at_once(): void
    {
        $this->publishTheBooks();
        $actor = $this->actingAs($this->treasurer, 'web');

        $donation = $actor->postJson('/api/admin/donations', [
            'donor_name' => 'सुमित्रा देवी',
            'amount' => '5000',
            'donation_date' => $this->today(),
            'purpose' => 'general',
            'payment_mode' => 'upi',
            'reference_number' => 'UPI/2026/0091',
        ])->assertCreated()->json('data');

        $actor->postJson("/api/admin/donations/{$donation['id']}/confirm")->assertOk();

        $this->getJson('/api/public/transparency')
            ->assertJsonPath('data.summary.donations_paise', 500_000);

        $actor->postJson("/api/admin/donations/{$donation['id']}/reverse", [
            'reversal_reason' => 'चेक वापस हो गया',
        ])->assertOk();

        // Gone from the totals — but not gone. The row, its receipt number and
        // the stated reason all survive, which is the whole point of a reversal
        // rather than a delete.
        $this->getJson('/api/public/transparency')
            ->assertJsonPath('data.summary.donations_paise', 0)
            ->assertJsonPath('data.summary.donation_count', 0);

        $actor->getJson('/api/admin/overview')
            ->assertJsonPath('data.money.donations_paise', 0);

        $reversed = $actor->getJson("/api/admin/donations/{$donation['id']}")->assertOk();
        $this->assertSame('reversed', $reversed->json('data.status'));
        $this->assertNotNull($reversed->json('data.receipt_number'));
    }

    /**
     * An expense, from writing it down to the village reading it — and the
     * refusals that sit in the middle.
     */
    public function test_an_expense_is_only_public_once_it_has_been_approved(): void
    {
        $this->publishTheBooks(openingRupees: 20_000);
        $actor = $this->actingAs($this->treasurer, 'web');

        $entry = $actor->postJson('/api/admin/transactions', [
            'category_id' => $this->expense->id,
            'type' => 'expense',
            'amount' => '3200',
            'transaction_date' => $this->today(),
            'description' => 'सीमेंट और बालू',
            'payee_name' => 'शर्मा ट्रेडर्स',
            'payment_mode' => 'cash',
        ])->assertCreated()->json('data');

        // Recorded, not approved: the village sees nothing yet.
        $this->getJson('/api/public/transparency')
            ->assertJsonPath('data.summary.total_expense_paise', 0);

        $actor->postJson("/api/admin/transactions/{$entry['id']}/approve")->assertOk();

        $public = $this->getJson('/api/public/transparency')->assertOk();
        $public->assertJsonPath('data.summary.total_expense_paise', 320_000);

        // The heading is public; the trader is not. No name reaches this page.
        $this->assertResponseCarries($public, 'निर्माण कार्य');
        $this->assertResponseDoesNotLeak($public, 'शर्मा ट्रेडर्स', 'सीमेंट और बालू');

        // An approved figure is settled. The books do not rewrite themselves —
        // and the refusal is the lock, not a validation slip, so the payload is
        // a complete and otherwise valid one.
        $actor->putJson("/api/admin/transactions/{$entry['id']}", [
            'amount' => '9999',
            'transaction_date' => $this->today(),
            'category_id' => $this->expense->id,
            'payment_mode' => 'cash',
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'TRANSACTION_LOCKED');
    }

    /**
     * The exported file and the screen are the same report — asserted by
     * counting one against the other rather than by trusting that they share a
     * code path.
     */
    public function test_the_file_a_treasurer_downloads_matches_what_the_screen_showed(): void
    {
        $actor = $this->actingAs($this->treasurer, 'web');
        $date = $this->today();

        foreach (['रामप्रसाद यादव', 'सुमित्रा देवी', 'गीता कुमारी'] as $index => $name) {
            $donation = $actor->postJson('/api/admin/donations', [
                'donor_name' => $name,
                'amount' => (string) (1000 * ($index + 1)),
                'donation_date' => $date,
                'purpose' => 'general',
                'payment_mode' => 'cash',
            ])->assertCreated()->json('data');

            $actor->postJson("/api/admin/donations/{$donation['id']}/confirm")->assertOk();
        }

        $onScreen = $actor->getJson('/api/admin/reports/donations?status=confirmed')->assertOk();
        $this->assertSame(3, $onScreen->json('meta.total'));

        $csv = $actor->get('/api/admin/reports/donations/export?format=csv&status=confirmed')
            ->assertOk();

        $body = $csv->getContent();
        // Data rows, ignoring the header block the file carries about itself.
        $rows = array_filter(
            explode("\r\n", $body),
            static fn (string $line): bool => str_contains($line, 'RKT') || str_contains($line, 'यादव')
                || str_contains($line, 'देवी') || str_contains($line, 'कुमारी'),
        );
        $this->assertCount(3, $rows);

        // And taking the copy is itself an event: Phase 10 could not answer
        // "who took the donor register", and this is the row that does.
        $exported = AuditLog::query()->where('action', AuditAction::REPORT_EXPORTED)->sole();
        $this->assertSame($this->treasurer->fullName(), $exported->actor_name);
    }
}

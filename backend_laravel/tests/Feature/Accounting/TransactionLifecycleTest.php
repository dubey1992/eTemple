<?php

declare(strict_types=1);

namespace Tests\Feature\Accounting;

use App\Models\AccountingCategory;
use App\Models\Role;
use App\Models\Transaction;
use App\Models\User;
use App\Support\PaymentMode;
use App\Support\TransactionType;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * pending → approved → reversed, and the refusals along the way.
 *
 * The rules under test are the ones that make the ledger defensible: an
 * approved figure cannot be quietly edited, nothing is ever deleted, and a
 * donation cannot be entered here at all.
 */
class TransactionLifecycleTest extends TestCase
{
    use RefreshDatabase;

    private User $treasurer;

    private AccountingCategory $expenseCategory;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        $this->treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $this->expenseCategory = AccountingCategory::factory()->expense()->create();
    }

    public function test_a_recorded_entry_starts_pending_and_counts_in_nothing(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $response = $this->postJson('/api/admin/transactions', [
            'amount' => '1200.50',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => PaymentMode::CASH,
            'payee_name' => 'शर्मा इलेक्ट्रिकल्स',
        ])->assertCreated();

        $response->assertJsonPath('data.status', Transaction::STATUS_PENDING);
        $response->assertJsonPath('data.is_locked', false);

        // Exact paise, from a string the treasurer typed. Never a float.
        $response->assertJsonPath('data.amount_paise', 120_050);
        $response->assertJsonPath('data.amount_formatted', '₹1,200.50');

        // Pending money is in no total.
        $this->getJson('/api/admin/transactions/summary')
            ->assertJsonPath('data.expense_paise', 0)
            ->assertJsonPath('data.pending_expense_paise', 120_050);
    }

    public function test_approving_counts_the_money_and_locks_the_row(): void
    {
        $transaction = Transaction::factory()->ofRupees(2_000)->create([
            'category_id' => $this->expenseCategory->id,
        ]);

        $this->actingAs($this->treasurer, 'web');

        $this->postJson("/api/admin/transactions/{$transaction->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', Transaction::STATUS_APPROVED)
            ->assertJsonPath('data.is_locked', true);

        $this->getJson('/api/admin/transactions/summary')
            ->assertJsonPath('data.expense_paise', 200_000);
    }

    public function test_an_approved_entry_refuses_every_edit_but_its_description(): void
    {
        $transaction = Transaction::factory()->approved()->ofRupees(2_000)->create([
            'category_id' => $this->expenseCategory->id,
        ]);

        $this->actingAs($this->treasurer, 'web');

        $this->putJson("/api/admin/transactions/{$transaction->id}", [
            'amount' => '3000',
            'transaction_date' => $transaction->transaction_date->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => $transaction->payment_mode,
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'TRANSACTION_LOCKED');

        // Unmoved. The figure has been counted in a published total.
        $this->assertSame(200_000, $transaction->fresh()->amount_paise);
    }

    public function test_the_description_may_still_be_corrected_after_approval(): void
    {
        $transaction = Transaction::factory()->approved()->ofRupees(2_000)->create([
            'category_id' => $this->expenseCategory->id,
        ]);

        $this->actingAs($this->treasurer, 'web');

        $this->putJson("/api/admin/transactions/{$transaction->id}", [
            'amount' => '2000',
            'transaction_date' => $transaction->transaction_date->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => $transaction->payment_mode,
            'description' => 'बिल संख्या 4471',
        ])->assertOk();

        $this->assertSame('बिल संख्या 4471', $transaction->fresh()->description);
    }

    public function test_reversal_keeps_the_row_and_needs_a_reason(): void
    {
        $transaction = Transaction::factory()->approved()->ofRupees(2_000)->create([
            'category_id' => $this->expenseCategory->id,
        ]);

        $this->actingAs($this->treasurer, 'web');

        // No reason: refused before anything changes.
        $this->postJson("/api/admin/transactions/{$transaction->id}/reverse", [])
            ->assertStatus(422);

        $this->assertTrue($transaction->fresh()->isApproved());

        $this->postJson("/api/admin/transactions/{$transaction->id}/reverse", [
            'reversal_reason' => 'दो बार दर्ज हो गया था',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', Transaction::STATUS_REVERSED)
            ->assertJsonPath('data.reversal_reason', 'दो बार दर्ज हो गया था');

        // The row stays; the money leaves every total.
        $this->assertDatabaseHas('transactions', ['id' => $transaction->id]);
        $this->getJson('/api/admin/transactions/summary')
            ->assertJsonPath('data.expense_paise', 0)
            ->assertJsonPath('data.reversed_count', 1);
    }

    public function test_a_reversed_entry_cannot_be_approved_or_reversed_again(): void
    {
        $transaction = Transaction::factory()->reversed()->create([
            'category_id' => $this->expenseCategory->id,
        ]);

        $this->actingAs($this->treasurer, 'web');

        $this->postJson("/api/admin/transactions/{$transaction->id}/approve")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'TRANSACTION_LOCKED');

        $this->postJson("/api/admin/transactions/{$transaction->id}/reverse", [
            'reversal_reason' => 'फिर से',
        ])->assertStatus(409);
    }

    public function test_approving_twice_is_refused(): void
    {
        $transaction = Transaction::factory()->approved()->create([
            'category_id' => $this->expenseCategory->id,
        ]);

        $this->actingAs($this->treasurer, 'web');

        $this->postJson("/api/admin/transactions/{$transaction->id}/approve")
            ->assertStatus(409);
    }

    public function test_there_is_no_way_to_delete_a_transaction(): void
    {
        $transaction = Transaction::factory()->create(['category_id' => $this->expenseCategory->id]);

        $this->actingAs($this->treasurer, 'web');

        $this->deleteJson("/api/admin/transactions/{$transaction->id}")
            ->assertStatus(405);

        $this->assertDatabaseHas('transactions', ['id' => $transaction->id]);
    }

    public function test_a_payload_cannot_set_its_own_status_or_approval(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => PaymentMode::CASH,
            // All ignored: approval is an endpoint, not a field.
            'status' => Transaction::STATUS_APPROVED,
            'approved_at' => now()->toIso8601String(),
            'approved_by' => $this->treasurer->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.status', Transaction::STATUS_PENDING);

        $this->assertDatabaseMissing('transactions', ['status' => Transaction::STATUS_APPROVED]);
    }

    public function test_a_non_cash_entry_needs_a_reference(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => PaymentMode::BANK_TRANSFER,
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure(['error' => ['details' => ['reference_number']]]);
    }

    public function test_an_amount_must_be_positive_and_readable(): void
    {
        $this->actingAs($this->treasurer, 'web');

        foreach (['0', '-500', 'पाँच सौ', '12.345'] as $amount) {
            $this->postJson('/api/admin/transactions', [
                'amount' => $amount,
                'transaction_date' => now()->subDay()->toDateString(),
                'category_id' => $this->expenseCategory->id,
                'payment_mode' => PaymentMode::CASH,
            ])->assertStatus(422);
        }

        $this->assertSame(0, Transaction::query()->count());
    }

    public function test_an_entry_cannot_be_dated_in_the_future(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->addDay()->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => PaymentMode::CASH,
        ])->assertStatus(422);
    }

    /**
     * The double-counting guard (PHASE_9_PLAN assumption N1).
     *
     * A donation entered here as well as in the donation register would be
     * published at twice its value. The rule is structural rather than
     * advisory, because a rule written only in a manual gets broken by the
     * third treasurer who never read it.
     */
    public function test_a_donation_cannot_be_entered_as_a_transaction(): void
    {
        $reserved = AccountingCategory::factory()->income()->code('donation')->create();

        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '5000',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $reserved->id,
            'payment_mode' => PaymentMode::CASH,
        ])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['category_id']]]);

        $this->assertSame(0, Transaction::query()->count());
    }

    public function test_an_entry_must_agree_with_its_category_side_of_the_books(): void
    {
        $income = AccountingCategory::factory()->income()->create();

        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $income->id,
            'type' => TransactionType::EXPENSE,
            'payment_mode' => PaymentMode::CASH,
        ])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['category_id']]]);
    }

    public function test_the_category_decides_the_type_when_none_is_sent(): void
    {
        $income = AccountingCategory::factory()->income()->create();

        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $income->id,
            'payment_mode' => PaymentMode::CASH,
        ])
            ->assertCreated()
            ->assertJsonPath('data.type', TransactionType::INCOME);
    }

    public function test_an_inactive_category_cannot_be_used_for_a_new_entry(): void
    {
        $retired = AccountingCategory::factory()->expense()->inactive()->create();

        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $retired->id,
            'payment_mode' => PaymentMode::CASH,
        ])->assertStatus(422);
    }

    /**
     * Separation of duties (assumption N3): off by default, so a one-treasurer
     * temple is not deadlocked on its first day.
     */
    public function test_by_default_the_recorder_may_approve_their_own_entry(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $id = $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => PaymentMode::CASH,
        ])->json('data.id');

        $this->postJson("/api/admin/transactions/{$id}/approve")->assertOk();
    }

    public function test_with_the_control_switched_on_somebody_else_must_approve(): void
    {
        config(['accounting.require_second_approver' => true]);

        $this->actingAs($this->treasurer, 'web');

        $id = $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->expenseCategory->id,
            'payment_mode' => PaymentMode::CASH,
        ])->json('data.id');

        $this->postJson("/api/admin/transactions/{$id}/approve")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'TRANSACTION_LOCKED');

        // Another member with the same permission may.
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');
        $this->postJson("/api/admin/transactions/{$id}/approve")->assertOk();
    }
}

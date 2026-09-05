<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\AccountingCategory;
use App\Models\Transaction;
use App\Support\PaymentMode;
use App\Support\TransactionType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Transaction>
 */
class TransactionFactory extends Factory
{
    protected $model = Transaction::class;

    /**
     * The safe default: a **pending** cash expense counted in no total.
     *
     * A test that wants a figure in the books has to approve it, the same way a
     * treasurer does — so no test can accidentally assert against money that
     * was never checked (mirrors {@see DonationFactory}).
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'type' => TransactionType::EXPENSE,
            'category_id' => AccountingCategory::factory()->expense(),
            'amount_paise' => 120_000,   // ₹1,200.00
            'transaction_date' => now()->subDays(3)->toDateString(),
            'payment_mode' => PaymentMode::CASH,
            'reference_number' => null,
            'description' => null,
            'payee_name' => null,
            'status' => Transaction::STATUS_PENDING,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (Transaction $transaction) {
            $transaction->forceFill([
                'created_by' => $transaction->created_by ?? null,
                'updated_by' => $transaction->updated_by ?? null,
                'approved_by' => $transaction->approved_by ?? null,
                'reversed_by' => $transaction->reversed_by ?? null,
            ]);
        });
    }

    public function income(): static
    {
        return $this->state(fn () => [
            'type' => TransactionType::INCOME,
            'category_id' => AccountingCategory::factory()->income(),
        ]);
    }

    /**
     * Approved, written directly.
     *
     * Only for tests that need a *starting* state; the approval rules
     * themselves are exercised through `TransactionService::approve()`.
     */
    public function approved(): static
    {
        return $this->state(fn () => [
            'status' => Transaction::STATUS_APPROVED,
            'approved_at' => now(),
        ]);
    }

    public function reversed(string $reason = 'दोबारा दर्ज किया गया'): static
    {
        return $this->state(fn () => [
            'status' => Transaction::STATUS_REVERSED,
            'reversal_reason' => $reason,
            'reversed_at' => now(),
        ]);
    }

    public function ofRupees(int $rupees): static
    {
        return $this->state(fn () => ['amount_paise' => $rupees * 100]);
    }

    public function on(string $date): static
    {
        return $this->state(fn () => ['transaction_date' => $date]);
    }

    public function inCategory(AccountingCategory $category): static
    {
        return $this->state(fn () => [
            'category_id' => $category->id,
            'type' => $category->type,
        ]);
    }
}

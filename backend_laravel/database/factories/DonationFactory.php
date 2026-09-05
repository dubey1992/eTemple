<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Donation;
use App\Support\DonationPurpose;
use App\Support\PaymentMode;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Donation>
 */
class DonationFactory extends Factory
{
    protected $model = Donation::class;

    /**
     * The safe default: a pending cash donation with **no receipt number**.
     *
     * A test that wants a receipt has to confirm the donation, the same way a
     * treasurer does — which means no test can accidentally assert against a
     * number that was never really issued.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'receipt_number' => null,
            'donor_name' => 'रामप्रसाद यादव',
            'donor_phone' => null,
            'donor_address' => null,
            'is_anonymous' => false,
            'amount_paise' => 50_100,   // ₹501.00
            'donation_date' => now()->subDays(3)->toDateString(),
            'payment_mode' => PaymentMode::CASH,
            'reference_number' => null,
            'purpose' => DonationPurpose::GENERAL,
            'notes' => null,
            'status' => Donation::STATUS_PENDING,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (Donation $donation) {
            $donation->forceFill([
                'recorded_by' => $donation->recorded_by ?? null,
                'updated_by' => $donation->updated_by ?? null,
                'confirmed_by' => $donation->confirmed_by ?? null,
                'reversed_by' => $donation->reversed_by ?? null,
            ]);
        });
    }

    /**
     * Confirmed, with a receipt number written directly.
     *
     * Only for tests that need a *starting* state; the generator's own
     * behaviour is exercised through `DonationService::confirm()`.
     */
    public function confirmed(?string $receiptNumber = null): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => Donation::STATUS_CONFIRMED,
            'receipt_number' => $receiptNumber ?? 'RKT/2026-27/'.str_pad(
                (string) $this->faker->unique()->numberBetween(1, 9999),
                4,
                '0',
                STR_PAD_LEFT,
            ),
            'confirmed_at' => now(),
        ]);
    }

    public function reversed(string $reason = 'दोबारा दर्ज किया गया'): static
    {
        return $this->state(fn () => [
            'status' => Donation::STATUS_REVERSED,
            'reversal_reason' => $reason,
            'reversed_at' => now(),
        ]);
    }

    public function upi(string $reference = 'UPI-2026-0001'): static
    {
        return $this->state(fn () => [
            'payment_mode' => PaymentMode::UPI,
            'reference_number' => $reference,
        ]);
    }

    public function ofRupees(int $rupees): static
    {
        return $this->state(fn () => ['amount_paise' => $rupees * 100]);
    }

    public function on(string $date): static
    {
        return $this->state(fn () => ['donation_date' => $date]);
    }
}

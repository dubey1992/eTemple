<?php

declare(strict_types=1);

namespace App\Http\Resources\Donations;

use App\Models\Donation;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One donation as the treasurer sees it.
 *
 * There is no public counterpart, and there is not going to be: donor detail
 * reaches no public endpoint at any status, in any aggregate
 * (PHASE_6_PLAN assumption N5). Every field below is behind `donations.view`.
 *
 * The amount is sent three ways on purpose: `amount_paise` is the authority,
 * `amount_formatted` is what a person reads, and `amount_decimal` is what an
 * export or a receipt prints. No client ever divides by a hundred.
 *
 * @mixin Donation
 */
class AdminDonationResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Donation $donation */
        $donation = $this->resource;

        return [
            'id' => $this->id,
            'receipt_number' => $this->receipt_number,

            'donor_name' => $this->donor_name,
            'donor_phone' => $this->donor_phone,
            'donor_address' => $this->donor_address,
            'is_anonymous' => $donation->is_anonymous,

            'amount_paise' => $donation->amount_paise,
            'amount_decimal' => Money::toDecimalString($donation->amount_paise),
            'amount_formatted' => $donation->formattedAmount(),

            'donation_date' => $donation->donation_date->toDateString(),
            'payment_mode' => $this->payment_mode,
            'reference_number' => $this->reference_number,
            'purpose' => $this->purpose,
            'notes' => $this->notes,

            'status' => $this->status,
            // What the client uses to decide which controls to offer. The
            // server refuses regardless; this only stops it offering a button
            // that would fail.
            'is_locked' => $donation->isLocked(),

            'recorded_by' => $this->whenLoaded('recordedBy', fn () => $donation->recordedBy?->fullName()),
            'confirmed_at' => $donation->confirmed_at?->toIso8601String(),
            'confirmed_by' => $this->whenLoaded('confirmedBy', fn () => $donation->confirmedBy?->fullName()),
            'reversed_at' => $donation->reversed_at?->toIso8601String(),
            'reversed_by' => $this->whenLoaded('reversedBy', fn () => $donation->reversedBy?->fullName()),
            'reversal_reason' => $this->reversal_reason,

            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}

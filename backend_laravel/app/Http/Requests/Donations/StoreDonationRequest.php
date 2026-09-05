<?php

declare(strict_types=1);

namespace App\Http\Requests\Donations;

use App\Support\DonationPurpose;
use App\Support\PaymentMode;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Recording or editing a donation.
 *
 * The shape only. Every rule that protects the books — the amount being
 * positive, the reference being present for anything but cash, the date being
 * neither future nor absurd, and a receipted donation being immutable — is
 * repeated in `DonationService`, so it holds however the record is reached.
 */
class StoreDonationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::DONATIONS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'donor_name' => ['required', 'string', 'max:200'],
            'donor_phone' => ['nullable', 'string', 'max:20'],
            'donor_address' => ['nullable', 'string', 'max:500'],
            'is_anonymous' => ['nullable', 'boolean'],

            // A string, not a number: "1,25,500" and "₹501.50" are what a
            // person types, and Money::parse understands them exactly or
            // refuses them. A float here would round before we ever saw it.
            'amount' => ['required', 'string', 'max:20'],

            'donation_date' => ['required', 'date'],
            'payment_mode' => ['required', Rule::in(PaymentMode::all())],
            'reference_number' => ['nullable', 'string', 'max:100'],
            'purpose' => ['nullable', Rule::in(DonationPurpose::all())],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /** Numbers sent as JSON numbers are accepted too, by making them strings. */
    protected function prepareForValidation(): void
    {
        $amount = $this->input('amount');

        if (is_int($amount) || is_float($amount)) {
            $this->merge(['amount' => (string) $amount]);
        }
    }
}

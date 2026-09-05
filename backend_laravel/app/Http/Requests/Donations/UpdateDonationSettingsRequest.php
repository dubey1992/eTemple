<?php

declare(strict_types=1);

namespace App\Http\Requests\Donations;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * The published bank/UPI block.
 *
 * Gated on `donations.manage`, not `content.manage`: changing the UPI id
 * devotees pay into is the single most valuable attack on this site, so it sits
 * behind the money permission and a compromised Content Manager account cannot
 * redirect the temple's donations (PHASE_6_PLAN assumption N6).
 */
class UpdateDonationSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::DONATIONS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'upi_id' => ['nullable', 'string', 'max:120'],
            'bank_name' => ['nullable', 'string', 'max:150'],
            'account_name' => ['nullable', 'string', 'max:150'],
            // Free text on purpose: whether to mask it, and how, is the
            // committee's decision and their bank's policy (assumption N7).
            'account_number' => ['nullable', 'string', 'max:60'],
            'ifsc' => ['nullable', 'string', 'max:20'],
            'qr_url' => ['nullable', 'url', 'max:500'],

            'intro_hi' => ['nullable', 'string', 'max:2000'],
            'intro_en' => ['nullable', 'string', 'max:2000'],
            'note_hi' => ['nullable', 'string', 'max:2000'],
            'note_en' => ['nullable', 'string', 'max:2000'],

            'is_published' => ['nullable', 'boolean'],
        ];
    }
}

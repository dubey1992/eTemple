<?php

declare(strict_types=1);

namespace App\Http\Requests\Donations;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Reversing a donation — the only undo there is.
 *
 * The reason is required here and again in the service. It is the sentence that
 * explains, months later, why an amount that is still in the books no longer
 * counts.
 */
class ReverseDonationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::DONATIONS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'reversal_reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }
}

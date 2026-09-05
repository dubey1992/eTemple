<?php

declare(strict_types=1);

namespace App\Http\Requests\Accounting;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * The two decisions nobody should make by accident: whether the temple's books
 * are public, and where they start.
 *
 * `is_published` is accepted here, unlike an announcement's status, because
 * publishing the accounts is not an irreversible act — switching it off takes
 * the page down again and loses nothing. What it must not be is a *default*,
 * which is why the column starts false (PHASE_9_PLAN assumption N7).
 */
class UpdateAccountingSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ACCOUNTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            // A string, and signed: a temple that begins in deficit should be
            // able to say so rather than rounding its own history up to zero.
            'opening_balance' => ['nullable', 'string', 'max:20'],
            'opening_balance_date' => ['nullable', 'date'],

            'intro_hi' => ['nullable', 'string', 'max:2000'],
            'intro_en' => ['nullable', 'string', 'max:2000'],
            'note_hi' => ['nullable', 'string', 'max:2000'],
            'note_en' => ['nullable', 'string', 'max:2000'],

            'is_published' => ['nullable', 'boolean'],
        ];
    }
}

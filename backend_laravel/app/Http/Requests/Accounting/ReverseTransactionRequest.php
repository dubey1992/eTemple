<?php

declare(strict_types=1);

namespace App\Http\Requests\Accounting;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Reversing a transaction.
 *
 * The reason is **required and has no default**. This is the only undo in the
 * phase, the row stays in the books afterwards, and the reason is the entire
 * explanation of why a figure that was once counted no longer is. A default
 * would put the same sentence on every reversal in the temple's history.
 */
class ReverseTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ACCOUNTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'reversal_reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Requests\Accounting;

use App\Support\PaymentMode;
use App\Support\Permission;
use App\Support\TransactionType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Recording or correcting one movement of the temple's money.
 *
 * The shape only. That the amount is positive, that the category exists and is
 * active and is on the right side of the books, that a non-cash entry carries a
 * reference, and that an approved entry is locked, are all checked again in
 * `TransactionService` so they hold however the record is reached.
 *
 * Note what is **not** here: `status`, `approved_at`, `approved_by`, and every
 * `attachment_*` column. Approving is a decision with its own endpoint, and the
 * stored file name is the server's, not the uploader's.
 */
class StoreTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ACCOUNTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            // A string, so "1,200.50" and "₹1200" both arrive intact and are
            // parsed once, by Money, into exact paise.
            'amount' => ['required', 'string', 'max:20'],

            'transaction_date' => ['required', 'date'],

            'category_id' => ['required', 'integer', 'min:1'],

            // Optional: the category decides the side of the books. Sending one
            // that disagrees with the category is refused rather than silently
            // corrected, because a disagreement means somebody chose wrongly.
            'type' => ['nullable', Rule::in(TransactionType::all())],

            'payment_mode' => ['required', Rule::in(PaymentMode::all())],
            'reference_number' => ['nullable', 'string', 'max:100'],

            'payee_name' => ['nullable', 'string', 'max:200'],
            'description' => ['nullable', 'string', 'max:2000'],

            // The bill. Validated properly by its bytes in AttachmentStore;
            // this only keeps an absurd upload from reaching PHP's memory.
            'attachment' => ['nullable', 'file', 'max:'.(int) config('accounting.attachments.max_upload_kb', 8192)],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['reference_number', 'payee_name', 'description'] as $key) {
            $value = $this->input($key);
            if (is_string($value) && trim($value) === '') {
                $this->merge([$key => null]);
            }
        }
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Resources\Accounting;

use App\Models\Transaction;
use App\Support\Money;
use App\Support\PaymentMode;
use App\Support\TransactionType;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One ledger entry, as the committee sees it.
 *
 * **`attachment_path` is never serialized** — not to a Viewer, not to a
 * Treasurer, not to the Super Admin. The bill is fetched from its own
 * authenticated endpoint by transaction id, so there is no path a client could
 * turn into a URL, and no URL to leak in a screenshot, a log or a browser's
 * history (PHASE_9_PLAN assumption N5).
 *
 * There is no public counterpart to this class and there is not going to be:
 * the public page publishes category totals, and this row carries who was paid.
 *
 * @mixin Transaction
 */
class AdminTransactionResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Transaction $transaction */
        $transaction = $this->resource;

        return [
            'id' => $this->id,

            'type' => $this->type,
            'type_label' => TransactionType::label($transaction->type),

            'category_id' => $this->category_id,
            'category' => $this->whenLoaded(
                'category',
                fn () => new AccountingCategoryResource($transaction->category),
            ),

            // The paise are the authority; the formatted string is what a
            // person reads. Nothing on the client ever divides by a hundred.
            'amount_paise' => $transaction->amount_paise,
            'amount_formatted' => Money::format($transaction->amount_paise),

            'transaction_date' => $transaction->transaction_date->toDateString(),

            'payment_mode' => $this->payment_mode,
            'payment_mode_label' => PaymentMode::label($transaction->payment_mode),
            'reference_number' => $this->reference_number,
            'requires_reference' => $transaction->requiresReference(),

            'payee_name' => $this->payee_name,
            'description' => $this->description,

            // What there is, never where it is.
            'has_attachment' => $transaction->hasAttachment(),
            'attachment_name' => $this->attachment_name,
            'attachment_size' => $this->attachment_size,
            'attachment_mime' => $this->attachment_mime,

            'status' => $this->status,
            'is_locked' => $transaction->isLocked(),

            'approved_at' => $transaction->approved_at?->toIso8601String(),
            'approved_by_name' => $this->whenLoaded(
                'approvedBy',
                fn () => $transaction->approvedBy?->fullName(),
            ),

            'reversed_at' => $transaction->reversed_at?->toIso8601String(),
            'reversed_by_name' => $this->whenLoaded(
                'reversedBy',
                fn () => $transaction->reversedBy?->fullName(),
            ),
            'reversal_reason' => $this->reversal_reason,

            'created_by_name' => $this->whenLoaded(
                'createdBy',
                fn () => $transaction->createdBy?->fullName(),
            ),
            'created_at' => $transaction->created_at?->toIso8601String(),
            'updated_at' => $transaction->updated_at?->toIso8601String(),
        ];
    }
}

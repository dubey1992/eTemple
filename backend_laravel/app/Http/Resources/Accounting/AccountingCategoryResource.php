<?php

declare(strict_types=1);

namespace App\Http\Resources\Accounting;

use App\Models\AccountingCategory;
use App\Support\TransactionType;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One heading the books are filed under, as the committee sees it.
 *
 * Both languages travel raw, for the reason the announcement editor's resource
 * gives: a resolved value with the Hindi fallback applied would make an empty
 * English field look filled in, and the next save would write the Hindi into
 * it. The public breakdown resolves through `LocalizedText` instead.
 *
 * @mixin AccountingCategory
 */
class AccountingCategoryResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var AccountingCategory $category */
        $category = $this->resource;

        return [
            'id' => $this->id,
            'code' => $this->code,

            'type' => $this->type,
            'type_label' => TransactionType::label($category->type),

            'name_hi' => $this->name_hi,
            'name_en' => $this->name_en,
            'description_hi' => $this->description_hi,
            'description_en' => $this->description_en,

            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,

            // How many entries are filed under it, when the caller asked for
            // the count. It is what decides whether the type may still be
            // changed and whether deletion is available at all, so it is
            // reported as the number rather than as somebody's boolean reading
            // of it.
            'transaction_count' => $this->whenCounted('transactions'),
        ];
    }
}

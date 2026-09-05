<?php

declare(strict_types=1);

namespace App\Http\Requests\Accounting;

use App\Support\Permission;
use App\Support\TransactionType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creating or editing one of the headings the books are filed under.
 *
 * The reserved `donation` code and the rule that a used category's type cannot
 * change are both enforced in `AccountingCategoryService`, not here: they are
 * facts about the ledger's history rather than about this payload.
 */
class StoreAccountingCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ACCOUNTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        $id = $this->route('category')?->id;

        return [
            'code' => [
                'nullable', 'string', 'max:50',
                Rule::unique('accounting_categories', 'code')->ignore($id),
            ],
            'type' => ['required', Rule::in(TransactionType::all())],

            // Hindi is the source language and is required; English is optional
            // and falls back to it on read.
            'name_hi' => ['required', 'string', 'max:150'],
            'name_en' => ['nullable', 'string', 'max:150'],
            'description_hi' => ['nullable', 'string', 'max:500'],
            'description_en' => ['nullable', 'string', 'max:500'],

            'sort_order' => ['nullable', 'integer', 'min:0', 'max:100000'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['code', 'name_en', 'description_hi', 'description_en'] as $key) {
            $value = $this->input($key);
            if (is_string($value) && trim($value) === '') {
                $this->merge([$key => null]);
            }
        }
    }
}

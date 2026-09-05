<?php

declare(strict_types=1);

namespace App\Services\Accounting;

use App\Exceptions\AccountingGuardException;
use App\Models\AccountingCategory;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;
use App\Support\TransactionType;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Str;

/**
 * The headings the temple's money is filed under.
 *
 * Two rules, and both are about not destroying the past:
 *
 *  * a category that has ever been used **cannot be deleted**, only
 *    deactivated — deleting one would turn old entries into "₹12,000, heading:
 *    —", which is exactly the thing a ledger exists to prevent;
 *  * the `donation` code is **reserved**, because donated income is counted
 *    from the donation register and a heading by that name is an invitation to
 *    count it twice (PHASE_9_PLAN assumption N1).
 */
class AccountingCategoryService
{
    public function __construct(private readonly AuditLogger $audit) {}

    /**
     * @param  array{type?: string, active_only?: bool}  $filters
     * @return Collection<int, AccountingCategory>
     */
    public function list(array $filters = []): Collection
    {
        $query = AccountingCategory::query()->inPickerOrder();

        if (isset($filters['type']) && TransactionType::exists((string) $filters['type'])) {
            $query->where('type', $filters['type']);
        }

        if (($filters['active_only'] ?? false) === true) {
            $query->where('is_active', true);
        }

        return $query->get();
    }

    /** @param array<string, mixed> $attributes */
    public function create(array $attributes, User $actor): AccountingCategory
    {
        $category = new AccountingCategory;
        $this->apply($category, $attributes, isNew: true);

        $category->created_by = $actor->id;
        $category->updated_by = $actor->id;
        $category->save();

        return $category;
    }

    /**
     * Edits a category.
     *
     * The **type is not editable once the category has been used**. Flipping a
     * heading from expense to income would move every historical entry filed
     * under it to the other side of the books — silently, and in figures the
     * village has already read.
     *
     * @param  array<string, mixed>  $attributes
     */
    public function update(AccountingCategory $category, array $attributes, User $actor): AccountingCategory
    {
        if ($this->isInUse($category)) {
            unset($attributes['type'], $attributes['code']);
        }

        $this->apply($category, $attributes, isNew: false);

        $category->updated_by = $actor->id;
        $category->save();

        return $category;
    }

    /**
     * Removes an unused category.
     *
     * A used one is refused with a message that names the count and says what
     * to do instead. The database's `restrictOnDelete` says the same thing one
     * layer down, so the rule holds even if this method is bypassed.
     */
    public function delete(AccountingCategory $category): void
    {
        $count = $category->transactions()->count();

        if ($count > 0) {
            throw AccountingGuardException::categoryInUse($count);
        }

        // Only ever an unused heading — the guard above is what makes that
        // true — but it is still a heading disappearing from the books, and
        // the ledger's whole promise is that nothing about it vanishes
        // unrecorded.
        $this->audit->record(
            action: AuditAction::CONTENT_DELETED,
            entity: $category,
            before: [
                'code' => $category->code,
                'type' => $category->type,
                'name_hi' => $category->name_hi,
            ],
            label: $category->name_hi,
        );

        $category->delete();
    }

    public function isInUse(AccountingCategory $category): bool
    {
        return $category->transactions()->exists();
    }

    /** @param array<string, mixed> $attributes */
    private function apply(AccountingCategory $category, array $attributes, bool $isNew): void
    {
        if (array_key_exists('code', $attributes)) {
            $code = Str::slug((string) $attributes['code']);

            if ($code === (string) config('accounting.donation_category_code', 'donation')) {
                throw AccountingGuardException::categoryCodeReserved();
            }

            $category->code = $code;
        }

        if ($isNew && ($category->code ?? '') === '') {
            $category->code = Str::slug((string) ($attributes['name_en'] ?? $attributes['name_hi'] ?? ''))
                ?: 'category-'.Str::lower(Str::random(6));
        }

        if (array_key_exists('type', $attributes)) {
            $type = (string) $attributes['type'];
            $category->type = TransactionType::exists($type) ? $type : TransactionType::EXPENSE;
        }

        foreach (['name_hi', 'name_en', 'description_hi', 'description_en'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $value = trim((string) ($attributes[$field] ?? ''));
                // Hindi is required and is never nulled; English absent means
                // absent, and the read falls back rather than being filled in
                // with a copy of the Hindi.
                $category->{$field} = $value === '' && $field !== 'name_hi' ? null : $value;
            }
        }

        if (array_key_exists('sort_order', $attributes)) {
            $category->sort_order = max(0, (int) $attributes['sort_order']);
        }

        if (array_key_exists('is_active', $attributes)) {
            $category->is_active = (bool) $attributes['is_active'];
        }

        $category->type ??= TransactionType::EXPENSE;
        $category->is_active ??= true;
    }
}

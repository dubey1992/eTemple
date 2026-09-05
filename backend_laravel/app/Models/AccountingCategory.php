<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\TransactionType;
use Database\Factories\AccountingCategoryFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * What the temple's money is received for and spent on (spec Phase 9 entity).
 *
 * @property int $id
 * @property string $code
 * @property string $type
 * @property string $name_hi
 * @property string|null $name_en
 * @property bool $is_active
 */
class AccountingCategory extends Model
{
    /** @use HasFactory<AccountingCategoryFactory> */
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'code', 'type', 'name_hi', 'name_en',
        'description_hi', 'description_en',
        'sort_order', 'is_active',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    /** @return HasMany<Transaction, $this> */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class, 'category_id');
    }

    /** @return BelongsTo<User, $this> */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function isIncome(): bool
    {
        return $this->type === TransactionType::INCOME;
    }

    /**
     * The reserved code: donated income is counted from the donation register,
     * never re-entered here (PHASE_9_PLAN assumption N1).
     */
    public function isReservedForDonations(): bool
    {
        return $this->code === (string) config('accounting.donation_category_code', 'donation');
    }

    /**
     * The order a picker offers them: active first, then the committee's own
     * ordering, then alphabetically by the Hindi name so two categories sharing
     * a sort order do not swap places between requests.
     *
     * @param  Builder<AccountingCategory>  $query
     */
    public function scopeInPickerOrder(Builder $query): void
    {
        $query->orderByDesc('is_active')
            ->orderBy('sort_order')
            ->orderBy('name_hi');
    }
}

<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\Money;
use App\Support\PaymentMode;
use App\Support\TransactionType;
use Database\Factories\TransactionFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * One movement of the temple's money (spec Phase 9 entity).
 *
 * The lifecycle mirrors a donation's, so the console behaves the same way on
 * both sides of the books:
 *
 *   pending ──approve──▶ approved ──reverse──▶ reversed
 *      └────────────────reverse────────────────────▶
 *
 * **Only `approved` counts in any total**, public or admin. The requirement
 * says "only approved data in public totals"; it is written more strongly than
 * that here, because a treasurer's screen showing a different figure from the
 * public page — with no label saying why — is how a committee ends up quoting
 * the wrong number in a meeting (PHASE_9_PLAN assumption N2).
 *
 * @property int $id
 * @property string $type
 * @property int $category_id
 * @property int $amount_paise
 * @property Carbon $transaction_date
 * @property string $payment_mode
 * @property string $status
 */
class Transaction extends Model
{
    /** @use HasFactory<TransactionFactory> */
    use HasFactory;

    /** Recorded, not yet checked against the bill or the statement. */
    public const STATUS_PENDING = 'pending';

    /** Checked. Counts in every total, and is locked to editing. */
    public const STATUS_APPROVED = 'approved';

    /** Cancelled. Counts in no total; the row and its reason stay. */
    public const STATUS_REVERSED = 'reversed';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [self::STATUS_PENDING, self::STATUS_APPROVED, self::STATUS_REVERSED];
    }

    /**
     * Deliberately not `status`, not the approval or reversal columns, and not
     * any of the `attachment_*` columns: those change only through the
     * service's own operations, never by a payload naming them.
     *
     * @var list<string>
     */
    protected $fillable = [
        'type', 'category_id', 'amount_paise', 'transaction_date',
        'payment_mode', 'reference_number', 'description', 'payee_name',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'transaction_date' => 'date',
            'amount_paise' => 'integer',
            'attachment_size' => 'integer',
            'approved_at' => 'datetime',
            'reversed_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<AccountingCategory, $this> */
    public function category(): BelongsTo
    {
        return $this->belongsTo(AccountingCategory::class, 'category_id');
    }

    /** @return BelongsTo<User, $this> */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /** @return BelongsTo<User, $this> */
    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    /** @return BelongsTo<User, $this> */
    public function reversedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reversed_by');
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isApproved(): bool
    {
        return $this->status === self::STATUS_APPROVED;
    }

    public function isReversed(): bool
    {
        return $this->status === self::STATUS_REVERSED;
    }

    public function isIncome(): bool
    {
        return $this->type === TransactionType::INCOME;
    }

    /**
     * True once the figure has been counted in a total somebody has read.
     *
     * From here only the description may change: an approved amount has been
     * published, and editing it silently would leave the page and the books
     * disagreeing with no trace of which changed (assumption N4).
     */
    public function isLocked(): bool
    {
        return $this->approved_at !== null;
    }

    public function requiresReference(): bool
    {
        return PaymentMode::requiresReference($this->payment_mode);
    }

    public function hasAttachment(): bool
    {
        return $this->attachment_path !== null;
    }

    /** "₹1,25,500.00", grouped the way the village reads it. */
    public function formattedAmount(): string
    {
        return Money::format($this->amount_paise);
    }

    /**
     * What counts towards a total.
     *
     * Applied in the query rather than by filtering a collection, so a total
     * cannot accidentally be the total of one page (assumption N11).
     *
     * @param  Builder<Transaction>  $query
     */
    public function scopeCountable(Builder $query): void
    {
        $query->where('status', self::STATUS_APPROVED);
    }
}

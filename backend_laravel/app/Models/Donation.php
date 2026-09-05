<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\Money;
use App\Support\PaymentMode;
use Database\Factories\DonationFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * One donation received by the temple (spec Phase 6 entity).
 *
 * The lifecycle is the point:
 *
 *   pending ──confirm──▶ confirmed ──reverse──▶ reversed
 *      └────────────────reverse────────────────────▶
 *
 * A receipt number is issued at **confirmation** and never changes; a reversed
 * donation keeps it. There is no delete at any status: reversal writes a
 * reason, a time and an actor onto the row and the row stays
 * (PHASE_6_PLAN assumptions N2 and N4).
 *
 * @property int $id
 * @property string|null $receipt_number
 * @property string $donor_name
 * @property int $amount_paise
 * @property Carbon $donation_date
 * @property string $payment_mode
 * @property string $status
 */
class Donation extends Model
{
    /** @use HasFactory<DonationFactory> */
    use HasFactory;

    /** Recorded, but not yet matched against the bank statement or cash box. */
    public const STATUS_PENDING = 'pending';

    /** Verified. Has a receipt number, and is counted in every total. */
    public const STATUS_CONFIRMED = 'confirmed';

    /** Cancelled. Keeps its receipt number, counted in no total. */
    public const STATUS_REVERSED = 'reversed';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [self::STATUS_PENDING, self::STATUS_CONFIRMED, self::STATUS_REVERSED];
    }

    /**
     * Fields an editor may set. Deliberately not `status`, `receipt_number` or
     * any of the audit columns: those change only through the service's
     * confirm and reverse operations.
     *
     * @var list<string>
     */
    protected $fillable = [
        'donor_name', 'donor_phone', 'donor_address', 'is_anonymous',
        'amount_paise', 'donation_date', 'payment_mode', 'reference_number',
        'purpose', 'notes',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'donation_date' => 'date',
            'amount_paise' => 'integer',
            'is_anonymous' => 'boolean',
            'confirmed_at' => 'datetime',
            'reversed_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    /** @return BelongsTo<User, $this> */
    public function confirmedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'confirmed_by');
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

    public function isConfirmed(): bool
    {
        return $this->status === self::STATUS_CONFIRMED;
    }

    public function isReversed(): bool
    {
        return $this->status === self::STATUS_REVERSED;
    }

    /**
     * True once a receipt exists in somebody's hand.
     *
     * From this moment only `notes` may be edited: changing the amount, the
     * date, the payer or the mode would make the database and the paper
     * disagree, and the correction for anything else is to reverse and record
     * again (assumption N3).
     */
    public function isLocked(): bool
    {
        return $this->receipt_number !== null;
    }

    public function requiresReference(): bool
    {
        return PaymentMode::requiresReference($this->payment_mode);
    }

    /** "₹1,25,500.00", grouped the way the village reads it. */
    public function formattedAmount(): string
    {
        return Money::format($this->amount_paise);
    }

    /**
     * What counts towards a total: confirmed, and not reversed.
     *
     * Applied in the query rather than by filtering a collection, so a total
     * cannot accidentally be the total of one page.
     *
     * @param  Builder<Donation>  $query
     * @return Builder<Donation>
     */
    public function scopeCountable(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_CONFIRMED);
    }
}

<?php

declare(strict_types=1);

namespace App\Services\Donations;

use App\Exceptions\DonationGuardException;
use App\Models\Donation;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;
use App\Support\DonationPurpose;
use App\Support\Money;
use App\Support\PaymentMode;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The rules that keep the temple's books honest.
 *
 * Four of them, and every one is enforced here rather than only in a form
 * request, so they hold however the record is reached:
 *
 *  1. an amount is more than zero, and is an integer number of paise;
 *  2. anything but cash carries a reference the treasurer can match;
 *  3. once a receipt has been issued, only the notes may change;
 *  4. nothing is ever deleted — reversal is the only undo, and it needs a
 *     reason.
 */
class DonationService
{
    public function __construct(
        private readonly ReceiptNumberGenerator $receipts,
        private readonly AuditLogger $audit,
    ) {}

    /**
     * The admin list, paginated and filtered.
     *
     * @param  array{status?: string, mode?: string, purpose?: string, from?: string, to?: string, q?: string, per_page?: int}  $filters
     * @return LengthAwarePaginator<int, Donation>
     */
    public function list(array $filters = []): LengthAwarePaginator
    {
        $perPage = max(1, min(
            $filters['per_page'] ?? (int) config('donations.default_per_page', 25),
            (int) config('donations.max_per_page', 100),
        ));

        return $this->filtered($filters)
            ->with(['recordedBy:id,first_name,last_name', 'confirmedBy:id,first_name,last_name'])
            ->orderByDesc('donation_date')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * Count and total for the current filter.
     *
     * Computed by the database over **confirmed** rows, never by adding up a
     * page of results — which would quietly report the total of one page as the
     * total of everything (PHASE_6_PLAN assumption N14).
     *
     * @param  array<string, mixed>  $filters
     * @return array{total_paise: int, confirmed_count: int, pending_count: int, pending_paise: int, reversed_count: int, donor_count: int}
     */
    public function summary(array $filters = []): array
    {
        // The status filter is dropped: a summary that honoured it would report
        // "total received: 0" whenever the reader happened to be looking at the
        // pending tab.
        $base = fn () => $this->filtered(array_diff_key($filters, ['status' => null]));

        $confirmed = $base()->where('status', Donation::STATUS_CONFIRMED);

        return [
            'total_paise' => (int) $base()
                ->where('status', Donation::STATUS_CONFIRMED)
                ->sum('amount_paise'),
            'confirmed_count' => (int) $confirmed->count(),
            'pending_count' => (int) $base()->where('status', Donation::STATUS_PENDING)->count(),
            'pending_paise' => (int) $base()
                ->where('status', Donation::STATUS_PENDING)
                ->sum('amount_paise'),
            'reversed_count' => (int) $base()->where('status', Donation::STATUS_REVERSED)->count(),
            // Distinct payers, which is the "दानदाता" figure the approved
            // prototype's transparency block shows.
            'donor_count' => (int) $base()
                ->where('status', Donation::STATUS_CONFIRMED)
                ->distinct()
                ->count('donor_name'),
        ];
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function record(array $attributes, User $actor): Donation
    {
        return DB::transaction(function () use ($attributes, $actor) {
            $donation = new Donation;
            $this->apply($donation, $attributes);

            $donation->status = Donation::STATUS_PENDING;
            $donation->recorded_by = $actor->id;
            $donation->updated_by = $actor->id;
            $donation->save();

            $this->audit->record(
                action: AuditAction::DONATION_RECORDED,
                entity: $donation,
                after: $this->snapshot($donation),
                label: $this->labelFor($donation),
            );

            return $donation->fresh() ?? $donation;
        });
    }

    /**
     * Edits a donation.
     *
     * Once a receipt exists only `notes` may change; anything else is refused
     * with a message that says to reverse and record again (assumption N3).
     *
     * @param  array<string, mixed>  $attributes
     */
    public function update(Donation $donation, array $attributes, User $actor): Donation
    {
        if ($donation->isLocked() && $this->changesMoreThanNotes($donation, $attributes)) {
            throw DonationGuardException::receiptedAndLocked();
        }

        return DB::transaction(function () use ($donation, $attributes, $actor) {
            $before = $this->snapshot($donation);

            if ($donation->isLocked()) {
                // Only the notes, whatever else the payload contained.
                $donation->notes = $this->text($attributes, 'notes');
            } else {
                $this->apply($donation, $attributes);
            }

            $donation->updated_by = $actor->id;
            $donation->save();

            // An edited donation is the first thing an auditor looks at, so
            // what changed is recorded rather than merely that something did.
            $this->audit->recordChange(
                action: AuditAction::DONATION_UPDATED,
                entity: $donation,
                before: $before,
                after: $this->snapshot($donation),
                label: $this->labelFor($donation),
            );

            return $donation->fresh() ?? $donation;
        });
    }

    /**
     * Verifies a donation and issues its receipt number.
     *
     * The number is issued here and nowhere else: the prototype's own words are
     * that a receipt follows verification, so a number that exists always
     * corresponds to a receipt that was really given (assumption N2).
     */
    public function confirm(Donation $donation, User $actor): Donation
    {
        if ($donation->isReversed()) {
            throw DonationGuardException::cannotConfirmReversed();
        }

        if ($donation->isConfirmed()) {
            throw DonationGuardException::alreadyConfirmed();
        }

        return DB::transaction(function () use ($donation, $actor) {
            $this->receipts->assign($donation);

            $donation->status = Donation::STATUS_CONFIRMED;
            $donation->confirmed_at = now();
            $donation->confirmed_by = $actor->id;
            $donation->updated_by = $actor->id;
            $donation->save();

            // What changed, not the whole record. A verification alters the
            // status and issues a number; listing eleven unchanged fields
            // beside an empty column reads as though all of them moved.
            $this->audit->record(
                action: AuditAction::DONATION_CONFIRMED,
                entity: $donation,
                after: [
                    'status' => $donation->status,
                    'receipt_number' => $donation->receipt_number,
                ],
                context: 'रसीद संख्या / Receipt: '.$donation->receipt_number,
                label: $this->labelFor($donation),
            );

            return $donation->fresh() ?? $donation;
        });
    }

    /**
     * The only undo there is.
     *
     * The row stays, keeps its receipt number, and stops counting towards every
     * total. The reason is required: "why was five thousand rupees removed from
     * the books" is the first question an auditor asks (assumption N4).
     */
    public function reverse(Donation $donation, string $reason, User $actor): Donation
    {
        if ($donation->isReversed()) {
            throw DonationGuardException::alreadyReversed();
        }

        $reason = trim($reason);
        if ($reason === '') {
            throw DonationGuardException::reversalReasonRequired();
        }

        return DB::transaction(function () use ($donation, $reason, $actor) {
            $donation->status = Donation::STATUS_REVERSED;
            $donation->reversal_reason = mb_substr($reason, 0, 500);
            $donation->reversed_at = now();
            $donation->reversed_by = $actor->id;
            $donation->updated_by = $actor->id;
            $donation->save();

            // The reason travels into the trail: "why was five thousand rupees
            // removed from the books" is the first question an auditor asks,
            // and the answer should not need a second lookup.
            $this->audit->record(
                action: AuditAction::DONATION_REVERSED,
                entity: $donation,
                after: [
                    'status' => $donation->status,
                    'reversal_reason' => $donation->reversal_reason,
                ],
                context: $donation->reversal_reason,
                label: $this->labelFor($donation),
            );

            return $donation->fresh() ?? $donation;
        });
    }

    /**
     * The fields worth remembering about a donation.
     *
     * Not the whole row: `created_at`, `updated_by` and the rest answer no
     * question, and a diff full of them hides the one line that matters.
     *
     * @return array<string, mixed>
     */
    private function snapshot(Donation $donation): array
    {
        return [
            'donor_name' => $donation->donor_name,
            'donor_phone' => $donation->donor_phone,
            'is_anonymous' => $donation->is_anonymous,
            'amount_paise' => $donation->amount_paise,
            'donation_date' => $donation->donation_date?->toDateString(),
            'purpose' => $donation->purpose,
            'payment_mode' => $donation->payment_mode,
            'reference_number' => $donation->reference_number,
            'receipt_number' => $donation->receipt_number,
            'status' => $donation->status,
            'notes' => $donation->notes,
        ];
    }

    /** Something readable in a list, without joining anything. */
    private function labelFor(Donation $donation): string
    {
        return trim(($donation->receipt_number ?? '—').' · '.$donation->donor_name);
    }

    // --- internals ----------------------------------------------------------

    /**
     * @param  array<string, mixed>  $filters
     * @return Builder<Donation>
     */
    private function filtered(array $filters): Builder
    {
        $query = Donation::query();

        if (isset($filters['status']) && in_array($filters['status'], Donation::statuses(), true)) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['mode']) && PaymentMode::exists((string) $filters['mode'])) {
            $query->where('payment_mode', $filters['mode']);
        }

        if (isset($filters['purpose']) && DonationPurpose::exists((string) $filters['purpose'])) {
            $query->where('purpose', $filters['purpose']);
        }

        if (isset($filters['from'])) {
            $query->whereDate('donation_date', '>=', $filters['from']);
        }

        if (isset($filters['to'])) {
            $query->whereDate('donation_date', '<=', $filters['to']);
        }

        if (isset($filters['q']) && trim((string) $filters['q']) !== '') {
            $term = '%'.addcslashes(trim((string) $filters['q']), '%_\\').'%';
            $query->where(function (Builder $inner) use ($term) {
                $inner->where('donor_name', 'like', $term)
                    ->orWhere('receipt_number', 'like', $term)
                    ->orWhere('reference_number', 'like', $term);
            });
        }

        return $query;
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function apply(Donation $donation, array $attributes): void
    {
        if (array_key_exists('amount', $attributes)) {
            $donation->amount_paise = $this->paise($attributes['amount']);
        }

        if (array_key_exists('donation_date', $attributes)) {
            $donation->donation_date = $this->date((string) $attributes['donation_date']);
        }

        if (array_key_exists('payment_mode', $attributes)) {
            $donation->payment_mode = (string) $attributes['payment_mode'];
        }

        foreach (['donor_name', 'donor_phone', 'donor_address', 'reference_number', 'notes'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $donation->{$field} = $this->text($attributes, $field);
            }
        }

        if (array_key_exists('purpose', $attributes)) {
            $purpose = (string) $attributes['purpose'];
            $donation->purpose = DonationPurpose::exists($purpose)
                ? $purpose
                : DonationPurpose::GENERAL;
        }

        if (array_key_exists('is_anonymous', $attributes)) {
            $donation->is_anonymous = (bool) $attributes['is_anonymous'];
        }

        $donation->purpose ??= DonationPurpose::GENERAL;

        // Repeated here and not only in the form request, so the rule holds
        // however the record is reached.
        if (($donation->amount_paise ?? 0) <= 0) {
            throw DonationGuardException::amountNotPositive();
        }

        if ($donation->requiresReference() && trim((string) $donation->reference_number) === '') {
            throw DonationGuardException::referenceRequired();
        }
    }

    /** @param array<string, mixed> $attributes */
    private function changesMoreThanNotes(Donation $donation, array $attributes): bool
    {
        $comparisons = [
            'donor_name' => fn ($v) => $this->nullIfBlank((string) $v) !== $donation->donor_name,
            'donor_phone' => fn ($v) => $this->nullIfBlank((string) $v) !== $donation->donor_phone,
            'donor_address' => fn ($v) => $this->nullIfBlank((string) $v) !== $donation->donor_address,
            'reference_number' => fn ($v) => $this->nullIfBlank((string) $v) !== $donation->reference_number,
            'payment_mode' => fn ($v) => (string) $v !== $donation->payment_mode,
            'purpose' => fn ($v) => (string) $v !== $donation->purpose,
            'is_anonymous' => fn ($v) => (bool) $v !== $donation->is_anonymous,
            'amount' => fn ($v) => $this->paise($v) !== $donation->amount_paise,
            'donation_date' => fn ($v) => $this->date((string) $v)->toDateString()
                !== $donation->donation_date->toDateString(),
        ];

        foreach ($comparisons as $field => $differs) {
            if (array_key_exists($field, $attributes) && $differs($attributes[$field])) {
                return true;
            }
        }

        return false;
    }

    private function paise(mixed $amount): int
    {
        $paise = match (true) {
            is_int($amount) => $amount * Money::PAISE_PER_RUPEE,
            is_string($amount) => Money::parse($amount),
            is_float($amount) => Money::parse((string) $amount),
            default => null,
        };

        if ($paise === null) {
            throw DonationGuardException::amountUnreadable();
        }

        if ($paise <= 0) {
            throw DonationGuardException::amountNotPositive();
        }

        $maxRupees = (int) config('donations.max_rupees', 10_000_000);
        if ($paise > $maxRupees * Money::PAISE_PER_RUPEE) {
            throw DonationGuardException::amountTooLarge($maxRupees);
        }

        return $paise;
    }

    private function date(string $value): Carbon
    {
        $date = Carbon::parse($value)->startOfDay();

        if ($date->isFuture()) {
            throw DonationGuardException::dateInFuture();
        }

        $limit = (int) config('donations.backdate_limit_days', 366);
        if ($date->lt(now()->startOfDay()->subDays($limit))) {
            throw DonationGuardException::dateTooOld($limit);
        }

        return $date;
    }

    /** @param array<string, mixed> $attributes */
    private function text(array $attributes, string $key): ?string
    {
        $value = $attributes[$key] ?? null;

        return is_string($value) ? $this->nullIfBlank($value) : null;
    }

    private function nullIfBlank(string $value): ?string
    {
        $trimmed = trim($value);

        return $trimmed === '' ? null : $trimmed;
    }
}

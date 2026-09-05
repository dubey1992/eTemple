<?php

declare(strict_types=1);

namespace App\Services\Accounting;

use App\Exceptions\AccountingGuardException;
use App\Models\AccountingCategory;
use App\Models\Transaction;
use App\Models\User;
use App\Support\Money;
use App\Support\PaymentMode;
use App\Support\TransactionType;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The rules that keep the temple's ledger defensible.
 *
 * Every one is enforced here rather than only in a form request, so it holds
 * however the record is reached:
 *
 *  1. an amount is more than zero, and is an integer number of paise;
 *  2. anything but cash carries a reference the treasurer can match;
 *  3. a category belongs to one side of the books, and the entry must agree;
 *  4. donations are never entered here — they are counted from their own
 *     register, and entering one twice would publish it at twice its value;
 *  5. once approved, only the description may change;
 *  6. nothing is ever deleted — reversal is the only undo, and it needs a
 *     reason.
 */
class TransactionService
{
    public function __construct(private readonly AttachmentStore $attachments) {}

    /**
     * The register, paginated and filtered.
     *
     * @param  array{status?: string, type?: string, category_id?: int, mode?: string, from?: string, to?: string, q?: string, per_page?: int}  $filters
     * @return LengthAwarePaginator<int, Transaction>
     */
    public function list(array $filters = []): LengthAwarePaginator
    {
        $perPage = max(1, min(
            $filters['per_page'] ?? (int) config('accounting.default_per_page', 25),
            (int) config('accounting.max_per_page', 100),
        ));

        return $this->filtered($filters)
            ->with([
                'category',
                'createdBy:id,first_name,last_name',
                'approvedBy:id,first_name,last_name',
            ])
            ->orderByDesc('transaction_date')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * Count and total for the current filter.
     *
     * Computed by the database over **approved** rows, never by adding up a
     * page of results — which would quietly report the total of one page as the
     * total of everything (PHASE_9_PLAN assumption N11).
     *
     * The status filter is dropped for the same reason it is in the donation
     * summary: a summary that honoured it would report "spent: 0" whenever the
     * reader happened to be looking at the pending tab.
     *
     * @param  array<string, mixed>  $filters
     * @return array{income_paise: int, expense_paise: int, net_paise: int, approved_count: int, pending_count: int, pending_income_paise: int, pending_expense_paise: int, reversed_count: int}
     */
    public function summary(array $filters = []): array
    {
        $base = fn () => $this->filtered(array_diff_key($filters, ['status' => null]));

        $approvedOfType = fn (string $type) => (int) $base()
            ->where('status', Transaction::STATUS_APPROVED)
            ->where('type', $type)
            ->sum('amount_paise');

        $pendingOfType = fn (string $type) => (int) $base()
            ->where('status', Transaction::STATUS_PENDING)
            ->where('type', $type)
            ->sum('amount_paise');

        $income = $approvedOfType(TransactionType::INCOME);
        $expense = $approvedOfType(TransactionType::EXPENSE);

        return [
            'income_paise' => $income,
            'expense_paise' => $expense,
            // Signed on purpose: a month that spent more than it received is a
            // real month, and clamping it at zero would hide exactly the fact a
            // treasurer needs to see.
            'net_paise' => $income - $expense,
            'approved_count' => (int) $base()->where('status', Transaction::STATUS_APPROVED)->count(),
            'pending_count' => (int) $base()->where('status', Transaction::STATUS_PENDING)->count(),
            'pending_income_paise' => $pendingOfType(TransactionType::INCOME),
            'pending_expense_paise' => $pendingOfType(TransactionType::EXPENSE),
            'reversed_count' => (int) $base()->where('status', Transaction::STATUS_REVERSED)->count(),
        ];
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function record(array $attributes, User $actor, ?UploadedFile $attachment = null): Transaction
    {
        return DB::transaction(function () use ($attributes, $actor, $attachment) {
            $transaction = new Transaction;
            $this->apply($transaction, $attributes);

            if ($attachment !== null) {
                $transaction->forceFill($this->attachments->store($attachment));
            }

            $transaction->status = Transaction::STATUS_PENDING;
            $transaction->created_by = $actor->id;
            $transaction->updated_by = $actor->id;
            $transaction->save();

            return $transaction->fresh() ?? $transaction;
        });
    }

    /**
     * Edits a transaction.
     *
     * Once approved only `description` may change; anything else is refused
     * with a message that says to reverse and record again (assumption N4).
     *
     * @param  array<string, mixed>  $attributes
     */
    public function update(
        Transaction $transaction,
        array $attributes,
        User $actor,
        ?UploadedFile $attachment = null,
    ): Transaction {
        if ($transaction->isLocked() && $this->changesMoreThanDescription($transaction, $attributes)) {
            throw AccountingGuardException::approvedAndLocked();
        }

        // A bill on an approved entry is part of the evidence for a published
        // figure. Replacing it is not an edit to a note.
        if ($transaction->isLocked() && $attachment !== null) {
            throw AccountingGuardException::approvedAndLocked();
        }

        return DB::transaction(function () use ($transaction, $attributes, $actor, $attachment) {
            if ($transaction->isLocked()) {
                $transaction->description = $this->text($attributes, 'description');
            } else {
                $this->apply($transaction, $attributes);
            }

            if ($attachment !== null) {
                $previous = $transaction->attachment_path;
                $transaction->forceFill($this->attachments->store($attachment));
                $this->attachments->forget($previous);
            }

            $transaction->updated_by = $actor->id;
            $transaction->save();

            return $transaction->fresh() ?? $transaction;
        });
    }

    /**
     * Checks a transaction against its bill, and counts it.
     *
     * From here the figure is in every total, including the one the village
     * reads, and the row is locked to everything but its description.
     */
    public function approve(Transaction $transaction, User $actor): Transaction
    {
        if ($transaction->isReversed()) {
            throw AccountingGuardException::cannotApproveReversed();
        }

        if ($transaction->isApproved()) {
            throw AccountingGuardException::alreadyApproved();
        }

        // Separation of duties, when the committee has asked for it
        // (assumption N3). Off by default: this temple may have one treasurer,
        // and a control that deadlocks the books is a control nobody keeps.
        if (config('accounting.require_second_approver')
            && $transaction->created_by !== null
            && $transaction->created_by === $actor->id) {
            throw AccountingGuardException::needsASecondApprover();
        }

        return DB::transaction(function () use ($transaction, $actor) {
            $transaction->status = Transaction::STATUS_APPROVED;
            $transaction->approved_at = now();
            $transaction->approved_by = $actor->id;
            $transaction->updated_by = $actor->id;
            $transaction->save();

            return $transaction->fresh() ?? $transaction;
        });
    }

    /**
     * The only undo there is.
     *
     * The row stays, keeps its bill, and stops counting towards every total.
     * The reason is required: an amount that was published and then removed is
     * the first thing an auditor asks about (assumption N4).
     */
    public function reverse(Transaction $transaction, string $reason, User $actor): Transaction
    {
        if ($transaction->isReversed()) {
            throw AccountingGuardException::alreadyReversed();
        }

        $reason = trim($reason);
        if ($reason === '') {
            throw AccountingGuardException::reversalReasonRequired();
        }

        return DB::transaction(function () use ($transaction, $reason, $actor) {
            $transaction->status = Transaction::STATUS_REVERSED;
            $transaction->reversal_reason = mb_substr($reason, 0, 500);
            $transaction->reversed_at = now();
            $transaction->reversed_by = $actor->id;
            $transaction->updated_by = $actor->id;
            $transaction->save();

            return $transaction->fresh() ?? $transaction;
        });
    }

    // --- internals ----------------------------------------------------------

    /**
     * @param  array<string, mixed>  $filters
     * @return Builder<Transaction>
     */
    private function filtered(array $filters): Builder
    {
        $query = Transaction::query();

        if (isset($filters['status']) && in_array($filters['status'], Transaction::statuses(), true)) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['type']) && TransactionType::exists((string) $filters['type'])) {
            $query->where('type', $filters['type']);
        }

        if (isset($filters['category_id']) && (int) $filters['category_id'] > 0) {
            $query->where('category_id', (int) $filters['category_id']);
        }

        if (isset($filters['mode']) && PaymentMode::exists((string) $filters['mode'])) {
            $query->where('payment_mode', $filters['mode']);
        }

        if (isset($filters['from'])) {
            $query->whereDate('transaction_date', '>=', $filters['from']);
        }

        if (isset($filters['to'])) {
            $query->whereDate('transaction_date', '<=', $filters['to']);
        }

        if (isset($filters['q']) && trim((string) $filters['q']) !== '') {
            $term = '%'.addcslashes(trim((string) $filters['q']), '%_\\').'%';
            $query->where(function (Builder $inner) use ($term) {
                $inner->where('payee_name', 'like', $term)
                    ->orWhere('description', 'like', $term)
                    ->orWhere('reference_number', 'like', $term);
            });
        }

        return $query;
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function apply(Transaction $transaction, array $attributes): void
    {
        if (array_key_exists('amount', $attributes)) {
            $transaction->amount_paise = $this->paise($attributes['amount']);
        }

        if (array_key_exists('transaction_date', $attributes)) {
            $transaction->transaction_date = $this->date((string) $attributes['transaction_date']);
        }

        if (array_key_exists('payment_mode', $attributes)) {
            $transaction->payment_mode = (string) $attributes['payment_mode'];
        }

        foreach (['reference_number', 'description', 'payee_name'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $transaction->{$field} = $this->text($attributes, $field);
            }
        }

        if (array_key_exists('category_id', $attributes)) {
            $this->applyCategory($transaction, $attributes);
        }

        // Repeated here and not only in the form request, so the rules hold
        // however the record is reached.
        if ($transaction->category_id === null) {
            throw AccountingGuardException::categoryRequired();
        }

        if (($transaction->amount_paise ?? 0) <= 0) {
            throw AccountingGuardException::amountNotPositive();
        }

        if ($transaction->requiresReference() && trim((string) $transaction->reference_number) === '') {
            throw AccountingGuardException::referenceRequired();
        }
    }

    /** @param array<string, mixed> $attributes */
    private function applyCategory(Transaction $transaction, array $attributes): void
    {
        $category = AccountingCategory::query()->find((int) $attributes['category_id']);

        if ($category === null) {
            throw AccountingGuardException::categoryRequired();
        }

        // The double-counting guard (assumption N1). Structural rather than
        // advisory: a rule written only in a manual is a rule that gets broken
        // by the third treasurer who never read it.
        if ($category->isReservedForDonations()) {
            throw AccountingGuardException::donationsAreNotTransactions();
        }

        if (! $category->is_active) {
            throw AccountingGuardException::categoryInactive();
        }

        // The requested type, if one was sent; otherwise the category's own.
        // The category is the authority either way — an entry filed on the
        // wrong side of the books would appear on the wrong side of the public
        // breakdown, silently.
        $requested = array_key_exists('type', $attributes)
            ? (string) $attributes['type']
            : $category->type;

        if ($requested !== $category->type) {
            throw AccountingGuardException::categoryTypeMismatch($category->type);
        }

        $transaction->category_id = $category->id;
        $transaction->type = $category->type;
    }

    /** @param array<string, mixed> $attributes */
    private function changesMoreThanDescription(Transaction $transaction, array $attributes): bool
    {
        $comparisons = [
            'payee_name' => fn ($v) => $this->nullIfBlank((string) $v) !== $transaction->payee_name,
            'reference_number' => fn ($v) => $this->nullIfBlank((string) $v) !== $transaction->reference_number,
            'payment_mode' => fn ($v) => (string) $v !== $transaction->payment_mode,
            'type' => fn ($v) => (string) $v !== $transaction->type,
            'category_id' => fn ($v) => (int) $v !== $transaction->category_id,
            'amount' => fn ($v) => $this->paise($v) !== $transaction->amount_paise,
            'transaction_date' => fn ($v) => $this->date((string) $v)->toDateString()
                !== $transaction->transaction_date->toDateString(),
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
            throw AccountingGuardException::amountUnreadable();
        }

        if ($paise <= 0) {
            throw AccountingGuardException::amountNotPositive();
        }

        $maxRupees = (int) config('accounting.max_rupees', 10_000_000);
        if ($paise > $maxRupees * Money::PAISE_PER_RUPEE) {
            throw AccountingGuardException::amountTooLarge($maxRupees);
        }

        return $paise;
    }

    private function date(string $value): Carbon
    {
        $date = Carbon::parse($value)->startOfDay();

        if ($date->isFuture()) {
            throw AccountingGuardException::dateInFuture();
        }

        $limit = (int) config('accounting.backdate_limit_days', 366);
        if ($date->lt(now()->startOfDay()->subDays($limit))) {
            throw AccountingGuardException::dateTooOld($limit);
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

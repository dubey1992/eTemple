<?php

declare(strict_types=1);

namespace App\Services\Donations;

use App\Models\Donation;
use Illuminate\Database\QueryException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Issues receipt numbers — unique, and immutable once issued.
 *
 * `RKT/2026-27/0001`: a prefix, the Indian financial year, and a sequence
 * within that year. The financial year is taken from the **donation's own
 * date**, not from the day it happened to be confirmed, so a donation and its
 * receipt sit in the same year's book; confirming a March donation in April
 * does not move it into next year's sequence.
 *
 * ## Why this is not just `max(id) + 1`
 *
 * Two treasurers confirming at the same moment both read the same highest
 * sequence and both build the same number. The application cannot prevent that
 * on its own, so it does not try to: the **unique index** on
 * `donations.receipt_number` is the guarantee, and this class retries when the
 * database refuses a collision. Uniqueness is enforced where it can actually be
 * enforced (PHASE_6_PLAN assumption N2).
 */
class ReceiptNumberGenerator
{
    /**
     * Enough attempts to survive a realistic race; a village temple will never
     * see two, and a hundred would mean something else is wrong.
     */
    private const MAX_ATTEMPTS = 10;

    /**
     * Assigns a number to a donation and persists it, retrying on collision.
     *
     * @return string the number that was issued
     *
     * @throws RuntimeException when the number could not be made unique
     */
    public function assign(Donation $donation): string
    {
        $year = $this->financialYearLabel($donation->donation_date);

        for ($attempt = 0; $attempt < self::MAX_ATTEMPTS; $attempt++) {
            $candidate = $this->compose($year, $this->nextSequence($year));

            try {
                // A conditional update rather than a save: if another request
                // has already numbered this donation, that number stands and
                // this one is discarded — a receipt number is issued once.
                $claimed = Donation::query()
                    ->whereKey($donation->id)
                    ->whereNull('receipt_number')
                    ->update(['receipt_number' => $candidate]);

                if ($claimed === 0) {
                    $existing = Donation::query()->whereKey($donation->id)->value('receipt_number');
                    if (is_string($existing) && $existing !== '') {
                        $donation->receipt_number = $existing;

                        return $existing;
                    }

                    // The row is gone, which is not something this class can fix.
                    throw new RuntimeException('The donation disappeared while its receipt was being issued.');
                }

                $donation->receipt_number = $candidate;

                return $candidate;
            } catch (QueryException $exception) {
                // Somebody else took this number between the read and the
                // write. Recompute and try again; anything that is not a
                // uniqueness violation is a real fault and is re-thrown.
                if (! $this->isUniqueViolation($exception)) {
                    throw $exception;
                }
            }
        }

        throw new RuntimeException(
            'Could not issue a unique receipt number after '.self::MAX_ATTEMPTS.' attempts.',
        );
    }

    /**
     * The label for the financial year containing [$date] — "2026-27".
     *
     * April to March, which is the year an Indian temple's books are kept in.
     */
    public function financialYearLabel(Carbon $date): string
    {
        $startMonth = (int) config('donations.financial_year_start_month', 4);
        $startYear = $date->month >= $startMonth ? $date->year : $date->year - 1;

        return sprintf('%d-%02d', $startYear, ($startYear + 1) % 100);
    }

    /** `RKT/2026-27/0001`. */
    public function compose(string $year, int $sequence): string
    {
        $prefix = (string) config('donations.receipt_prefix', 'RKT');
        $length = (int) config('donations.receipt_sequence_length', 4);

        return sprintf('%s/%s/%s', $prefix, $year, str_pad((string) $sequence, $length, '0', STR_PAD_LEFT));
    }

    /**
     * One past the highest sequence already issued in this financial year.
     *
     * Reads the maximum rather than counting rows: a number is never reused, so
     * counting would collide the moment anything was reversed or a year's
     * numbering started above one.
     */
    public function nextSequence(string $year): int
    {
        $prefix = (string) config('donations.receipt_prefix', 'RKT');
        $stem = $prefix.'/'.$year.'/';

        $highest = Donation::query()
            ->whereNotNull('receipt_number')
            ->where('receipt_number', 'like', $this->escapeLike($stem).'%')
            ->orderByDesc(DB::raw('LENGTH(receipt_number)'))
            ->orderByDesc('receipt_number')
            ->value('receipt_number');

        if (! is_string($highest)) {
            return 1;
        }

        $sequence = (int) substr($highest, strlen($stem));

        return $sequence + 1;
    }

    private function escapeLike(string $value): string
    {
        return addcslashes($value, '%_\\');
    }

    private function isUniqueViolation(QueryException $exception): bool
    {
        // 23000/23505 are the SQL-state families for an integrity constraint
        // violation; every driver this project runs on reports one of them.
        $state = (string) ($exception->errorInfo[0] ?? '');

        return in_array($state, ['23000', '23505'], true);
    }
}

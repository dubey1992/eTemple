<?php

declare(strict_types=1);

namespace App\Services\Enquiries;

use App\Models\Enquiry;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Issues enquiry references — `RKT/E/2026-27/0001`.
 *
 * The same shape as a receipt number, and for the same reason: a villager who
 * telephones the temple a week later needs to be able to say which message they
 * mean, and "the one I sent on Tuesday" is not that.
 *
 * Unlike a receipt number this is issued the moment the enquiry is stored,
 * because it is the only thing the public response contains — the visitor gets
 * a reference or they get nothing.
 *
 * Uniqueness is the database's unique index, not this class's arithmetic. Two
 * visitors submitting at the same moment read the same highest sequence; only
 * the index can settle it, and {@see EnquiryService} retries when it does.
 */
class EnquiryReferenceGenerator
{
    /** `RKT/E/2026-27/0001`. */
    public function next(?Carbon $at = null): string
    {
        $year = $this->financialYearLabel($at ?? now());

        return $this->compose($year, $this->nextSequence($year));
    }

    /**
     * The label for the financial year containing [$date] — "2026-27".
     *
     * April to March, matching the receipts. An enquiry and a donation made on
     * the same day belong to the same year's records, and a committee that
     * files them differently would have to remember two rules.
     */
    public function financialYearLabel(Carbon $date): string
    {
        $startMonth = (int) config('donations.financial_year_start_month', 4);
        $startYear = $date->month >= $startMonth ? $date->year : $date->year - 1;

        return sprintf('%d-%02d', $startYear, ($startYear + 1) % 100);
    }

    public function compose(string $year, int $sequence): string
    {
        $prefix = (string) config('enquiries.reference_prefix', 'RKT/E');
        $length = (int) config('enquiries.reference_sequence_length', 4);

        return sprintf('%s/%s/%s', $prefix, $year, str_pad((string) $sequence, $length, '0', STR_PAD_LEFT));
    }

    /**
     * One past the highest sequence issued this financial year.
     *
     * Reads the maximum rather than counting rows: nothing is ever deleted from
     * this table, but a `spam` row still holds its reference, and counting
     * would start colliding the day somebody wanted the numbering to begin
     * above one.
     */
    public function nextSequence(string $year): int
    {
        $stem = (string) config('enquiries.reference_prefix', 'RKT/E').'/'.$year.'/';

        $highest = Enquiry::query()
            ->where('reference', 'like', addcslashes($stem, '%_\\').'%')
            ->orderByDesc(DB::raw('LENGTH(reference)'))
            ->orderByDesc('reference')
            ->value('reference');

        if (! is_string($highest)) {
            return 1;
        }

        return ((int) substr($highest, strlen($stem))) + 1;
    }
}

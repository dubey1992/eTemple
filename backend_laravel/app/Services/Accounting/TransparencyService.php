<?php

declare(strict_types=1);

namespace App\Services\Accounting;

use App\Models\AccountingCategory;
use App\Models\Donation;
use App\Models\Transaction;
use App\Support\FinancialYear;
use App\Support\Language;
use App\Support\LocalizedText;
use App\Support\TransactionType;
use Illuminate\Support\Carbon;

/**
 * The figures the village reads.
 *
 * **This is the only place the public numbers are computed.** Not the
 * controller, not the resource, and never the client: a total assembled in two
 * places is a total that eventually disagrees with itself, and this particular
 * disagreement would be the temple appearing to misstate its accounts.
 *
 * Three rules shape every query below:
 *
 *  1. **Only approved money counts.** Pending is unchecked and reversed is
 *     cancelled; neither appears in any figure here, at any granularity.
 *  2. **Donated income is read from the donation register, never from the
 *     ledger.** Entering a donation in both places would publish it at twice
 *     its value, so the two sources are separate and are reported as separate
 *     lines (PHASE_9_PLAN assumption N1).
 *  3. **Nothing identifies a person.** No donor name, no payee, no individual
 *     row at any status. Category totals answer the question a villager asks
 *     and identify nobody (assumptions N6 and N9).
 *
 * Every figure is a `SUM` over a filtered query. Nothing here adds up a page of
 * results.
 */
class TransparencyService
{
    public function __construct(private readonly AccountingSettingService $settings) {}

    /**
     * The published figures for one financial year.
     *
     * @return array{
     *     year: int,
     *     year_label: string,
     *     starts_on: string,
     *     ends_on: string,
     *     opening_balance_paise: int,
     *     donations_paise: int,
     *     other_income_paise: int,
     *     total_income_paise: int,
     *     total_expense_paise: int,
     *     closing_balance_paise: int,
     *     donation_count: int,
     *     income_by_category: list<array{code: string, name: array{value: string|null, language: string, fallback_used: bool}, total_paise: int}>,
     *     expense_by_category: list<array{code: string, name: array{value: string|null, language: string, fallback_used: bool}, total_paise: int}>,
     *     as_of: string
     * }
     */
    public function forYear(FinancialYear $year, Language $language): array
    {
        $from = $year->startsOn();
        $to = $year->endsOn();

        $donations = $this->donationsBetween($from, $to);
        $otherIncome = $this->ledgerTotal(TransactionType::INCOME, $from, $to);
        $expense = $this->ledgerTotal(TransactionType::EXPENSE, $from, $to);

        $opening = $this->balanceBefore($from);

        return [
            'year' => $year->year,
            'year_label' => $year->label(),
            'starts_on' => $from->toDateString(),
            'ends_on' => $to->toDateString(),

            // Stated as its own line rather than folded into the total, so a
            // reader can see the books start somewhere (assumption N8).
            'opening_balance_paise' => $opening,

            'donations_paise' => $donations['total_paise'],
            'other_income_paise' => $otherIncome,
            'total_income_paise' => $donations['total_paise'] + $otherIncome,
            'total_expense_paise' => $expense,
            'closing_balance_paise' => $opening + $donations['total_paise'] + $otherIncome - $expense,

            // A count, never a name. See assumption N9 for why there is no
            // donor roll here and what building one would actually require.
            'donation_count' => $donations['count'],

            'income_by_category' => $this->byCategory(TransactionType::INCOME, $from, $to, $language),
            'expense_by_category' => $this->byCategory(TransactionType::EXPENSE, $from, $to, $language),

            'as_of' => Carbon::now()->toIso8601String(),
        ];
    }

    /**
     * The years the public page may be asked for, newest first.
     *
     * **The current financial year is always offered, even while empty**, and
     * it is always first. A page that quietly showed last year because this one
     * has no entries yet would put a heading of one year over the figures of
     * another — and a reader has no way to tell.
     *
     * Earlier years appear only if they have something in them. An empty past
     * year reads as "the temple received nothing that year", when the truth is
     * that its books were never kept here.
     *
     * @return list<FinancialYear>
     */
    public function publishedYears(): array
    {
        $current = FinancialYear::current();
        $earliest = $this->earliestYear();
        $years = [$current];

        foreach (FinancialYear::recent((int) config('accounting.public_years', 5), $earliest) as $year) {
            if ($year->year !== $current->year && $this->hasAnything($year)) {
                $years[] = $year;
            }
        }

        return $years;
    }

    public function isPublished(): bool
    {
        return $this->settings->current()->is_published;
    }

    /**
     * The temple's own words about its accounts, resolved for the reader's
     * language with the same Hindi fallback as the rest of the site.
     *
     * @return array{intro: LocalizedText, note: LocalizedText, opening_balance_date: string|null}
     */
    public function preamble(Language $language): array
    {
        $settings = $this->settings->current();

        return [
            'intro' => LocalizedText::resolve($settings->intro_hi, $settings->intro_en, $language),
            'note' => LocalizedText::resolve($settings->note_hi, $settings->note_en, $language),
            'opening_balance_date' => $settings->opening_balance_date?->toDateString(),
        ];
    }

    // --- internals ----------------------------------------------------------

    /**
     * Confirmed donations in a window.
     *
     * Read from the donation register rather than the ledger, and confirmed
     * only — a pending donation is money somebody has written down, not money
     * the treasurer has found (assumption N1).
     *
     * `is_anonymous` is not consulted, and cannot be: it decides whether a
     * donor may be *named*, and nothing here names anybody. A donation from a
     * donor who asked not to be named is still money the temple received, and
     * leaving it out of the total would misstate the accounts to hide a name
     * that is not being shown anyway.
     *
     * @return array{total_paise: int, count: int}
     */
    private function donationsBetween(Carbon $from, Carbon $to): array
    {
        $query = fn () => Donation::query()
            ->countable()
            ->whereBetween('donation_date', [$from->toDateString(), $to->toDateString()]);

        return [
            'total_paise' => (int) $query()->sum('amount_paise'),
            'count' => (int) $query()->count(),
        ];
    }

    private function ledgerTotal(string $type, Carbon $from, Carbon $to): int
    {
        return (int) Transaction::query()
            ->countable()
            ->where('type', $type)
            ->whereBetween('transaction_date', [$from->toDateString(), $to->toDateString()])
            ->sum('amount_paise');
    }

    /**
     * Everything the temple held when a year began: the stated opening balance,
     * plus every approved rupee that moved before that date.
     *
     * Computed, never stored. A correction to an old entry must not be able to
     * leave last year's closing balance and this year's opening balance
     * disagreeing (assumption N10).
     */
    private function balanceBefore(Carbon $start): int
    {
        $settings = $this->settings->current();

        $donations = (int) Donation::query()
            ->countable()
            ->whereDate('donation_date', '<', $start->toDateString())
            ->sum('amount_paise');

        $income = (int) Transaction::query()
            ->countable()
            ->where('type', TransactionType::INCOME)
            ->whereDate('transaction_date', '<', $start->toDateString())
            ->sum('amount_paise');

        $expense = (int) Transaction::query()
            ->countable()
            ->where('type', TransactionType::EXPENSE)
            ->whereDate('transaction_date', '<', $start->toDateString())
            ->sum('amount_paise');

        return $settings->opening_balance_paise + $donations + $income - $expense;
    }

    /**
     * Category totals — the granularity the public page publishes.
     *
     * Categories with nothing in them are omitted rather than listed at zero: a
     * heading with no money against it says nothing, and a column of zeros
     * makes the figures that matter harder to find.
     *
     * @return list<array{code: string, name: array{value: string|null, language: string, fallback_used: bool}, total_paise: int}>
     */
    private function byCategory(string $type, Carbon $from, Carbon $to, Language $language): array
    {
        /** @var array<int, int> $totals */
        $totals = Transaction::query()
            ->countable()
            ->where('type', $type)
            ->whereBetween('transaction_date', [$from->toDateString(), $to->toDateString()])
            ->groupBy('category_id')
            ->selectRaw('category_id, SUM(amount_paise) as total')
            ->pluck('total', 'category_id')
            ->map(fn ($total) => (int) $total)
            ->all();

        if ($totals === []) {
            return [];
        }

        $categories = AccountingCategory::query()
            ->whereIn('id', array_keys($totals))
            ->inPickerOrder()
            ->get();

        $rows = [];
        foreach ($categories as $category) {
            $rows[] = [
                'code' => $category->code,
                'name' => LocalizedText::resolve($category->name_hi, $category->name_en, $language)->toArray(),
                'total_paise' => $totals[$category->id] ?? 0,
            ];
        }

        // Largest first: "what did most of the money go on" is the question,
        // and a reader should not have to scan for the answer.
        usort($rows, fn (array $a, array $b) => $b['total_paise'] <=> $a['total_paise']);

        return $rows;
    }

    private function hasAnything(FinancialYear $year): bool
    {
        $from = $year->startsOn()->toDateString();
        $to = $year->endsOn()->toDateString();

        return Transaction::query()->countable()->whereBetween('transaction_date', [$from, $to])->exists()
            || Donation::query()->countable()->whereBetween('donation_date', [$from, $to])->exists();
    }

    /** The financial year the temple's records actually begin in. */
    private function earliestYear(): ?int
    {
        $dates = array_filter([
            $this->settings->current()->opening_balance_date?->toDateString(),
            Transaction::query()->countable()->min('transaction_date'),
            Donation::query()->countable()->min('donation_date'),
        ]);

        if ($dates === []) {
            return null;
        }

        return FinancialYear::containing(Carbon::parse(min($dates)))->year;
    }
}

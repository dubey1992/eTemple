<?php

declare(strict_types=1);

namespace App\Services\Reports;

use App\Models\Donation;
use App\Models\Enquiry;
use App\Models\User;
use App\Services\Accounting\TransparencyService;
use App\Services\Events\EventService;
use App\Support\FinancialYear;
use App\Support\Language;
use App\Support\LocalizedText;
use App\Support\Permission;
use Carbon\CarbonImmutable;
use Illuminate\Support\Carbon;

/**
 * The dashboard's at-a-glance figures.
 *
 * Phase 8 §9 left the admin dashboard as a landing page and said these would go
 * here; they do.
 *
 * **Every panel is gated by the module it reads**, so a Content Manager — who
 * holds no money key — opens a dashboard with no money on it, rather than one
 * with empty boxes where the money should be. An absent panel says "not yours";
 * an empty one says "the temple received nothing", and only one of those is
 * true.
 *
 * The money comes from {@see TransparencyService}, the same code behind the
 * public page and the income & expenditure statement, so the three cannot
 * disagree (PHASE_10_PLAN assumption N9).
 */
class OverviewService
{
    public function __construct(
        private readonly TransparencyService $transparency,
        private readonly EventService $events,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function forUser(User $user, Language $language): array
    {
        $year = FinancialYear::current();

        $overview = [
            'financial_year' => [
                'year' => $year->year,
                'label' => $year->label(),
            ],
        ];

        if ($user->can(Permission::ACCOUNTS_VIEW)) {
            $figures = $this->transparency->forYear($year, $language);

            $overview['money'] = [
                'donations_paise' => $figures['donations_paise'],
                'other_income_paise' => $figures['other_income_paise'],
                'total_income_paise' => $figures['total_income_paise'],
                'total_expense_paise' => $figures['total_expense_paise'],
                'closing_balance_paise' => $figures['closing_balance_paise'],
                'donation_count' => $figures['donation_count'],
            ];
        }

        // The trend needs the donation register rather than the accounts, so it
        // is offered to whoever may read that — a treasurer without
        // `accounts.view` still gets it.
        if ($user->can(Permission::DONATIONS_VIEW)) {
            $overview['donation_trend'] = $this->donationTrend();
        }

        if ($user->can(Permission::ENQUIRIES_MANAGE)) {
            $overview['enquiries'] = $this->enquiries();
        }

        if ($user->can(Permission::CONTENT_VIEW)) {
            $overview['upcoming_events'] = $this->upcomingEvents($language);
        }

        return $overview;
    }

    /**
     * Twelve months of confirmed donations, oldest first.
     *
     * Every month is present, including the ones with nothing in them: a chart
     * that omitted an empty month would compress the gap and show a steady
     * trickle where there was a festival and then silence.
     *
     * @return list<array{month: string, label: string, total_paise: int}>
     */
    private function donationTrend(): array
    {
        $start = CarbonImmutable::now()->startOfMonth()->subMonths(11);

        $totals = Donation::query()
            ->countable()
            ->whereDate('donation_date', '>=', $start->toDateString())
            ->get(['donation_date', 'amount_paise'])
            ->groupBy(fn (Donation $donation) => $donation->donation_date->format('Y-m'))
            ->map(fn ($group) => (int) $group->sum('amount_paise'));

        $months = [];
        for ($offset = 0; $offset < 12; $offset++) {
            $month = $start->addMonths($offset);
            $key = $month->format('Y-m');

            $months[] = [
                'month' => $key,
                'label' => $month->format('M'),
                'total_paise' => $totals[$key] ?? 0,
            ];
        }

        return $months;
    }

    /** @return array<string, int> */
    private function enquiries(): array
    {
        $count = fn (string $status) => (int) Enquiry::query()->where('status', $status)->count();

        return [
            'new' => $count(Enquiry::STATUS_NEW),
            'in_progress' => $count(Enquiry::STATUS_IN_PROGRESS),
            'open' => $count(Enquiry::STATUS_NEW) + $count(Enquiry::STATUS_IN_PROGRESS),
        ];
    }

    /**
     * The next few occurrences, expanded from the recurrence rules.
     *
     * @return list<array{date: string, time: string, title: string, is_cancelled: bool}>
     */
    private function upcomingEvents(Language $language): array
    {
        $from = CarbonImmutable::now();
        $to = $from->addDays(30);

        $upcoming = [];

        foreach ($this->events->adminList() as $event) {
            if (! $event->isPublished() && ! $event->isCancelled()) {
                continue;
            }

            foreach ($this->events->occurrences($event, $from, $to) as $occurrence) {
                $upcoming[] = [
                    'date' => $occurrence->startAt->toDateString(),
                    'time' => $occurrence->startAt->format('H:i'),
                    'title' => LocalizedText::resolve(
                        $event->title_hi,
                        $event->title_en,
                        $language,
                    )->value ?? '',
                    // A cancelled occurrence is shown and flagged, not dropped:
                    // "the aarti is off on Tuesday" is the thing somebody
                    // opening this needs to know.
                    'is_cancelled' => $event->isCancelled(),
                ];
            }
        }

        usort($upcoming, static fn (array $a, array $b) => [$a['date'], $a['time']] <=> [$b['date'], $b['time']]);

        return array_slice($upcoming, 0, 5);
    }

    /** For the tests and the live checks: today, as the service sees it. */
    public function now(): Carbon
    {
        return Carbon::now();
    }
}

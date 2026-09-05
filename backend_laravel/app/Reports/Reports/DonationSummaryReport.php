<?php

declare(strict_types=1);

namespace App\Reports\Reports;

use App\Models\Donation;
use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRequest;
use App\Services\Donations\DonationService;
use App\Support\DonationPurpose;
use App\Support\Language;
use App\Support\PaymentMode;
use App\Support\Permission;
use Illuminate\Database\Eloquent\Builder;

/**
 * What the donations came in for, and how.
 *
 * "How much came in for the festival this year" is the question
 * {@see DonationPurpose} was made a code catalogue for back in Phase 6 — it is
 * not answerable over a text box that has held "festival", "Festival" and
 * "जन्माष्टमी के लिए". This is that answer.
 *
 * **No donor appears here at all**, at any permission: the report is grouped,
 * and a group of one is still a group. There are therefore no personal columns
 * and no disclosure switch.
 */
class DonationSummaryReport implements Report
{
    public function __construct(private readonly DonationService $donations) {}

    public function key(): string
    {
        return 'donation-summary';
    }

    public function title(Language $language): string
    {
        return $language === Language::English ? 'Donation summary' : 'दान सारांश';
    }

    public function description(Language $language): string
    {
        return $language === Language::English
            ? 'Confirmed donations grouped by purpose, by payment mode and by month.'
            : 'सत्यापित दान — उद्देश्य, भुगतान माध्यम और माह के अनुसार।';
    }

    public function permission(): string
    {
        return Permission::DONATIONS_VIEW;
    }

    public function personalPermission(): ?string
    {
        return null;
    }

    public function columns(): array
    {
        return [
            ReportColumn::make('group', 'वर्ग', 'Grouping'),
            ReportColumn::make('label', 'मद', 'Heading'),
            ReportColumn::make('count', 'संख्या', 'Count', ReportColumn::NUMBER),
            ReportColumn::make('amount', 'राशि', 'Amount', ReportColumn::MONEY),
        ];
    }

    public function rows(ReportRequest $request): array
    {
        $english = $request->language === Language::English;

        return [
            ...$this->group(
                $request,
                'purpose',
                $english ? 'Purpose' : 'उद्देश्य',
                DonationPurpose::label(...),
            ),
            ...$this->group(
                $request,
                'payment_mode',
                $english ? 'Mode' : 'माध्यम',
                PaymentMode::label(...),
            ),
            ...$this->byMonth($request, $english ? 'Month' : 'माह'),
        ];
    }

    public function summary(ReportRequest $request): array
    {
        $totals = $this->donations->summary($this->filters($request));

        return [
            ['key' => 'total', 'label' => 'कुल प्राप्त · Total received', 'value' => $totals['total_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'confirmed', 'label' => 'सत्यापित दान · Confirmed donations', 'value' => $totals['confirmed_count'], 'type' => ReportColumn::NUMBER],
            ['key' => 'donors', 'label' => 'दानदाता · Donors', 'value' => $totals['donor_count'], 'type' => ReportColumn::NUMBER],
        ];
    }

    /**
     * One grouping, summed by the database.
     *
     * Confirmed only, like every total in this project: pending money is money
     * somebody wrote down, not money the treasurer has found.
     *
     * @param  callable(string): string  $label
     * @return list<array<string, mixed>>
     */
    private function group(
        ReportRequest $request,
        string $column,
        string $groupName,
        callable $label,
    ): array {
        $rows = $this->query($request)
            ->groupBy($column)
            ->selectRaw("{$column} as bucket, COUNT(*) as entries, SUM(amount_paise) as total")
            ->orderByDesc('total')
            ->get();

        return $rows->map(fn ($row) => [
            'group' => $groupName,
            'label' => $label((string) $row->bucket),
            'count' => (int) $row->entries,
            'amount' => (int) $row->total,
        ])->all();
    }

    /**
     * By month, in calendar order rather than by size.
     *
     * A trend read out of order is not a trend. `DATE_FORMAT` is MySQL and
     * MariaDB; SQLite — which the test suite uses for speed elsewhere — needs
     * `strftime`, so the expression is chosen from the connection rather than
     * assumed.
     *
     * @return list<array<string, mixed>>
     */
    private function byMonth(ReportRequest $request, string $groupName): array
    {
        $expression = $this->monthExpression();

        $rows = $this->query($request)
            ->groupBy('bucket')
            ->selectRaw("{$expression} as bucket, COUNT(*) as entries, SUM(amount_paise) as total")
            ->orderBy('bucket')
            ->get();

        return $rows->map(fn ($row) => [
            'group' => $groupName,
            'label' => (string) $row->bucket,
            'count' => (int) $row->entries,
            'amount' => (int) $row->total,
        ])->all();
    }

    private function monthExpression(): string
    {
        return Donation::query()->getConnection()->getDriverName() === 'sqlite'
            ? "strftime('%Y-%m', donation_date)"
            : "DATE_FORMAT(donation_date, '%Y-%m')";
    }

    /** @return Builder<Donation> */
    private function query(ReportRequest $request): Builder
    {
        $query = Donation::query()->countable();

        if ($request->fromDate() !== null) {
            $query->whereDate('donation_date', '>=', $request->fromDate());
        }

        if ($request->toDate() !== null) {
            $query->whereDate('donation_date', '<=', $request->toDate());
        }

        if ($request->filter('purpose') !== null) {
            $query->where('purpose', $request->filter('purpose'));
        }

        if ($request->filter('mode') !== null) {
            $query->where('payment_mode', $request->filter('mode'));
        }

        return $query;
    }

    /** @return array<string, mixed> */
    private function filters(ReportRequest $request): array
    {
        return array_filter([
            'from' => $request->fromDate(),
            'to' => $request->toDate(),
            'purpose' => $request->filter('purpose'),
            'mode' => $request->filter('mode'),
        ], static fn ($value) => $value !== null);
    }
}

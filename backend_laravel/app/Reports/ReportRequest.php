<?php

declare(strict_types=1);

namespace App\Reports;

use App\Support\FinancialYear;
use App\Support\Language;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * The filters a report was asked for.
 *
 * **Parsed once, here, from the query string** — and the screen and the export
 * both build one from the same request shape. That is what makes "the export
 * applies exactly the on-screen filters" a fact about the code rather than a
 * promise: there is no second parser to drift, and the client never sends the
 * rows it happens to be showing (PHASE_10_PLAN assumption N1).
 */
final class ReportRequest
{
    private function __construct(
        public readonly Language $language,
        public readonly ?Carbon $from,
        public readonly ?Carbon $to,
        /** @var array<string, string> */
        public readonly array $filters,
        public readonly bool $includePersonal,
        public readonly int $page,
        public readonly int $perPage,
    ) {}

    /** Filters any report may be given, beyond its own. */
    private const COMMON = ['status', 'type', 'mode', 'purpose', 'category', 'q'];

    public static function fromRequest(Request $request): self
    {
        $filters = [];
        foreach (self::COMMON as $key) {
            $value = $request->query($key);
            if (is_string($value) && trim($value) !== '') {
                $filters[$key] = trim($value);
            }
        }

        // `category_id` is an integer filter and travels separately so a blank
        // one is never read as the id zero.
        $categoryId = $request->query('category_id');
        if (is_numeric($categoryId) && (int) $categoryId > 0) {
            $filters['category_id'] = (string) (int) $categoryId;
        }

        [$from, $to] = self::window($request);

        return new self(
            language: Language::fromRequest($request->query('lang')),
            from: $from,
            to: $to,
            filters: $filters,
            // Default false, and it stays false unless somebody asked. The
            // permission is checked separately, by the runner (assumption N2).
            includePersonal: $request->boolean('include_personal'),
            page: max(1, (int) $request->query('page', 1)),
            perPage: max(1, min((int) $request->query('per_page', 50), 200)),
        );
    }

    /**
     * The period.
     *
     * `year` names an Indian financial year and is the ordinary way to ask;
     * `from`/`to` are for a treasurer who wants a month or a festival week.
     * When neither is given the report covers the current financial year rather
     * than all of history, because an unbounded first click on a report is a
     * scan of every row the temple has ever recorded.
     *
     * @return array{0: ?Carbon, 1: ?Carbon}
     */
    private static function window(Request $request): array
    {
        $from = $request->query('from');
        $to = $request->query('to');

        if (is_string($from) && $from !== '' || is_string($to) && $to !== '') {
            return [
                is_string($from) && $from !== '' ? Carbon::parse($from)->startOfDay() : null,
                is_string($to) && $to !== '' ? Carbon::parse($to)->endOfDay() : null,
            ];
        }

        $year = $request->query('year');
        $financialYear = is_numeric($year) && FinancialYear::isReportable((int) $year)
            ? FinancialYear::of((int) $year)
            : FinancialYear::current();

        return [$financialYear->startsOn(), $financialYear->endsOn()];
    }

    public function filter(string $key): ?string
    {
        return $this->filters[$key] ?? null;
    }

    /** The window as the module services want it: plain `Y-m-d` strings. */
    public function fromDate(): ?string
    {
        return $this->from?->toDateString();
    }

    public function toDate(): ?string
    {
        return $this->to?->toDateString();
    }

    /**
     * The same request without paging, for an export.
     *
     * The *only* difference between what the screen shows and what the file
     * contains: same key, same filters, same parser, same rows.
     */
    public function unpaged(int $limit): self
    {
        return new self(
            language: $this->language,
            from: $this->from,
            to: $this->to,
            filters: $this->filters,
            includePersonal: $this->includePersonal,
            page: 1,
            perPage: $limit,
        );
    }

    /** The same request with personal columns refused. */
    public function withoutPersonal(): self
    {
        return new self(
            language: $this->language,
            from: $this->from,
            to: $this->to,
            filters: $this->filters,
            includePersonal: false,
            page: $this->page,
            perPage: $this->perPage,
        );
    }

    /**
     * The filters in words, for the header block every export carries.
     *
     * A printed sheet with no statement of what it was filtered to is a sheet
     * somebody will misread (assumption N7).
     *
     * @return list<string>
     */
    public function describe(): array
    {
        $parts = [];

        if ($this->from !== null || $this->to !== null) {
            $parts[] = sprintf(
                '%s – %s',
                $this->from?->toDateString() ?? '…',
                $this->to?->toDateString() ?? '…',
            );
        }

        foreach ($this->filters as $key => $value) {
            $parts[] = "{$key}: {$value}";
        }

        return $parts;
    }
}

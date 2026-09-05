<?php

declare(strict_types=1);

namespace App\Reports;

use App\Support\Language;

/**
 * A report that has been run: its columns, its rows and its figures, together
 * with everything the header block of an export needs.
 *
 * One object serves the screen and all three formats, which is what keeps them
 * from diverging.
 */
final class ReportResult
{
    /**
     * @param  list<ReportColumn>  $columns
     * @param  list<array<string, mixed>>  $rows
     * @param  list<array{key: string, label: string, value: mixed, type: string}>  $summary
     * @param  list<string>  $filters
     */
    public function __construct(
        public readonly Report $report,
        public readonly Language $language,
        public readonly array $columns,
        public readonly array $rows,
        public readonly array $summary,
        public readonly array $filters,
        public readonly bool $includesPersonal,
        public readonly int $total,
        public readonly int $page,
        public readonly int $perPage,
        /**
         * True when the export cap stopped the rows short. The response says
         * so rather than handing over a file that is quietly missing its last
         * four hundred rows (PHASE_10_PLAN assumption N8).
         */
        public readonly bool $truncated = false,
    ) {}

    public function title(): string
    {
        return $this->report->title($this->language);
    }

    public function lastPage(): int
    {
        return max(1, (int) ceil($this->total / max(1, $this->perPage)));
    }

    /** @return list<string> */
    public function columnKeys(): array
    {
        return array_map(static fn (ReportColumn $column) => $column->key, $this->columns);
    }
}

<?php

declare(strict_types=1);

namespace App\Reports;

use App\Exceptions\ReportGuardException;
use App\Models\User;

/**
 * Runs a report for a caller.
 *
 * **The single path.** The screen calls {@see run()} and an export calls
 * {@see runForExport()}; the second is the first with paging removed and a cap
 * applied. There is no other way to produce a report's rows, which is what makes
 * the export and the screen agree by construction rather than by care
 * (PHASE_10_PLAN assumption N1).
 *
 * It is also the one place the disclosure control lives (assumption N2):
 * personal columns are dropped unless the caller both holds the permission and
 * asked for them, and asking without the permission is refused rather than
 * quietly answered with a narrower file.
 */
class ReportRunner
{
    /**
     * The ceiling on an export. Beyond this the result is marked truncated and
     * the caller is told to narrow the period — a file quietly missing its last
     * rows is worse than one that refused (assumption N8).
     */
    public const EXPORT_LIMIT = 10_000;

    public function __construct(private readonly ReportRegistry $registry) {}

    public function run(Report $report, ReportRequest $request, User $actor): ReportResult
    {
        $request = $this->resolveDisclosure($report, $request, $actor);

        $columns = $this->visibleColumns($report, $request);
        $rows = $report->rows($request);

        return new ReportResult(
            report: $report,
            language: $request->language,
            columns: $columns,
            rows: $this->project($rows, $columns),
            summary: $report->summary($request),
            filters: $request->describe(),
            includesPersonal: $request->includePersonal,
            total: $this->total($report, $request, count($rows)),
            page: $request->page,
            perPage: $request->perPage,
        );
    }

    public function runForExport(Report $report, ReportRequest $request, User $actor): ReportResult
    {
        // One more than the cap, so a result that reaches it can be told apart
        // from one that merely filled it exactly.
        $unpaged = $request->unpaged(self::EXPORT_LIMIT + 1);
        $result = $this->run($report, $unpaged, $actor);

        if (count($result->rows) <= self::EXPORT_LIMIT) {
            return $result;
        }

        return new ReportResult(
            report: $result->report,
            language: $result->language,
            columns: $result->columns,
            rows: array_slice($result->rows, 0, self::EXPORT_LIMIT),
            summary: $result->summary,
            filters: $result->filters,
            includesPersonal: $result->includesPersonal,
            total: $result->total,
            page: 1,
            perPage: self::EXPORT_LIMIT,
            truncated: true,
        );
    }

    /**
     * Decides whether this run carries personal columns.
     *
     * Three outcomes, and the middle one is the point:
     *
     *  * did not ask → no personal columns, whatever the permission;
     *  * asked, and may → personal columns;
     *  * **asked, and may not → refused**, not silently narrowed. Dropping
     *    columns somebody explicitly asked for is how a treasurer concludes the
     *    export is broken and starts copying the register out by hand.
     */
    private function resolveDisclosure(
        Report $report,
        ReportRequest $request,
        User $actor,
    ): ReportRequest {
        if (! $request->includePersonal) {
            return $request->withoutPersonal();
        }

        if ($report->personalPermission() === null) {
            // Nothing to disclose; the flag is meaningless rather than wrong.
            return $request->withoutPersonal();
        }

        if (! $this->registry->maySeePersonal($actor, $report)) {
            throw ReportGuardException::personalColumnsRefused();
        }

        return $request;
    }

    /** @return list<ReportColumn> */
    private function visibleColumns(Report $report, ReportRequest $request): array
    {
        return array_values(array_filter(
            $report->columns(),
            static fn (ReportColumn $column) => $request->includePersonal || ! $column->personal,
        ));
    }

    /**
     * Keeps only the visible columns' values.
     *
     * A personal column is **absent from the row**, not blanked: a masked column
     * is still a column somebody can widen, and an empty string in a file is a
     * fact somebody will read as "we hold nothing about this person".
     *
     * @param  list<array<string, mixed>>  $rows
     * @param  list<ReportColumn>  $columns
     * @return list<array<string, mixed>>
     */
    private function project(array $rows, array $columns): array
    {
        $keys = array_map(static fn (ReportColumn $column) => $column->key, $columns);

        return array_map(
            static fn (array $row) => array_intersect_key($row, array_flip($keys)),
            $rows,
        );
    }

    /**
     * How many rows the whole filter matches.
     *
     * A report that paginates says so through its summary; one that does not is
     * as long as it is. Either way this is never "the number of rows on this
     * page" dressed up as a total.
     */
    private function total(Report $report, ReportRequest $request, int $returned): int
    {
        foreach ($report->summary($request) as $figure) {
            if ($figure['key'] === 'row_count') {
                return (int) $figure['value'];
            }
        }

        return $returned;
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Exceptions\ReportGuardException;
use App\Http\Controllers\Controller;
use App\Reports\Export\ExporterRegistry;
use App\Reports\Export\ExportHeader;
use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRegistry;
use App\Reports\ReportRequest;
use App\Reports\ReportResult;
use App\Reports\ReportRunner;
use App\Support\ApiErrorCode;
use App\Support\ApiResponse;
use App\Support\Language;
use App\Support\Money;
use App\Support\Permission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * The standard reports, and the files made from them.
 *
 * Three endpoints and one rule: {@see show()} and {@see export()} build the
 * **same** `ReportRequest` from the **same** query string and hand it to the
 * **same** runner. The client never posts rows to be exported, so "the export
 * applies exactly the on-screen filters" is a property of the code
 * (PHASE_10_PLAN assumption N1).
 *
 * Nothing here writes. Every route is a `GET`.
 */
class ReportController extends Controller
{
    public function __construct(
        private readonly ReportRegistry $registry,
        private readonly ReportRunner $runner,
        private readonly ExporterRegistry $exporters,
        private readonly ExportHeader $header,
    ) {}

    /**
     * GET /api/admin/reports
     *
     * Only what this account may actually run — the console is never offered a
     * door that will not open. A courtesy, never the access control: every
     * other method checks again.
     */
    public function index(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));
        $user = $request->user();

        return ApiResponse::success([
            'reports' => array_map(
                fn (Report $report) => [
                    'key' => $report->key(),
                    'title' => $report->title($language),
                    'description' => $report->description($language),
                    'has_personal_columns' => $report->personalPermission() !== null,
                    'may_see_personal' => $this->registry->maySeePersonal($user, $report),
                ],
                $this->registry->availableTo($user),
            ),
            'may_export' => $user->can(Permission::REPORTS_EXPORT),
            'formats' => $this->exporters->formats(),
            'export_limit' => ReportRunner::EXPORT_LIMIT,
        ]);
    }

    /** GET /api/admin/reports/{key} */
    public function show(Request $request, string $key): JsonResponse
    {
        $report = $this->report($request, $key);
        $result = $this->runner->run($report, ReportRequest::fromRequest($request), $request->user());

        return ApiResponse::success($this->serialize($result), [
            'current_page' => $result->page,
            'per_page' => $result->perPage,
            'total' => $result->total,
            'last_page' => $result->lastPage(),
            'has_more' => $result->page < $result->lastPage(),
        ]);
    }

    /**
     * GET /api/admin/reports/{key}/export?format=
     *
     * Downloading is its own permission: a Viewer may read a report on screen
     * and not take a copy away.
     */
    public function export(Request $request, string $key): Response
    {
        if (! $request->user()->can(Permission::REPORTS_EXPORT)) {
            return ApiResponse::error(
                ApiErrorCode::FORBIDDEN,
                'This account may read reports but not download them.',
                403,
            );
        }

        $report = $this->report($request, $key);
        $exporter = $this->exporters->for((string) $request->query('format', 'csv'));

        $result = $this->runner->runForExport(
            $report,
            ReportRequest::fromRequest($request),
            $request->user(),
        );

        $body = $exporter->render($result, $request->user());
        $filename = $this->header->filename($result, $exporter->extension());

        return response($body, 200, [
            'Content-Type' => $exporter->contentType(),
            // The print format opens in a tab to be printed; the other two are
            // files. `inline` on an HTML document served from the API origin is
            // safe here because every value in it went through one escaper.
            'Content-Disposition' => sprintf(
                '%s; filename="%s"',
                $exporter->format() === 'pdf' ? 'inline' : 'attachment',
                $filename,
            ),
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ]);
    }

    private function report(Request $request, string $key): Report
    {
        $report = $this->registry->find($key);

        if ($report === null) {
            return throw new NotFoundHttpException(
                'There is no report by that name.',
            );
        }

        if (! $this->registry->mayRun($request->user(), $report)) {
            throw ReportGuardException::reportRefused();
        }

        return $report;
    }

    /**
     * The result as JSON.
     *
     * Money travels as **both** the integer paise and the formatted string —
     * the paise are the authority and the string is what a person reads, and
     * only one side of the wire ever divides by a hundred.
     *
     * @return array<string, mixed>
     */
    private function serialize(ReportResult $result): array
    {
        return [
            'key' => $result->report->key(),
            'title' => $result->title(),
            'description' => $result->report->description($result->language),
            'filters' => $result->filters,
            'includes_personal' => $result->includesPersonal,
            'has_personal_columns' => $result->report->personalPermission() !== null,
            'columns' => array_map(
                fn (ReportColumn $column) => $column->toArray($result->language),
                $result->columns,
            ),
            'rows' => array_map(
                fn (array $row) => $this->serializeRow($row, $result->columns),
                $result->rows,
            ),
            'summary' => array_map(
                fn (array $figure) => [
                    'key' => $figure['key'],
                    'label' => $figure['label'],
                    'type' => $figure['type'],
                    'value' => $figure['value'],
                    'display' => $figure['type'] === ReportColumn::MONEY && $figure['value'] !== null
                        ? Money::format((int) $figure['value'])
                        : (string) ($figure['value'] ?? '—'),
                ],
                $result->summary,
            ),
        ];
    }

    /**
     * @param  array<string, mixed>  $row
     * @param  list<ReportColumn>  $columns
     * @return array<string, mixed>
     */
    private function serializeRow(array $row, array $columns): array
    {
        $out = [];

        foreach ($columns as $column) {
            $value = $row[$column->key] ?? null;

            $out[$column->key] = $column->type === ReportColumn::MONEY && $value !== null
                ? ['paise' => (int) $value, 'display' => Money::format((int) $value)]
                : $value;
        }

        return $out;
    }
}

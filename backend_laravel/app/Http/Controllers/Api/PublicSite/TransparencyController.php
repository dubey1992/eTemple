<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Services\Accounting\TransparencyService;
use App\Support\ApiResponse;
use App\Support\FinancialYear;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * What the temple did with the money.
 *
 * One endpoint, aggregates only. It carries **no individual transaction and no
 * person's name** at any status: the public figures are category totals for a
 * financial year, which answer the question a villager actually asks and
 * identify nobody (PHASE_9_PLAN assumptions N6 and N9).
 *
 * When the committee has not published its books, this reports that plainly —
 * `is_published: false` with the temple's own words — rather than serving a
 * page of zeros. Zeros would read as "the temple received nothing", which is a
 * false statement about somebody's finances rather than a missing feature.
 */
class TransparencyController extends Controller
{
    public function __construct(private readonly TransparencyService $transparency) {}

    /** GET /api/public/transparency?year=&lang= */
    public function show(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));
        $preamble = $this->transparency->preamble($language);

        if (! $this->transparency->isPublished()) {
            return ApiResponse::success([
                'is_published' => false,
                'intro' => $preamble['intro']->toArray(),
                'note' => $preamble['note']->toArray(),
            ]);
        }

        $years = $this->transparency->publishedYears();
        $requested = $this->resolveYear($request->query('year'), $years);

        return ApiResponse::success([
            'is_published' => true,
            'intro' => $preamble['intro']->toArray(),
            'note' => $preamble['note']->toArray(),
            'opening_balance_date' => $preamble['opening_balance_date'],

            'available_years' => array_map(
                static fn (FinancialYear $year) => [
                    'year' => $year->year,
                    'label' => $year->label(),
                ],
                $years,
            ),

            'summary' => $this->transparency->forYear($requested, $language),
        ]);
    }

    /**
     * The year to report on.
     *
     * A year that is out of range, unparseable or simply has no records is
     * answered with the newest year that does, rather than with an error: a
     * stale bookmark to `?year=2019` should show the reader this year's
     * accounts, not a fault page.
     *
     * @param  list<FinancialYear>  $available
     */
    private function resolveYear(mixed $requested, array $available): FinancialYear
    {
        $year = is_numeric($requested) ? (int) $requested : null;

        if ($year !== null && FinancialYear::isReportable($year)) {
            foreach ($available as $candidate) {
                if ($candidate->year === $year) {
                    return $candidate;
                }
            }
        }

        return $available[0] ?? FinancialYear::current();
    }
}

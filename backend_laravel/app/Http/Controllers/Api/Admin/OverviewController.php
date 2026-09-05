<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\Reports\OverviewService;
use App\Support\ApiResponse;
use App\Support\Language;
use App\Support\Money;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The dashboard's at-a-glance figures.
 *
 * Behind `reports.view`, and then each panel is gated again by the module it
 * reads — so what comes back differs by account, and a panel that is absent is
 * absent rather than empty.
 */
class OverviewController extends Controller
{
    public function __construct(private readonly OverviewService $overview) {}

    /** GET /api/admin/overview */
    public function show(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));
        $data = $this->overview->forUser($request->user(), $language);

        return ApiResponse::success($this->withDisplayAmounts($data));
    }

    /**
     * Adds the read-aloud form of every money figure beside its paise.
     *
     * The paise stay the authority; the string is what the panel prints. Doing
     * it here rather than on the client keeps the one division by a hundred on
     * the server, as everywhere else in this project.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function withDisplayAmounts(array $data): array
    {
        if (isset($data['money']) && is_array($data['money'])) {
            $money = $data['money'];

            foreach ($money as $key => $value) {
                if (str_ends_with($key, '_paise')) {
                    $money[substr($key, 0, -6).'_display'] = Money::format((int) $value);
                }
            }

            $data['money'] = $money;
        }

        if (isset($data['donation_trend']) && is_array($data['donation_trend'])) {
            $data['donation_trend'] = array_map(
                static fn (array $month) => $month + [
                    'display' => Money::format((int) $month['total_paise']),
                ],
                $data['donation_trend'],
            );
        }

        return $data;
    }
}

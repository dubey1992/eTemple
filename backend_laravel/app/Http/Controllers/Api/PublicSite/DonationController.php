<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Donations\PublicDonationSettingsResource;
use App\Services\Donations\DonationSettingService;
use App\Support\ApiResponse;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The public half of Phase 6, and all of it: where to send money.
 *
 * There is no donation list here, no count, no total and no donor. That is not
 * an omission to be filled in later — donor detail reaches no public endpoint
 * at any status, in any aggregate (PHASE_6_PLAN assumption N5). Aggregate
 * transparency is Phase 9's requirement, with its own consent question.
 */
class DonationController extends Controller
{
    public function __construct(private readonly DonationSettingService $settings) {}

    /** GET /api/public/donation-settings?lang= */
    public function settings(Request $request): JsonResponse
    {
        $settings = $this->settings->publiclyVisible();
        $language = Language::fromRequest($request->query('lang'));

        // Unconfigured is an empty state, not an error: a brand-new site has no
        // bank details yet and must not look broken.
        return ApiResponse::success(
            $settings === null
                ? null
                : new PublicDonationSettingsResource($settings, $language),
        );
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Content\PublicSiteSettingsResource;
use App\Services\Content\SiteSettingService;
use App\Support\ApiResponse;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SiteSettingsController extends Controller
{
    public function __construct(private readonly SiteSettingService $settings) {}

    /** GET /api/public/site-settings?lang=hi|en */
    public function show(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));

        return ApiResponse::success(new PublicSiteSettingsResource(
            $this->settings->current(),
            $language,
            $this->settings->visibleNavigation(),
        ));
    }
}

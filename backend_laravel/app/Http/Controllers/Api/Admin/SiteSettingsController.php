<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Content\UpdateSiteSettingsRequest;
use App\Http\Resources\Content\AdminSiteSettingsResource;
use App\Models\User;
use App\Services\Content\SiteSettingService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class SiteSettingsController extends Controller
{
    public function __construct(private readonly SiteSettingService $settings) {}

    /** GET /api/admin/site-settings */
    public function show(): JsonResponse
    {
        return ApiResponse::success(new AdminSiteSettingsResource(
            $this->settings->current(),
            $this->settings->allNavigation(),
        ));
    }

    /** PUT /api/admin/site-settings */
    public function update(UpdateSiteSettingsRequest $request): JsonResponse
    {
        /** @var User $editor */
        $editor = $request->user();

        $data = $request->validated();
        $navigation = $data['navigation'] ?? null;
        unset($data['navigation']);

        $settings = $this->settings->update($data, $navigation, $editor);

        return ApiResponse::success(new AdminSiteSettingsResource(
            $settings,
            $this->settings->allNavigation(),
        ));
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Donations\UpdateDonationSettingsRequest;
use App\Http\Resources\Donations\AdminDonationSettingsResource;
use App\Models\User;
use App\Services\Donations\DonationSettingService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class DonationSettingsController extends Controller
{
    public function __construct(private readonly DonationSettingService $settings) {}

    /** GET /api/admin/donation-settings — requires `donations.view`. */
    public function show(): JsonResponse
    {
        return ApiResponse::success(
            new AdminDonationSettingsResource($this->settings->current()),
        );
    }

    /**
     * PUT /api/admin/donation-settings — requires `donations.manage`.
     *
     * The money permission, not the content one: changing the published UPI id
     * is the single most valuable attack on this site.
     */
    public function update(UpdateDonationSettingsRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        return ApiResponse::success(
            new AdminDonationSettingsResource(
                $this->settings->update($request->validated(), $actor),
            ),
        );
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Accounting\UpdateAccountingSettingsRequest;
use App\Http\Resources\Accounting\AdminAccountingSettingsResource;
use App\Services\Accounting\AccountingSettingService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Whether the temple's books are public, and where they start.
 *
 * Reading needs `accounts.view`; changing either answer needs
 * `accounts.manage`. Publishing the accounts is not the Content Manager's
 * decision any more than the bank details were in Phase 6.
 */
class AccountingSettingsController extends Controller
{
    public function __construct(private readonly AccountingSettingService $settings) {}

    /** GET /api/admin/accounting-settings */
    public function show(): JsonResponse
    {
        return ApiResponse::success(new AdminAccountingSettingsResource(
            $this->settings->current()->load('updatedBy:id,first_name,last_name'),
        ));
    }

    /** PUT /api/admin/accounting-settings */
    public function update(UpdateAccountingSettingsRequest $request): JsonResponse
    {
        $settings = $this->settings->update($request->validated(), $request->user());

        return ApiResponse::success(new AdminAccountingSettingsResource(
            $settings->load('updatedBy:id,first_name,last_name'),
        ));
    }
}

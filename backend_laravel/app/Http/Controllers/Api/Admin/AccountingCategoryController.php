<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Accounting\StoreAccountingCategoryRequest;
use App\Http\Resources\Accounting\AccountingCategoryResource;
use App\Models\AccountingCategory;
use App\Services\Accounting\AccountingCategoryService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The headings the temple's books are filed under.
 *
 * `destroy` exists here and nowhere else in Phases 6–9, and it is narrow: a
 * category that has never been used may be removed, because it is a mistyped
 * heading rather than a piece of history. One that has been used is refused
 * with a message naming the count and offering deactivation instead.
 */
class AccountingCategoryController extends Controller
{
    public function __construct(private readonly AccountingCategoryService $categories) {}

    /** GET /api/admin/accounting-categories */
    public function index(Request $request): JsonResponse
    {
        $categories = $this->categories
            ->list([
                'type' => $request->query('type'),
                'active_only' => $request->boolean('active_only'),
            ])
            ->loadCount('transactions');

        return ApiResponse::success(AccountingCategoryResource::collection($categories));
    }

    /** POST /api/admin/accounting-categories */
    public function store(StoreAccountingCategoryRequest $request): JsonResponse
    {
        $category = $this->categories->create($request->validated(), $request->user());

        return ApiResponse::success(
            new AccountingCategoryResource($category->loadCount('transactions')),
            status: 201,
        );
    }

    /** PUT /api/admin/accounting-categories/{category} */
    public function update(
        StoreAccountingCategoryRequest $request,
        AccountingCategory $category,
    ): JsonResponse {
        $updated = $this->categories->update($category, $request->validated(), $request->user());

        return ApiResponse::success(
            new AccountingCategoryResource($updated->loadCount('transactions')),
        );
    }

    /** DELETE /api/admin/accounting-categories/{category} */
    public function destroy(AccountingCategory $category): JsonResponse
    {
        $this->categories->delete($category);

        return ApiResponse::noContent();
    }
}

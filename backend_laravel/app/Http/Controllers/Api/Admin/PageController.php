<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Content\UpdatePageRequest;
use App\Http\Resources\Content\AdminPageResource;
use App\Models\Page;
use App\Models\User;
use App\Services\Content\PageService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PageController extends Controller
{
    public function __construct(private readonly PageService $pages) {}

    /** GET /api/admin/pages */
    public function index(Request $request): JsonResponse
    {
        $paginator = $this->pages->paginateForAdmin((int) $request->integer('per_page', 25));

        return ApiResponse::paginated(
            $paginator,
            AdminPageResource::collection($paginator->getCollection())->resolve($request),
        );
    }

    /** GET /api/admin/pages/{page} */
    public function show(Page $page): JsonResponse
    {
        return ApiResponse::success(new AdminPageResource($page));
    }

    /** PUT /api/admin/pages/{page} */
    public function update(UpdatePageRequest $request, Page $page): JsonResponse
    {
        /** @var User $editor */
        $editor = $request->user();

        $updated = $this->pages->update($page, $request->validated(), $editor);

        return ApiResponse::success(new AdminPageResource($updated));
    }
}

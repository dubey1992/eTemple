<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Content\PublicPageResource;
use App\Services\Content\PageService;
use App\Support\ApiResponse;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PageController extends Controller
{
    public function __construct(private readonly PageService $pages) {}

    /**
     * GET /api/public/pages/{slug}?lang=hi|en
     *
     * Unknown and draft slugs both raise ModelNotFoundException, which the
     * central renderer turns into a 404 NOT_FOUND — a draft is indistinguishable
     * from a page that does not exist.
     */
    public function show(Request $request, string $slug): JsonResponse
    {
        $page = $this->pages->publishedBySlug($slug);
        $language = Language::fromRequest($request->query('lang'));

        return ApiResponse::success(new PublicPageResource($page, $language));
    }
}

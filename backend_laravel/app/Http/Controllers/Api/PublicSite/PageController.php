<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Content\PublicPageResource;
use App\Http\Resources\Content\PublicPageSummaryResource;
use App\Services\Content\PageService;
use App\Support\ApiResponse;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PageController extends Controller
{
    public function __construct(private readonly PageService $pages) {}

    /**
     * GET /api/public/pages?lang=hi|en
     *
     * Which pages exist, so a client does not have to guess. The home page's
     * About section used to request the `about` slug unconditionally and take a
     * 404 on every visit of a site that has not written one.
     *
     * Drafts are absent: listing must not reveal a page that fetching would
     * refuse.
     */
    public function index(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));

        return ApiResponse::success(
            $this->pages->publishedIndex()
                ->map(fn ($page) => new PublicPageSummaryResource($page, $language))
                ->all(),
        );
    }

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

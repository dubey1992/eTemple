<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Announcements\PublicAnnouncementResource;
use App\Models\Announcement;
use App\Services\Announcements\AnnouncementService;
use App\Support\ApiResponse;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The temple's current notices.
 *
 * One endpoint, and it hands out only what is published **and inside its
 * window**. The filter is a `where` clause, not a serializer decision: a notice
 * scheduled for next Tuesday is not reachable today by any request, which is
 * what makes "scheduled" a fact rather than a display convention
 * (PHASE_8_PLAN assumption N2).
 */
class AnnouncementController extends Controller
{
    public function __construct(private readonly AnnouncementService $announcements) {}

    /** GET /api/public/announcements?lang= */
    public function index(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));

        // A small, fixed number. The banner shows one; the handful behind it
        // exist so a client can offer "see all notices" without a second call,
        // and an unbounded list on a public endpoint is a denial-of-service
        // against our own API.
        $announcements = $this->announcements->currentlyShowing();

        return ApiResponse::success(
            $announcements
                ->map(fn (Announcement $announcement) => new PublicAnnouncementResource($announcement, $language))
                ->all(),
        );
    }
}

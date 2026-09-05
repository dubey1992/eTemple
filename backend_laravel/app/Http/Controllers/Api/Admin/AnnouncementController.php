<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Announcements\SendAnnouncementRequest;
use App\Http\Requests\Announcements\StoreAnnouncementRequest;
use App\Http\Resources\Announcements\AdminAnnouncementResource;
use App\Models\Announcement;
use App\Services\Announcements\AnnouncementService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Writing, publishing and sending the temple's notices.
 *
 * Four verbs on four endpoints rather than a `status` field somebody can PUT:
 * saving, publishing, archiving and sending have different consequences, and
 * one of them cannot be undone. Giving the irreversible one its own URL is what
 * makes "no sends without explicit admin action" true of the API and not just
 * of the screen (PHASE_8_PLAN assumption N1).
 *
 * There is no destroy method. `archive` takes a notice off the website and
 * keeps the row, including its record of what was sent.
 */
class AnnouncementController extends Controller
{
    public function __construct(private readonly AnnouncementService $announcements) {}

    /** GET /api/admin/announcements */
    public function index(Request $request): JsonResponse
    {
        $announcements = $this->announcements->list([
            'status' => $request->query('status'),
            'priority' => $request->query('priority'),
            'search' => $request->query('search'),
            'include_archived' => $request->boolean('include_archived'),
            'per_page' => $request->query('per_page'),
        ]);

        return ApiResponse::paginated(
            $announcements,
            AdminAnnouncementResource::collection($announcements->getCollection()),
        );
    }

    /** GET /api/admin/announcements/{announcement} */
    public function show(Announcement $announcement): JsonResponse
    {
        $announcement->load(['author:id,first_name,last_name', 'sender:id,first_name,last_name']);

        return ApiResponse::success(new AdminAnnouncementResource($announcement));
    }

    /** POST /api/admin/announcements */
    public function store(StoreAnnouncementRequest $request): JsonResponse
    {
        $announcement = $this->announcements->create($request->validated(), $request->user());

        return ApiResponse::success(new AdminAnnouncementResource($announcement), status: 201);
    }

    /** PUT /api/admin/announcements/{announcement} */
    public function update(StoreAnnouncementRequest $request, Announcement $announcement): JsonResponse
    {
        $updated = $this->announcements->update($announcement, $request->validated(), $request->user());

        return ApiResponse::success(new AdminAnnouncementResource($updated));
    }

    /** POST /api/admin/announcements/{announcement}/publish */
    public function publish(Request $request, Announcement $announcement): JsonResponse
    {
        return ApiResponse::success(new AdminAnnouncementResource(
            $this->announcements->publish($announcement, $request->user()),
        ));
    }

    /** POST /api/admin/announcements/{announcement}/archive */
    public function archive(Request $request, Announcement $announcement): JsonResponse
    {
        return ApiResponse::success(new AdminAnnouncementResource(
            $this->announcements->archive($announcement, $request->user()),
        ));
    }

    /** POST /api/admin/announcements/{announcement}/send */
    public function send(SendAnnouncementRequest $request, Announcement $announcement): JsonResponse
    {
        return ApiResponse::success(new AdminAnnouncementResource(
            $this->announcements->send(
                $announcement,
                $request->validated('channels'),
                $request->user(),
            ),
        ));
    }
}

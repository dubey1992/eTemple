<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Events\StoreEventRequest;
use App\Http\Resources\Events\AdminEventResource;
use App\Models\Event;
use App\Models\User;
use App\Services\Events\EventService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function __construct(private readonly EventService $events) {}

    /**
     * GET /api/admin/events?status=
     *
     * Every event including drafts, cancelled entries and past ones — the
     * calendar is a record as well as a schedule.
     */
    public function index(Request $request): JsonResponse
    {
        $status = $request->query('status');
        $status = is_string($status) && in_array($status, Event::statuses(), true)
            ? $status
            : null;

        $events = $this->events->adminList($status)
            ->map(fn (Event $event) => (new AdminEventResource($event))->resolve($request))
            ->all();

        return ApiResponse::success($events);
    }

    /** GET /api/admin/events/{event} */
    public function show(Event $event): JsonResponse
    {
        return ApiResponse::success(new AdminEventResource($event));
    }

    /** POST /api/admin/events */
    public function store(StoreEventRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $event = $this->events->create($request->validated(), $actor);

        return ApiResponse::success(new AdminEventResource($event), null, 201);
    }

    /** PUT /api/admin/events/{event} */
    public function update(StoreEventRequest $request, Event $event): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $updated = $this->events->update($event, $request->validated(), $actor);

        return ApiResponse::success(new AdminEventResource($updated));
    }

    /**
     * DELETE /api/admin/events/{event}
     *
     * Cancelling keeps the record and tells devotees the event is off; deleting
     * removes it entirely and is for entries created by mistake.
     */
    public function destroy(Event $event): JsonResponse
    {
        $this->events->delete($event);

        return ApiResponse::noContent();
    }
}

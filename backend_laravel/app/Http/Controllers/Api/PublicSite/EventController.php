<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Events\PublicEventOccurrenceResource;
use App\Services\Events\EventService;
use App\Support\ApiResponse;
use App\Support\EventOccurrence;
use App\Support\EventType;
use App\Support\Language;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function __construct(private readonly EventService $events) {}

    /**
     * GET /api/public/events?lang=&view=upcoming|past&days=&featured=1&type=
     *
     * Returns dated occurrences, not stored rows: the daily aarti is one record
     * and many occurrences. Drafts are excluded in the query; cancelled events
     * are included and flagged.
     */
    public function index(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));
        $type = $request->query('type');

        $occurrences = $this->events->publicOccurrences([
            'view' => $request->query('view') === 'past' ? 'past' : 'upcoming',
            'days' => (int) $request->integer('days', EventService::DEFAULT_WINDOW_DAYS),
            'featured' => $request->boolean('featured'),
            ...(is_string($type) && EventType::exists($type) ? ['type' => $type] : []),
        ]);

        return ApiResponse::success(
            array_map(
                fn (EventOccurrence $o) => (new PublicEventOccurrenceResource($o, $language))
                    ->resolve($request),
                $occurrences,
            ),
            [
                'view' => $request->query('view') === 'past' ? 'past' : 'upcoming',
                'timezone' => config('app.timezone'),
                'count' => count($occurrences),
            ],
        );
    }

    /**
     * GET /api/public/events/{event}?lang=&on=YYYY-MM-DD
     *
     * A draft is indistinguishable from an event that does not exist.
     */
    public function show(Request $request, int $event): JsonResponse
    {
        $model = $this->events->publiclyVisibleById($event);

        if ($model === null) {
            throw new ModelNotFoundException;
        }

        $language = Language::fromRequest($request->query('lang'));
        $now = CarbonImmutable::now();

        // The occurrence the visitor arrived at, so a shared link to "the aarti
        // on the 12th" still says the 12th.
        $on = $request->query('on');
        $anchor = is_string($on) && $on !== ''
            ? CarbonImmutable::parse($on)->startOfDay()
            : $now;

        $upcoming = $this->events->occurrences(
            $model,
            $anchor,
            $anchor->addDays(EventService::DEFAULT_WINDOW_DAYS),
        );

        if ($upcoming === []) {
            // A one-off that has already happened still has a page.
            $upcoming = $this->events->occurrences(
                $model,
                CarbonImmutable::instance($model->start_at)->startOfDay(),
                $now,
            );
        }

        return ApiResponse::success([
            'event' => $upcoming === []
                ? null
                : (new PublicEventOccurrenceResource($upcoming[0], $language))->resolve($request),
            'occurrences' => array_map(
                fn (EventOccurrence $o) => (new PublicEventOccurrenceResource($o, $language))
                    ->resolve($request),
                array_slice($upcoming, 0, 10),
            ),
        ], ['timezone' => config('app.timezone')]);
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Resources\Events;

use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * An event as the editor sees it: both languages raw, and the recurrence rule
 * itself rather than the dates it produces.
 *
 * @mixin Event
 */
class AdminEventResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Event $event */
        $event = $this->resource;
        $timezone = config('app.timezone');

        return [
            'id' => $this->id,
            'event_type' => $this->event_type,
            'title_hi' => $this->title_hi,
            'title_en' => $this->title_en,
            'description_hi' => $this->description_hi,
            'description_en' => $this->description_en,
            'venue_hi' => $this->venue_hi,
            'venue_en' => $this->venue_en,
            'start_at' => $event->start_at->setTimezone($timezone)->toIso8601String(),
            'end_at' => $event->end_at?->setTimezone($timezone)->toIso8601String(),
            'recurrence' => $this->recurrence,
            'recurrence_days' => $this->recurrence_days ?? [],
            'recurrence_until' => $event->recurrence_until?->toDateString(),
            'poster_url' => $this->poster_url,
            'is_featured' => $event->is_featured,
            'status' => $this->status,
            'timezone' => $timezone,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}

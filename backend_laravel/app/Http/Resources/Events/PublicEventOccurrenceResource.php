<?php

declare(strict_types=1);

namespace App\Http\Resources\Events;

use App\Support\EventOccurrence;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One dated occurrence of an event, resolved for a language.
 *
 * Times carry the temple's UTC offset rather than being sent as bare UTC: a
 * client that ignores timezones still shows the right local time, and one that
 * respects them has the offset to work with (PHASE_4_PLAN assumption E3).
 *
 * A cancelled occurrence is returned, flagged rather than hidden — devotees who
 * planned around a festival need to be told it is off.
 */
class PublicEventOccurrenceResource extends JsonResource
{
    public function __construct(
        private readonly EventOccurrence $occurrence,
        private readonly Language $language,
    ) {
        parent::__construct($occurrence);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $event = $this->occurrence->event;
        $timezone = config('app.timezone');

        return [
            'id' => $event->id,
            'occurrence_key' => $this->occurrence->key(),
            'event_type' => $event->event_type,
            'requested_language' => $this->language->value,
            'title' => LocalizedText::resolve(
                $event->title_hi, $event->title_en, $this->language
            )->toArray(),
            'description' => LocalizedText::resolve(
                $event->description_hi, $event->description_en, $this->language
            )->toArray(),
            'venue' => LocalizedText::resolve(
                $event->venue_hi, $event->venue_en, $this->language
            )->toArray(),
            'start_at' => $this->occurrence->startAt->setTimezone($timezone)->toIso8601String(),
            'end_at' => $this->occurrence->endAt?->setTimezone($timezone)->toIso8601String(),
            'timezone' => $timezone,
            'is_recurring' => $event->repeats(),
            'recurrence' => $event->recurrence,
            'is_featured' => $event->is_featured,
            'is_cancelled' => $event->isCancelled(),
            'poster_url' => $event->poster_url,
        ];
    }
}

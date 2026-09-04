<?php

declare(strict_types=1);

namespace App\Support;

use App\Models\Event;
use Carbon\CarbonImmutable;

/**
 * One dated instance of an event.
 *
 * A recurring event is stored once as a rule; this is what that rule produces
 * for a particular date. The event is carried along so the serializer has the
 * bilingual content without a second lookup.
 */
final class EventOccurrence
{
    public function __construct(
        public readonly Event $event,
        public readonly CarbonImmutable $startAt,
        public readonly ?CarbonImmutable $endAt,
    ) {}

    /** When this occurrence is over — its end, or its start if none was given. */
    public function finishesAt(): CarbonImmutable
    {
        return $this->endAt ?? $this->startAt;
    }

    public function hasFinished(CarbonImmutable $now): bool
    {
        return $this->finishesAt()->lt($now);
    }

    /**
     * A stable identifier for one occurrence of a repeating event, so a link to
     * "the aarti on the 12th" survives being shared.
     */
    public function key(): string
    {
        return $this->event->id.'@'.$this->startAt->toDateString();
    }
}

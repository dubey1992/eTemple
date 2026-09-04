<?php

declare(strict_types=1);

namespace App\Services\Events;

use App\Exceptions\EventGuardException;
use App\Models\Event;
use App\Models\User;
use App\Support\EventOccurrence;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Collection;

/**
 * Business rules for the calendar, including recurrence expansion.
 *
 * An `events` row is a rule — "the aarti, daily, at 05:30" — and this is where
 * that rule becomes dates. Expansion happens on read across a bounded window so
 * an indefinite daily event never becomes an unbounded response
 * (PHASE_4_PLAN assumptions E1 and E2).
 */
class EventService
{
    /** Never expand one event beyond this many occurrences in a single window. */
    public const MAX_OCCURRENCES_PER_EVENT = 366;

    /** The widest window a caller may ask for, in days. */
    public const MAX_WINDOW_DAYS = 366;

    public const DEFAULT_WINDOW_DAYS = 90;

    /**
     * Occurrences a visitor may see, ordered for the requested view.
     *
     * @param  array{view?: string, days?: int, featured?: bool, type?: string}  $filters
     * @return list<EventOccurrence>
     */
    public function publicOccurrences(array $filters = [], ?CarbonImmutable $now = null): array
    {
        $now ??= CarbonImmutable::now();
        $past = ($filters['view'] ?? 'upcoming') === 'past';

        $days = max(1, min($filters['days'] ?? self::DEFAULT_WINDOW_DAYS, self::MAX_WINDOW_DAYS));
        [$from, $to] = $past
            ? [$now->subDays($days), $now]
            : [$now, $now->addDays($days)];

        $query = Event::query()->publiclyVisible();

        if (($filters['featured'] ?? false) === true) {
            // A cancelled event is never featured, whatever the flag says.
            $query->where('is_featured', true)->where('status', Event::STATUS_PUBLISHED);
        }

        if (isset($filters['type'])) {
            $query->where('event_type', $filters['type']);
        }

        /** @var Collection<int, Event> $events */
        $events = $query->orderBy('start_at')->get();

        $occurrences = [];
        foreach ($events as $event) {
            foreach ($this->occurrences($event, $from, $to) as $occurrence) {
                // "Upcoming" keeps anything still running; a festival that
                // started yesterday and ends tomorrow has not been missed.
                if ($past ? $occurrence->hasFinished($now) : ! $occurrence->hasFinished($now)) {
                    $occurrences[] = $occurrence;
                }
            }
        }

        usort(
            $occurrences,
            static fn (EventOccurrence $a, EventOccurrence $b) => $past
                ? $b->startAt <=> $a->startAt
                : $a->startAt <=> $b->startAt,
        );

        return $occurrences;
    }

    /**
     * One published or cancelled event, or null. Drafts are indistinguishable
     * from events that do not exist.
     */
    public function publiclyVisibleById(int $id): ?Event
    {
        return Event::query()->publiclyVisible()->whereKey($id)->first();
    }

    /**
     * Expand one event's rule across a window.
     *
     * @return list<EventOccurrence>
     */
    public function occurrences(
        Event $event,
        CarbonImmutable $from,
        CarbonImmutable $to,
    ): array {
        $start = CarbonImmutable::instance($event->start_at);
        $durationSeconds = $event->end_at === null
            ? null
            : CarbonImmutable::instance($event->end_at)->getTimestamp() - $start->getTimestamp();

        // The rule stops at the earlier of its own end date and the window's.
        $until = $event->recurrence_until === null
            ? $to
            : CarbonImmutable::instance($event->recurrence_until)->endOfDay();
        $limit = $until->lt($to) ? $until : $to;

        if (! $event->repeats()) {
            $single = $this->make($event, $start, $durationSeconds);

            return ($start->lte($limit) && ! $single->finishesAt()->lt($from)) ? [$single] : [];
        }

        $occurrences = [];
        foreach ($this->cursors($event, $start, $from, $limit) as $cursor) {
            $occurrence = $this->make($event, $cursor, $durationSeconds);

            // An occurrence that is still running has not been missed.
            if ($occurrence->finishesAt()->lt($from)) {
                continue;
            }

            $occurrences[] = $occurrence;

            if (count($occurrences) >= self::MAX_OCCURRENCES_PER_EVENT) {
                break;
            }
        }

        return $occurrences;
    }

    /**
     * The start instants the rule produces between [from, limit].
     *
     * Fast-forwards to the window instead of stepping from the first occurrence,
     * so a daily event that began years ago costs the same as one that began
     * yesterday.
     *
     * @return iterable<CarbonImmutable>
     */
    private function cursors(
        Event $event,
        CarbonImmutable $start,
        CarbonImmutable $from,
        CarbonImmutable $limit,
    ): iterable {
        if ($event->recurrence === Event::RECURRENCE_WEEKLY && $event->recurrence_days) {
            yield from $this->weeklyOnDays($event, $start, $from, $limit);

            return;
        }

        $cursor = $this->fastForward($event->recurrence, $start, $from);
        $guard = 0;

        while ($cursor->lte($limit) && $guard++ < self::MAX_OCCURRENCES_PER_EVENT * 2) {
            if ($cursor->gte($start)) {
                yield $cursor;
            }
            $cursor = $this->step($event->recurrence, $cursor);
        }
    }

    /**
     * Weekly on named days, e.g. bhajan-kirtan every Tuesday and Saturday.
     *
     * @return iterable<CarbonImmutable>
     */
    private function weeklyOnDays(
        Event $event,
        CarbonImmutable $start,
        CarbonImmutable $from,
        CarbonImmutable $limit,
    ): iterable {
        /** @var list<int> $days */
        $days = array_values(array_unique(array_map('intval', (array) $event->recurrence_days)));
        sort($days);

        if ($days === []) {
            return;
        }

        // Walk whole weeks from the Monday of the first relevant week. Monday is
        // pinned explicitly: startOfWeek() follows the locale, and a Sunday
        // start would shift every named weekday by one.
        $weekStart = ($start->gt($from) ? $start : $from)
            ->startOfWeek(CarbonInterface::MONDAY)
            ->setTimeFrom($start);
        $guard = 0;

        while ($weekStart->lte($limit) && $guard++ < self::MAX_OCCURRENCES_PER_EVENT) {
            foreach ($days as $day) {
                if ($day < 1 || $day > 7) {
                    continue;
                }

                $candidate = $weekStart->addDays($day - 1);

                if ($candidate->gte($start) && $candidate->lte($limit)) {
                    yield $candidate;
                }
            }

            $weekStart = $weekStart->addWeek();
        }
    }

    private function fastForward(
        string $recurrence,
        CarbonImmutable $start,
        CarbonImmutable $from,
    ): CarbonImmutable {
        if ($start->gte($from)) {
            return $start;
        }

        $elapsed = $from->getTimestamp() - $start->getTimestamp();

        return match ($recurrence) {
            // One period short of the window, so a still-running occurrence that
            // began just before it is not skipped.
            Event::RECURRENCE_DAILY => $start->addDays(max(0, intdiv($elapsed, 86400) - 1)),
            Event::RECURRENCE_WEEKLY => $start->addWeeks(max(0, intdiv($elapsed, 604800) - 1)),
            Event::RECURRENCE_MONTHLY => $start->addMonthsNoOverflow(
                max(0, $this->monthsBetween($start, $from) - 1)
            ),
            Event::RECURRENCE_YEARLY => $start->addYearsNoOverflow(
                max(0, intdiv($this->monthsBetween($start, $from), 12) - 1)
            ),
            default => $start,
        };
    }

    private function step(string $recurrence, CarbonImmutable $cursor): CarbonImmutable
    {
        return match ($recurrence) {
            Event::RECURRENCE_DAILY => $cursor->addDay(),
            Event::RECURRENCE_WEEKLY => $cursor->addWeek(),
            // "No overflow" so the 31st of a month does not become the 1st of
            // the next: a monthly puja on the 31st lands on the 30th in April.
            Event::RECURRENCE_MONTHLY => $cursor->addMonthNoOverflow(),
            Event::RECURRENCE_YEARLY => $cursor->addYearNoOverflow(),
            default => $cursor->addCentury(),
        };
    }

    private function monthsBetween(CarbonImmutable $a, CarbonImmutable $b): int
    {
        return ($b->year - $a->year) * 12 + ($b->month - $a->month);
    }

    private function make(Event $event, CarbonImmutable $start, ?int $durationSeconds): EventOccurrence
    {
        return new EventOccurrence(
            $event,
            $start,
            $durationSeconds === null ? null : $start->addSeconds($durationSeconds),
        );
    }

    // --- Administration ----------------------------------------------------

    /** @return Collection<int, Event> */
    public function adminList(?string $status = null): Collection
    {
        return Event::query()
            ->when($status !== null, fn ($q) => $q->where('status', $status))
            ->orderByDesc('start_at')
            ->get();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes, User $actor): Event
    {
        $event = new Event;
        $this->apply($event, $attributes);
        $event->created_by = $actor->id;
        $event->updated_by = $actor->id;
        $event->save();

        return $event->refresh();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Event $event, array $attributes, User $actor): Event
    {
        $this->apply($event, $attributes);
        $event->updated_by = $actor->id;
        $event->save();

        return $event->refresh();
    }

    public function delete(Event $event): void
    {
        $event->delete();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function apply(Event $event, array $attributes): void
    {
        $event->fill($attributes);

        // Also checked by the form request, so the rule holds for any caller.
        if ($event->end_at !== null && $event->end_at->lt($event->start_at)) {
            throw EventGuardException::endsBeforeItStarts();
        }

        if ($event->recurrence_until !== null
            && $event->recurrence_until->endOfDay()->lt($event->start_at)) {
            throw EventGuardException::repeatsUntilBeforeItStarts();
        }

        if ($event->recurrence === Event::RECURRENCE_WEEKLY
            && ($event->recurrence_days === null || $event->recurrence_days === [])) {
            // Fall back to the weekday the event starts on rather than
            // refusing: "weekly" already says everything needed.
            $event->recurrence_days = [(int) CarbonImmutable::instance($event->start_at)->isoWeekday()];
        }

        if ($event->recurrence !== Event::RECURRENCE_WEEKLY) {
            $event->recurrence_days = null;
        }

        if ($event->isCancelled()) {
            // A cancelled event is never promoted on the home page.
            $event->is_featured = false;
        }
    }
}

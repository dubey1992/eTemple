<?php

declare(strict_types=1);

namespace App\Reports\Reports;

use App\Models\Event;
use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRequest;
use App\Services\Events\EventService;
use App\Support\EventOccurrence;
use App\Support\EventType;
use App\Support\Language;
use App\Support\LocalizedText;
use App\Support\Permission;
use Carbon\CarbonImmutable;

/**
 * What the temple actually held.
 *
 * The rows are **occurrences, not records**: the daily aarti is one row in the
 * database and three hundred and sixty-five events in a year, and a committee
 * asking "what did we hold" means the second. They are expanded from each
 * event's recurrence rule by the same service the public calendar uses.
 *
 * A cancelled occurrence is **listed and flagged**, not dropped. "We did not
 * hold the Tuesday aarti in August" is a fact about the year, and a report that
 * quietly omitted it would show a year that did not happen.
 *
 * Nobody is named, so there are no personal columns: this project records no
 * attendance and the report does not invent any (PHASE_10_PLAN N10).
 */
class EventsReport implements Report
{
    public function __construct(private readonly EventService $events) {}

    public function key(): string
    {
        return 'events';
    }

    public function title(Language $language): string
    {
        return $language === Language::English ? 'Events held' : 'आयोजित कार्यक्रम';
    }

    public function description(Language $language): string
    {
        return $language === Language::English
            ? 'Every aarti, puja and festival that fell in the period, expanded from its schedule.'
            : 'अवधि में पड़ने वाली प्रत्येक आरती, पूजा एवं त्योहार — नियम से विस्तारित।';
    }

    public function permission(): string
    {
        return Permission::CONTENT_VIEW;
    }

    public function personalPermission(): ?string
    {
        return null;
    }

    public function columns(): array
    {
        return [
            ReportColumn::make('date', 'तिथि', 'Date', ReportColumn::DATE),
            ReportColumn::make('time', 'समय', 'Time'),
            ReportColumn::make('title', 'कार्यक्रम', 'Event'),
            ReportColumn::make('type', 'प्रकार', 'Type'),
            ReportColumn::make('repeats', 'नियमित', 'Recurring'),
            ReportColumn::make('status', 'स्थिति', 'Status'),
        ];
    }

    public function rows(ReportRequest $request): array
    {
        $occurrences = $this->occurrences($request);
        $english = $request->language === Language::English;

        $page = array_slice(
            $occurrences,
            ($request->page - 1) * $request->perPage,
            $request->perPage,
        );

        return array_map(
            fn (EventOccurrence $occurrence) => [
                'date' => $occurrence->startAt->toDateString(),
                'time' => $occurrence->startAt->format('H:i'),
                'title' => LocalizedText::resolve(
                    $occurrence->event->title_hi,
                    $occurrence->event->title_en,
                    $request->language,
                )->value ?? '',
                'type' => EventType::label($occurrence->event->event_type),
                'repeats' => $occurrence->event->repeats() ? ($english ? 'yes' : 'हाँ') : '',
                'status' => $occurrence->event->isCancelled()
                    ? ($english ? 'cancelled' : 'रद्द')
                    : ($english ? 'held' : 'आयोजित'),
            ],
            $page,
        );
    }

    public function summary(ReportRequest $request): array
    {
        $occurrences = $this->occurrences($request);

        $cancelled = count(array_filter(
            $occurrences,
            static fn (EventOccurrence $o) => $o->event->isCancelled(),
        ));

        $byType = [];
        foreach ($occurrences as $occurrence) {
            $type = $occurrence->event->event_type;
            $byType[$type] = ($byType[$type] ?? 0) + 1;
        }
        arsort($byType);

        $figures = [
            ['key' => 'row_count', 'label' => 'कुल आयोजन · Occurrences', 'value' => count($occurrences), 'type' => ReportColumn::NUMBER],
            ['key' => 'cancelled', 'label' => 'रद्द · Cancelled', 'value' => $cancelled, 'type' => ReportColumn::NUMBER],
        ];

        foreach ($byType as $type => $count) {
            $figures[] = [
                'key' => 'type_'.$type,
                'label' => EventType::label((string) $type),
                'value' => $count,
                'type' => ReportColumn::NUMBER,
            ];
        }

        return $figures;
    }

    /**
     * Every occurrence in the window, oldest first.
     *
     * Draft events are excluded: a draft is something the committee has not
     * decided to hold, and a report of what was held should not carry it.
     *
     * @return list<EventOccurrence>
     */
    private function occurrences(ReportRequest $request): array
    {
        $from = CarbonImmutable::parse($request->fromDate() ?? 'first day of January this year')->startOfDay();
        $to = CarbonImmutable::parse($request->toDate() ?? 'last day of December this year')->endOfDay();

        $type = $request->filter('type');

        $occurrences = [];
        foreach ($this->events->adminList() as $event) {
            if ($event->status === Event::STATUS_DRAFT) {
                continue;
            }

            if ($type !== null && $event->event_type !== $type) {
                continue;
            }

            foreach ($this->events->occurrences($event, $from, $to) as $occurrence) {
                $occurrences[] = $occurrence;
            }
        }

        usort(
            $occurrences,
            static fn (EventOccurrence $a, EventOccurrence $b) => $a->startAt <=> $b->startAt,
        );

        return $occurrences;
    }
}

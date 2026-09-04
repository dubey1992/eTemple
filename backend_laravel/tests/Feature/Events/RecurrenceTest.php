<?php

declare(strict_types=1);

namespace Tests\Feature\Events;

use App\Models\Event;
use App\Services\Events\EventService;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Recurrence expansion — the load-bearing logic of the calendar.
 *
 * An `events` row is a rule, not an instance. If this is wrong the daily aarti
 * either vanishes from the site or floods it, so the awkward cases (an event
 * that began years ago, a month with no 31st, a rule that has expired) are
 * tested directly rather than through the API.
 */
class RecurrenceTest extends TestCase
{
    use RefreshDatabase;

    private EventService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(EventService::class);
    }

    private function window(string $from, int $days): array
    {
        $start = CarbonImmutable::parse($from);

        return [$start, $start->addDays($days)];
    }

    public function test_a_one_off_event_produces_exactly_one_occurrence(): void
    {
        $event = Event::factory()->published()->create([
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
            'end_at' => CarbonImmutable::parse('2026-10-05 20:00'),
        ]);

        [$from, $to] = $this->window('2026-10-01', 30);

        $this->assertCount(1, $this->service->occurrences($event, $from, $to));
    }

    public function test_a_one_off_event_outside_the_window_produces_none(): void
    {
        $event = Event::factory()->published()->create([
            'start_at' => CarbonImmutable::parse('2026-12-25 18:00'),
            'end_at' => null,
        ]);

        [$from, $to] = $this->window('2026-10-01', 30);

        $this->assertSame([], $this->service->occurrences($event, $from, $to));
    }

    public function test_a_daily_event_fills_the_window(): void
    {
        $event = Event::factory()->create([
            'status' => Event::STATUS_PUBLISHED,
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2026-01-01 18:30'),
            'end_at' => CarbonImmutable::parse('2026-01-01 19:00'),
        ]);

        [$from, $to] = $this->window('2026-10-01 00:00', 6);
        $occurrences = $this->service->occurrences($event, $from, $to);

        // The window closes at midnight on the 7th, so that evening's 18:30
        // occurrence falls outside it: the 1st through the 6th.
        $this->assertCount(6, $occurrences);
        $this->assertSame('2026-10-01', $occurrences[0]->startAt->toDateString());
        $this->assertSame('2026-10-06', $occurrences[5]->startAt->toDateString());
    }

    public function test_a_daily_event_keeps_its_time_of_day(): void
    {
        // The stored start fixes the clock time every later occurrence inherits.
        $event = Event::factory()->create([
            'status' => Event::STATUS_PUBLISHED,
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2026-01-01 18:30'),
            'end_at' => CarbonImmutable::parse('2026-01-01 19:15'),
        ]);

        [$from, $to] = $this->window('2026-10-01 00:00', 2);

        foreach ($this->service->occurrences($event, $from, $to) as $occurrence) {
            $this->assertSame('18:30', $occurrence->startAt->format('H:i'));
            $this->assertSame('19:15', $occurrence->endAt?->format('H:i'));
        }
    }

    public function test_an_event_that_began_years_ago_still_expands_correctly(): void
    {
        // Fast-forwarding must land on the right day, not merely a nearby one.
        $event = Event::factory()->create([
            'status' => Event::STATUS_PUBLISHED,
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2015-03-04 05:30'),
            'end_at' => CarbonImmutable::parse('2015-03-04 06:00'),
        ]);

        [$from, $to] = $this->window('2026-10-01 00:00', 3);
        $occurrences = $this->service->occurrences($event, $from, $to);

        // The 4th's 05:30 is past the window's midnight boundary.
        $this->assertSame(
            ['2026-10-01', '2026-10-02', '2026-10-03'],
            array_map(fn ($o) => $o->startAt->toDateString(), $occurrences),
        );
        $this->assertSame('05:30', $occurrences[0]->startAt->format('H:i'));
    }

    public function test_a_weekly_event_repeats_on_its_named_days(): void
    {
        // Tuesday (2) and Saturday (6).
        $event = Event::factory()->weeklyOn([2, 6])->create([
            'start_at' => CarbonImmutable::parse('2026-09-01 19:00'),
            'end_at' => CarbonImmutable::parse('2026-09-01 20:00'),
        ]);

        [$from, $to] = $this->window('2026-10-05 00:00', 13);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $days = array_unique(array_map(fn ($o) => $o->startAt->isoWeekday(), $occurrences));
        sort($days);

        $this->assertSame([2, 6], $days);
        // Two weeks, two days a week.
        $this->assertCount(4, $occurrences);
    }

    public function test_weekly_without_named_days_falls_back_to_the_start_weekday(): void
    {
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_WEEKLY,
            'recurrence_days' => null,
            'start_at' => CarbonImmutable::parse('2026-09-02 19:00'), // a Wednesday
            'end_at' => null,
        ]);

        [$from, $to] = $this->window('2026-10-01 00:00', 20);

        foreach ($this->service->occurrences($event, $from, $to) as $occurrence) {
            $this->assertSame(3, $occurrence->startAt->isoWeekday());
        }
    }

    public function test_a_monthly_event_does_not_slide_into_the_next_month(): void
    {
        // The 31st has no equivalent in April; it must land on the 30th rather
        // than rolling over to 1 May and drifting from then on.
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_MONTHLY,
            'start_at' => CarbonImmutable::parse('2026-01-31 10:00'),
            'end_at' => null,
        ]);

        [$from, $to] = $this->window('2026-04-01 00:00', 40);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $dates = array_map(fn ($o) => $o->startAt->toDateString(), $occurrences);

        $this->assertContains('2026-04-30', $dates);
        $this->assertNotContains('2026-05-01', $dates);
    }

    public function test_a_yearly_event_repeats_once_a_year(): void
    {
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_YEARLY,
            'start_at' => CarbonImmutable::parse('2020-08-26 06:00'),
            'end_at' => null,
        ]);

        [$from, $to] = $this->window('2026-01-01 00:00', 365);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $this->assertCount(1, $occurrences);
        $this->assertSame('2026-08-26', $occurrences[0]->startAt->toDateString());
    }

    public function test_a_rule_stops_at_its_until_date(): void
    {
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2026-09-01 18:00'),
            'end_at' => null,
            'recurrence_until' => CarbonImmutable::parse('2026-10-03'),
        ]);

        [$from, $to] = $this->window('2026-10-01 00:00', 30);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $this->assertSame(
            ['2026-10-01', '2026-10-02', '2026-10-03'],
            array_map(fn ($o) => $o->startAt->toDateString(), $occurrences),
        );
    }

    public function test_an_expired_rule_produces_nothing(): void
    {
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2026-01-01 18:00'),
            'end_at' => null,
            'recurrence_until' => CarbonImmutable::parse('2026-02-01'),
        ]);

        [$from, $to] = $this->window('2026-10-01', 30);

        $this->assertSame([], $this->service->occurrences($event, $from, $to));
    }

    public function test_occurrences_never_precede_the_first_one(): void
    {
        // A window that opens before the event exists must not invent history.
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2026-10-10 18:00'),
            'end_at' => null,
        ]);

        [$from, $to] = $this->window('2026-10-01 00:00', 12);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $this->assertSame('2026-10-10', $occurrences[0]->startAt->toDateString());
    }

    public function test_an_indefinite_daily_event_is_capped(): void
    {
        // Without a cap, a wide window on an indefinite rule is a
        // denial-of-service against our own API.
        $event = Event::factory()->published()->create([
            'recurrence' => Event::RECURRENCE_DAILY,
            'start_at' => CarbonImmutable::parse('2000-01-01 06:00'),
            'end_at' => null,
        ]);

        [$from, $to] = $this->window('2026-01-01', 10000);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $this->assertLessThanOrEqual(
            EventService::MAX_OCCURRENCES_PER_EVENT,
            count($occurrences),
        );
    }

    public function test_a_multi_day_event_still_running_is_not_treated_as_past(): void
    {
        // A three-day festival that began yesterday has not been missed.
        $event = Event::factory()->published()->create([
            'start_at' => CarbonImmutable::parse('2026-09-30 09:00'),
            'end_at' => CarbonImmutable::parse('2026-10-02 21:00'),
        ]);

        [$from, $to] = $this->window('2026-10-01 12:00', 30);
        $occurrences = $this->service->occurrences($event, $from, $to);

        $this->assertCount(1, $occurrences);
        $this->assertFalse(
            $occurrences[0]->hasFinished(CarbonImmutable::parse('2026-10-01 12:00'))
        );
    }
}

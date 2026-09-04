<?php

declare(strict_types=1);

namespace Tests\Feature\Events;

use App\Models\Event;
use App\Support\EventType;
use Carbon\CarbonImmutable;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventPublicTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        // A fixed clock: "upcoming" and "past" are meaningless assertions
        // against a moving now.
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-10-01 09:00'));
    }

    protected function tearDown(): void
    {
        CarbonImmutable::setTestNow();
        parent::tearDown();
    }

    public function test_the_list_is_empty_on_a_fresh_site(): void
    {
        $this->getJson('/api/public/events')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', [])
            ->assertJsonPath('meta.view', 'upcoming');
    }

    public function test_the_public_endpoint_needs_no_authentication(): void
    {
        Event::factory()->published()->create();

        $this->getJson('/api/public/events')->assertOk();
    }

    public function test_a_draft_event_is_never_public(): void
    {
        Event::factory()->create([
            'title_hi' => 'गुप्त कार्यक्रम',
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);

        $response = $this->getJson('/api/public/events')->assertOk();

        $this->assertSame([], $response->json('data'));
        $this->assertStringNotContainsString('गुप्त', $response->getContent() ?: '');
    }

    public function test_a_draft_is_indistinguishable_from_a_missing_event(): void
    {
        $draft = Event::factory()->create();

        $this->getJson("/api/public/events/{$draft->id}")
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'NOT_FOUND');

        $this->getJson('/api/public/events/999999')
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_a_cancelled_event_stays_visible_and_is_flagged(): void
    {
        // Silently dropping it would leave devotees who planned around the
        // festival finding nothing and assuming the site was broken.
        Event::factory()->cancelled()->create([
            'title_hi' => 'रद्द उत्सव',
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
            'end_at' => CarbonImmutable::parse('2026-10-05 21:00'),
        ]);

        $this->getJson('/api/public/events')
            ->assertOk()
            ->assertJsonPath('data.0.title.value', 'रद्द उत्सव')
            ->assertJsonPath('data.0.is_cancelled', true);
    }

    public function test_a_cancelled_event_is_never_featured(): void
    {
        $event = Event::factory()->featured()->create([
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);
        $event->forceFill(['status' => Event::STATUS_CANCELLED])->save();

        $this->getJson('/api/public/events?featured=1')
            ->assertOk()
            ->assertJsonPath('data', []);
    }

    public function test_upcoming_is_the_default_view_and_is_ordered_soonest_first(): void
    {
        Event::factory()->published()->create([
            'title_hi' => 'बाद में',
            'start_at' => CarbonImmutable::parse('2026-10-20 18:00'),
            'end_at' => null,
        ]);
        Event::factory()->published()->create([
            'title_hi' => 'पहले',
            'start_at' => CarbonImmutable::parse('2026-10-03 18:00'),
            'end_at' => null,
        ]);

        $titles = $this->getJson('/api/public/events')
            ->assertOk()
            ->json('data.*.title.value');

        $this->assertSame(['पहले', 'बाद में'], $titles);
    }

    public function test_past_events_are_returned_most_recent_first(): void
    {
        Event::factory()->published()->create([
            'title_hi' => 'बहुत पुराना',
            'start_at' => CarbonImmutable::parse('2026-09-01 18:00'),
            'end_at' => CarbonImmutable::parse('2026-09-01 20:00'),
        ]);
        Event::factory()->published()->create([
            'title_hi' => 'हाल का',
            'start_at' => CarbonImmutable::parse('2026-09-28 18:00'),
            'end_at' => CarbonImmutable::parse('2026-09-28 20:00'),
        ]);

        $response = $this->getJson('/api/public/events?view=past')->assertOk();

        $this->assertSame('past', $response->json('meta.view'));
        $this->assertSame(['हाल का', 'बहुत पुराना'], $response->json('data.*.title.value'));
    }

    public function test_a_past_event_does_not_appear_in_upcoming(): void
    {
        Event::factory()->past()->create(['title_hi' => 'बीत गया']);

        $this->getJson('/api/public/events')
            ->assertOk()
            ->assertJsonPath('data', []);
    }

    public function test_the_daily_aarti_is_one_record_and_many_occurrences(): void
    {
        Event::factory()->dailyAarti()->create();

        $response = $this->getJson('/api/public/events?days=7')->assertOk();

        $this->assertSame(1, Event::query()->count());
        $this->assertGreaterThanOrEqual(7, count($response->json('data')));

        // Every occurrence points back at the same event but has its own date.
        $ids = array_unique($response->json('data.*.id'));
        $keys = array_unique($response->json('data.*.occurrence_key'));

        $this->assertCount(1, $ids);
        $this->assertGreaterThanOrEqual(7, count($keys));
    }

    public function test_the_window_is_bounded_however_wide_the_request(): void
    {
        Event::factory()->dailyAarti()->create();

        $response = $this->getJson('/api/public/events?days=100000')->assertOk();

        $this->assertLessThanOrEqual(366, count($response->json('data')));
    }

    public function test_events_are_resolved_for_the_requested_language(): void
    {
        Event::factory()->published()->create([
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);

        $this->getJson('/api/public/events?lang=en')
            ->assertOk()
            ->assertJsonPath('data.0.title.value', 'Test event')
            ->assertJsonPath('data.0.title.fallback_used', false);
    }

    public function test_a_hindi_only_event_falls_back_and_says_so(): void
    {
        Event::factory()->published()->hindiOnly()->create([
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);

        $this->getJson('/api/public/events?lang=en')
            ->assertOk()
            ->assertJsonPath('data.0.title.value', 'परीक्षण कार्यक्रम')
            ->assertJsonPath('data.0.title.language', 'hi')
            ->assertJsonPath('data.0.title.fallback_used', true);
    }

    public function test_times_carry_the_temples_offset_not_bare_utc(): void
    {
        // A client that ignores timezones must still show the right local time.
        Event::factory()->published()->create([
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
            'end_at' => CarbonImmutable::parse('2026-10-05 20:00'),
        ]);

        $response = $this->getJson('/api/public/events')->assertOk();

        $this->assertStringContainsString('+05:30', $response->json('data.0.start_at'));
        $this->assertStringContainsString('+05:30', $response->json('data.0.end_at'));
        $this->assertSame('Asia/Kolkata', $response->json('data.0.timezone'));
        $this->assertSame('Asia/Kolkata', $response->json('meta.timezone'));
    }

    public function test_the_featured_filter_narrows_the_list(): void
    {
        Event::factory()->featured()->create([
            'title_hi' => 'मुख्य',
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);
        Event::factory()->published()->create([
            'title_hi' => 'साधारण',
            'start_at' => CarbonImmutable::parse('2026-10-06 18:00'),
        ]);

        $this->getJson('/api/public/events?featured=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title.value', 'मुख्य');
    }

    public function test_the_type_filter_narrows_the_list(): void
    {
        Event::factory()->published()->create([
            'event_type' => EventType::FESTIVAL,
            'title_hi' => 'उत्सव',
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);
        Event::factory()->published()->create([
            'event_type' => EventType::AARTI,
            'title_hi' => 'आरती',
            'start_at' => CarbonImmutable::parse('2026-10-06 18:00'),
        ]);

        $this->getJson('/api/public/events?type='.EventType::FESTIVAL)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title.value', 'उत्सव');
    }

    public function test_an_unknown_type_filter_is_ignored_rather_than_erroring(): void
    {
        Event::factory()->published()->create([
            'start_at' => CarbonImmutable::parse('2026-10-05 18:00'),
        ]);

        $this->getJson('/api/public/events?type=not-a-type')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_the_detail_endpoint_returns_the_event_and_its_next_occurrences(): void
    {
        $event = Event::factory()->dailyAarti()->create();

        $response = $this->getJson("/api/public/events/{$event->id}")->assertOk();

        $this->assertSame($event->id, $response->json('data.event.id'));
        $this->assertGreaterThan(1, count($response->json('data.occurrences')));
    }

    public function test_the_detail_endpoint_honours_the_requested_occurrence_date(): void
    {
        // A shared link to "the aarti on the 12th" must still say the 12th.
        $event = Event::factory()->dailyAarti()->create();

        $this->getJson("/api/public/events/{$event->id}?on=2026-10-12")
            ->assertOk()
            ->assertJsonPath('data.event.occurrence_key', $event->id.'@2026-10-12');
    }

    public function test_a_one_off_event_that_has_passed_still_has_a_page(): void
    {
        $event = Event::factory()->past()->create();

        $this->getJson("/api/public/events/{$event->id}")
            ->assertOk()
            ->assertJsonPath('data.event.id', $event->id);
    }
}

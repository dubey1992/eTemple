<?php

declare(strict_types=1);

namespace Tests\Feature\Events;

use App\Models\Event;
use App\Models\Role;
use App\Models\User;
use App\Support\EventType;
use Carbon\CarbonImmutable;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $editor;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->editor = User::factory()->withRole(Role::ADMIN)->create();
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-10-01 09:00'));
    }

    protected function tearDown(): void
    {
        CarbonImmutable::setTestNow();
        parent::tearDown();
    }

    /** @return array<string, mixed> */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'event_type' => EventType::FESTIVAL,
            'title_hi' => 'जन्माष्टमी',
            'title_en' => 'Janmashtami',
            'start_at' => '2026-10-15 18:00:00',
            'end_at' => '2026-10-15 22:00:00',
            'status' => Event::STATUS_PUBLISHED,
        ], $overrides);
    }

    public function test_an_editor_can_create_an_event(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload())
            ->assertStatus(201)
            ->assertJsonPath('data.title_hi', 'जन्माष्टमी')
            ->assertJsonPath('data.status', Event::STATUS_PUBLISHED);

        $event = Event::query()->sole();
        $this->assertSame($this->editor->id, $event->created_by);
        $this->assertSame($this->editor->id, $event->updated_by);
    }

    public function test_a_new_event_defaults_to_a_draft_when_asked_for_one(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload([
                'status' => Event::STATUS_DRAFT,
            ]))
            ->assertStatus(201)
            ->assertJsonPath('data.status', Event::STATUS_DRAFT);

        // And it is not on the public site.
        $this->getJson('/api/public/events')->assertOk()->assertJsonPath('data', []);
    }

    public function test_hindi_title_type_start_and_status_are_required(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', ['title_en' => 'English only'])
            ->assertStatus(422)
            ->assertJsonStructure([
                'error' => ['details' => ['event_type', 'title_hi', 'start_at', 'status']],
            ]);
    }

    public function test_an_unknown_event_type_is_refused(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload(['event_type' => 'wedding']))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['event_type']]]);
    }

    public function test_an_event_cannot_end_before_it_starts(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload([
                'start_at' => '2026-10-15 18:00:00',
                'end_at' => '2026-10-15 17:00:00',
            ]))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['end_at']]]);

        $this->assertSame(0, Event::query()->count());
    }

    public function test_a_repeat_until_date_before_the_first_occurrence_is_refused(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload([
                'recurrence' => Event::RECURRENCE_DAILY,
                'recurrence_until' => '2026-09-01',
            ]))
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['recurrence_until']]]);
    }

    public function test_weekly_without_named_days_adopts_the_start_weekday(): void
    {
        // "Weekly" already says everything needed; refusing would be pedantic.
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload([
                // 2026-10-15 is a Thursday.
                'recurrence' => Event::RECURRENCE_WEEKLY,
            ]))
            ->assertStatus(201)
            ->assertJsonPath('data.recurrence_days', [4]);
    }

    public function test_recurrence_days_are_cleared_when_the_rule_is_not_weekly(): void
    {
        // A leftover day list on a daily event would be silently misleading.
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload([
                'recurrence' => Event::RECURRENCE_DAILY,
                'recurrence_days' => [2, 5],
            ]))
            ->assertStatus(201)
            ->assertJsonPath('data.recurrence_days', []);
    }

    public function test_a_weekday_outside_one_to_seven_is_refused(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/events', $this->payload([
                'recurrence' => Event::RECURRENCE_WEEKLY,
                'recurrence_days' => [0, 9],
            ]))
            ->assertStatus(422);
    }

    public function test_cancelling_an_event_removes_its_featured_flag(): void
    {
        $event = Event::factory()->featured()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/events/{$event->id}", $this->payload([
                'status' => Event::STATUS_CANCELLED,
                'is_featured' => true,
            ]))
            ->assertOk()
            ->assertJsonPath('data.is_featured', false);
    }

    public function test_an_editor_can_update_an_event(): void
    {
        $event = Event::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/events/{$event->id}", $this->payload([
                'title_hi' => 'सुधारा हुआ नाम',
            ]))
            ->assertOk()
            ->assertJsonPath('data.title_hi', 'सुधारा हुआ नाम');
    }

    public function test_an_editor_can_delete_an_event(): void
    {
        $event = Event::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->deleteJson("/api/admin/events/{$event->id}")
            ->assertNoContent();

        $this->assertSame(0, Event::query()->count());
    }

    public function test_the_admin_list_includes_drafts_cancelled_and_past_events(): void
    {
        // The calendar is a record as well as a schedule.
        Event::factory()->create(['title_hi' => 'मसौदा']);
        Event::factory()->cancelled()->create(['title_hi' => 'रद्द']);
        Event::factory()->past()->create(['title_hi' => 'बीता हुआ']);

        $titles = $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/events')
            ->assertOk()
            ->json('data.*.title_hi');

        $this->assertContains('मसौदा', $titles);
        $this->assertContains('रद्द', $titles);
        $this->assertContains('बीता हुआ', $titles);
    }

    public function test_the_admin_list_can_be_filtered_by_status(): void
    {
        Event::factory()->create(['title_hi' => 'मसौदा']);
        Event::factory()->published()->create(['title_hi' => 'प्रकाशित']);

        $titles = $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/events?status='.Event::STATUS_DRAFT)
            ->assertOk()
            ->json('data.*.title_hi');

        $this->assertSame(['मसौदा'], $titles);
    }

    public function test_the_admin_view_returns_the_rule_not_the_expanded_dates(): void
    {
        // The committee edits the rule; expanding it is the public API's job.
        $event = Event::factory()->dailyAarti()->create();

        $this->actingAs($this->editor, 'web')
            ->getJson("/api/admin/events/{$event->id}")
            ->assertOk()
            ->assertJsonPath('data.recurrence', Event::RECURRENCE_DAILY)
            ->assertJsonPath('data.timezone', 'Asia/Kolkata');
    }

    public function test_an_unknown_event_is_a_404(): void
    {
        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/events/999999')
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_publishing_a_draft_makes_it_public_immediately(): void
    {
        $event = Event::factory()->create([
            'start_at' => CarbonImmutable::parse('2026-10-15 18:00'),
            'end_at' => CarbonImmutable::parse('2026-10-15 20:00'),
        ]);

        $this->getJson('/api/public/events')->assertOk()->assertJsonPath('data', []);

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/events/{$event->id}", $this->payload([
                'title_hi' => $event->title_hi,
            ]))
            ->assertOk();

        $this->getJson('/api/public/events')->assertOk()->assertJsonCount(1, 'data');
    }
}

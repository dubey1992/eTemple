<?php

declare(strict_types=1);

namespace Tests\Feature\Announcements;

use App\Models\Announcement;
use App\Support\AnnouncementPriority;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * What the public endpoint hands out, and when.
 *
 * The whole phase turns on this being a **query** and not a serializer
 * decision: if the schedule were applied while rendering, "scheduled for next
 * Tuesday" would be a display convention, and the first caller to hit the
 * endpoint directly would read next week's news.
 */
class AnnouncementScheduleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_only_a_published_announcement_inside_its_window_is_public(): void
    {
        $showing = Announcement::factory()->showing()->create(['title_hi' => 'अभी दिख रहा है']);
        Announcement::factory()->create(['title_hi' => 'मसौदा']);
        Announcement::factory()->scheduled()->create(['title_hi' => 'अगले सप्ताह']);
        Announcement::factory()->expired()->create(['title_hi' => 'बीत चुका']);
        Announcement::factory()->archived()->create(['title_hi' => 'हटाया गया']);

        $response = $this->getJson('/api/public/announcements')->assertOk();

        $this->assertCount(1, $response->json('data'));
        $this->assertSame($showing->id, $response->json('data.0.id'));

        $body = $response->getContent();
        foreach (['मसौदा', 'अगले सप्ताह', 'बीत चुका', 'हटाया गया'] as $hidden) {
            $this->assertStringNotContainsString($hidden, $body);
        }
    }

    public function test_a_notice_appears_the_moment_its_window_opens(): void
    {
        Announcement::factory()->create([
            'status' => Announcement::STATUS_PUBLISHED,
            'start_at' => now()->addMinutes(10),
            'end_at' => now()->addDay(),
            'title_hi' => 'दस मिनट बाद',
        ]);

        $this->assertCount(0, $this->getJson('/api/public/announcements')->json('data'));

        // Nothing runs in between: no scheduler, no status flip. The clock
        // moves and the query answers differently (PHASE_8_PLAN assumption N3).
        $this->travel(11)->minutes();

        $this->assertCount(1, $this->getJson('/api/public/announcements')->json('data'));
    }

    public function test_a_notice_disappears_the_moment_its_window_closes(): void
    {
        Announcement::factory()->create([
            'status' => Announcement::STATUS_PUBLISHED,
            'start_at' => now()->subDay(),
            'end_at' => now()->addMinutes(10),
        ]);

        $this->assertCount(1, $this->getJson('/api/public/announcements')->json('data'));

        $this->travel(11)->minutes();

        $this->assertCount(0, $this->getJson('/api/public/announcements')->json('data'));
    }

    public function test_a_notice_with_no_end_runs_until_it_is_archived(): void
    {
        $announcement = Announcement::factory()->showing()->create(['end_at' => null]);

        $this->travel(400)->days();
        $this->assertCount(1, $this->getJson('/api/public/announcements')->json('data'));

        // `status` is not mass-assignable — archiving is a decision with its
        // own endpoint, not a field. Forced here because this test is about the
        // window, not about how the status got set.
        $announcement->forceFill(['status' => Announcement::STATUS_ARCHIVED])->save();
        $this->assertCount(0, $this->getJson('/api/public/announcements')->json('data'));
    }

    public function test_the_loudest_notice_comes_first(): void
    {
        Announcement::factory()->showing()->create(['title_hi' => 'सामान्य']);
        Announcement::factory()->showing()->important()->create(['title_hi' => 'महत्वपूर्ण']);
        Announcement::factory()->showing()->urgent()->create(['title_hi' => 'अत्यावश्यक']);

        $priorities = $this->getJson('/api/public/announcements')->json('data.*.priority');

        $this->assertSame(
            [
                AnnouncementPriority::URGENT,
                AnnouncementPriority::IMPORTANT,
                AnnouncementPriority::NORMAL,
            ],
            $priorities,
        );
    }

    public function test_priority_grants_nothing(): void
    {
        // An urgent notice obeys exactly the same schedule as any other
        // (assumption N8): being loud is not being early.
        Announcement::factory()->scheduled()->urgent()->create();

        $this->assertCount(0, $this->getJson('/api/public/announcements')->json('data'));
    }

    public function test_the_public_notice_says_nothing_about_who_wrote_or_sent_it(): void
    {
        Announcement::factory()->showing()->create([
            'sent_at' => now(),
            'recipient_count' => 7,
            'channels' => ['site', 'email'],
        ]);

        $body = $this->getJson('/api/public/announcements')->getContent();

        foreach (['sent_at', 'recipient_count', 'channels', 'status', 'created_by'] as $private) {
            $this->assertStringNotContainsString($private, $body, "{$private} reached the public endpoint");
        }
    }

    public function test_english_falls_back_to_hindi_and_says_that_it_did(): void
    {
        Announcement::factory()->showing()->create([
            'title_hi' => 'जन्माष्टमी',
            'title_en' => null,
        ]);

        $response = $this->getJson('/api/public/announcements?lang=en')->assertOk();

        $this->assertSame('जन्माष्टमी', $response->json('data.0.title.value'));
        $this->assertSame('hi', $response->json('data.0.title.language'));
        $this->assertTrue($response->json('data.0.title.fallback_used'));
    }

    public function test_english_is_served_when_it_was_written(): void
    {
        Announcement::factory()->showing()->create([
            'title_hi' => 'जन्माष्टमी',
            'title_en' => 'Janmashtami',
        ]);

        $response = $this->getJson('/api/public/announcements?lang=en')->assertOk();

        $this->assertSame('Janmashtami', $response->json('data.0.title.value'));
        $this->assertFalse($response->json('data.0.title.fallback_used'));
    }

    public function test_the_public_list_is_bounded(): void
    {
        Announcement::factory()->showing()->count(20)->create();

        // An unbounded list on a public endpoint is a denial-of-service against
        // our own API.
        $this->assertLessThanOrEqual(
            5,
            count($this->getJson('/api/public/announcements')->json('data')),
        );
    }
}

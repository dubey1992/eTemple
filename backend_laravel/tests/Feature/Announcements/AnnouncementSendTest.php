<?php

declare(strict_types=1);

namespace Tests\Feature\Announcements;

use App\Mail\AnnouncementNotification;
use App\Models\Announcement;
use App\Models\Enquiry;
use App\Models\Role;
use App\Models\User;
use App\Support\AnnouncementChannel;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Sending — the one thing in this application that cannot be undone.
 *
 * Every test here is about a way somebody could send something they did not
 * mean to, or believe they had sent something they had not.
 */
class AnnouncementSendTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        Mail::fake();

        $this->admin = User::factory()->withRole(Role::ADMIN)->create();
        $this->actingAs($this->admin, 'web');
    }

    public function test_saving_an_announcement_sends_nothing(): void
    {
        $this->postJson('/api/admin/announcements', [
            'title_hi' => 'सूचना',
            'message_hi' => 'मंदिर में कल विशेष आरती होगी।',
        ])->assertCreated();

        // The specification's rule, at its plainest: no sends without explicit
        // admin action (PHASE_8_PLAN assumption N1).
        Mail::assertNothingQueued();

        $announcement = Announcement::query()->firstOrFail();
        $this->assertSame(Announcement::STATUS_DRAFT, $announcement->status);
        $this->assertFalse($announcement->wasSent());
    }

    public function test_publishing_an_announcement_sends_nothing(): void
    {
        $announcement = Announcement::factory()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/publish")->assertOk();

        Mail::assertNothingQueued();
        $this->assertNull($announcement->refresh()->sent_at);
    }

    public function test_sending_needs_a_channel_to_be_chosen(): void
    {
        $announcement = Announcement::factory()->showing()->create();

        // No default channel, deliberately: a default would mean the most
        // consequential action in the phase could happen without a choice.
        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [])
            ->assertStatus(422);

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", ['channels' => []])
            ->assertStatus(422);

        Mail::assertNothingQueued();
    }

    public function test_a_published_announcement_can_be_sent_to_the_committee(): void
    {
        User::factory()->withRole(Role::CONTENT_MANAGER)->create(['email' => 'member@thakurbari.local']);
        $announcement = Announcement::factory()->showing()->create();

        $response = $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::SITE, AnnouncementChannel::EMAIL],
        ])->assertOk();

        Mail::assertQueued(AnnouncementNotification::class);

        $announcement->refresh();
        $this->assertTrue($announcement->wasSent());
        $this->assertSame($this->admin->id, $announcement->sent_by);
        $this->assertSame(2, $announcement->recipient_count);
        $this->assertSame(['site', 'email'], $announcement->channels);
        $this->assertTrue($response->json('data.was_sent'));
    }

    public function test_a_second_send_is_refused(): void
    {
        $announcement = Announcement::factory()->showing()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])->assertOk();

        $sentAt = $announcement->refresh()->sent_at;
        Mail::fake();

        // A message cannot be unsent, so the second press is refused rather
        // than obeyed (assumption N6).
        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'ANNOUNCEMENT_ALREADY_SENT');

        Mail::assertNothingQueued();
        $this->assertTrue($sentAt->equalTo($announcement->refresh()->sent_at));
    }

    public function test_a_draft_cannot_be_sent(): void
    {
        $announcement = Announcement::factory()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'ANNOUNCEMENT_NOT_PUBLISHED');

        Mail::assertNothingQueued();
    }

    public function test_an_archived_announcement_cannot_be_sent(): void
    {
        $announcement = Announcement::factory()->archived()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])->assertStatus(409);

        Mail::assertNothingQueued();
    }

    public function test_an_unconnected_channel_is_refused_and_says_why(): void
    {
        config(['announcements.channels.sms' => false]);
        $announcement = Announcement::factory()->showing()->create();

        $response = $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::SMS],
        ])->assertStatus(422);

        // A checkbox that appears to send an SMS and quietly does nothing is
        // worse than no checkbox (assumption N5).
        $this->assertStringContainsString('provider', $response->json('error.message'));

        Mail::assertNothingQueued();
        $this->assertFalse($announcement->refresh()->wasSent());
    }

    public function test_one_unavailable_channel_refuses_the_whole_send(): void
    {
        config(['announcements.channels.whatsapp' => false]);
        $announcement = Announcement::factory()->showing()->create();

        // Partly sending would leave the committee unsure what went out.
        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL, AnnouncementChannel::WHATSAPP],
        ])->assertStatus(422);

        Mail::assertNothingQueued();
        $this->assertFalse($announcement->refresh()->wasSent());
    }

    public function test_a_devotee_who_wrote_to_the_temple_is_not_added_to_a_mailing_list(): void
    {
        // A villager gave this address to get an answer to their question.
        // Using it for announcements is consent laundering (assumption N4).
        Enquiry::factory()->create(['email' => 'devotee@example.test']);
        $announcement = Announcement::factory()->showing()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])->assertOk();

        Mail::assertNotQueued(
            AnnouncementNotification::class,
            fn (AnnouncementNotification $mail) => $mail->hasTo('devotee@example.test'),
        );
    }

    public function test_a_blocked_account_is_not_written_to(): void
    {
        User::factory()->withRole(Role::VIEWER)->create([
            'email' => 'blocked@thakurbari.local',
            'status' => User::STATUS_BLOCKED,
        ]);
        $announcement = Announcement::factory()->showing()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])->assertOk();

        Mail::assertNotQueued(
            AnnouncementNotification::class,
            fn (AnnouncementNotification $mail) => $mail->hasTo('blocked@thakurbari.local'),
        );
        $this->assertSame(1, $announcement->refresh()->recipient_count);
    }

    public function test_sending_on_the_site_channel_alone_queues_no_mail(): void
    {
        $announcement = Announcement::factory()->showing()->create();

        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::SITE],
        ])->assertOk();

        Mail::assertNothingQueued();
        $this->assertSame(0, $announcement->refresh()->recipient_count);
        // Still recorded as sent: the committee said "put it out", and that it
        // went out on the website only is what `channels` records.
        $this->assertTrue($announcement->wasSent());
    }

    public function test_the_notification_carries_the_temples_own_words(): void
    {
        $announcement = Announcement::factory()->showing()->create([
            'title_hi' => 'जन्माष्टमी महोत्सव',
            'message_hi' => 'सभी ग्रामवासी आमंत्रित हैं।',
            'title_en' => 'Janmashtami',
            'message_en' => 'All villagers are invited.',
        ]);

        $body = (new AnnouncementNotification($announcement))->render();

        // Unlike Phase 7's acknowledgement, this one does carry the message —
        // it was written by a committee member, not by a stranger.
        $this->assertStringContainsString('जन्माष्टमी महोत्सव', $body);
        $this->assertStringContainsString('All villagers are invited.', $body);
    }

    public function test_the_notification_escapes_what_the_author_typed(): void
    {
        $announcement = Announcement::factory()->showing()->create([
            'message_hi' => 'सावधान <script>alert(1)</script>',
        ]);

        $body = (new AnnouncementNotification($announcement))->render();

        // The author is trusted to write the notice; they are not trusted to
        // have avoided a `<` by accident, and a mail client will interpret it.
        $this->assertStringNotContainsString('<script>', $body);
    }

    public function test_there_is_no_way_to_delete_an_announcement(): void
    {
        $announcement = Announcement::factory()->create();

        $this->deleteJson("/api/admin/announcements/{$announcement->id}")->assertStatus(405);

        $this->assertSame(1, Announcement::query()->count());
    }

    public function test_archiving_keeps_the_record_of_what_was_sent(): void
    {
        $announcement = Announcement::factory()->showing()->create();
        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])->assertOk();

        $this->postJson("/api/admin/announcements/{$announcement->id}/archive")->assertOk();

        $announcement->refresh();
        $this->assertTrue($announcement->isArchived());
        $this->assertTrue($announcement->wasSent());
        $this->assertNotNull($announcement->recipient_count);
    }
}

<?php

declare(strict_types=1);

namespace Tests\Feature\Announcements;

use App\Models\Announcement;
use App\Models\Role;
use App\Models\User;
use App\Support\AnnouncementChannel;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Who may write in the temple's name, and who may send it.
 *
 * Every case calls the API directly with the role under test. Hiding a Flutter
 * control is never the access control.
 */
class AnnouncementAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        Mail::fake();
    }

    public function test_an_anonymous_visitor_cannot_open_the_admin_list(): void
    {
        Announcement::factory()->create();

        $this->getJson('/api/admin/announcements')
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    /** @return array<string, array{string}> */
    public static function readingRoles(): array
    {
        return [
            'admin' => [Role::ADMIN],
            'content manager' => [Role::CONTENT_MANAGER],
            // content.view is enough to read, as for the calendar and the
            // gallery: a Viewer may see what the temple has announced.
            'viewer' => [Role::VIEWER],
            'treasurer' => [Role::TREASURER],
        ];
    }

    #[DataProvider('readingRoles')]
    public function test_content_view_is_enough_to_read(string $slug): void
    {
        Announcement::factory()->create();
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->getJson('/api/admin/announcements')->assertOk();
    }

    /** @return array<string, array{string}> */
    public static function refusedRoles(): array
    {
        return [
            'treasurer' => [Role::TREASURER],
            'viewer' => [Role::VIEWER],
        ];
    }

    #[DataProvider('refusedRoles')]
    public function test_writing_needs_announcements_manage(string $slug): void
    {
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->postJson('/api/admin/announcements', [
            'title_hi' => 'बिना अनुमति',
            'message_hi' => 'यह कभी सहेजा नहीं जाना चाहिए, कम से कम बीस अक्षर।',
        ])->assertStatus(403);

        $this->assertSame(0, Announcement::query()->count());
    }

    #[DataProvider('refusedRoles')]
    public function test_publishing_and_sending_need_announcements_manage(string $slug): void
    {
        $announcement = Announcement::factory()->showing()->create();
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->postJson("/api/admin/announcements/{$announcement->id}/publish")->assertStatus(403);
        $this->postJson("/api/admin/announcements/{$announcement->id}/archive")->assertStatus(403);
        $this->postJson("/api/admin/announcements/{$announcement->id}/send", [
            'channels' => [AnnouncementChannel::EMAIL],
        ])->assertStatus(403);

        Mail::assertNothingQueued();
        $this->assertFalse($announcement->refresh()->wasSent());
    }

    public function test_a_content_manager_may_write_publish_and_send(): void
    {
        $this->actingAs(User::factory()->withRole(Role::CONTENT_MANAGER)->create(), 'web');

        $id = $this->postJson('/api/admin/announcements', [
            'title_hi' => 'सूचना',
            'message_hi' => 'कल संध्या आरती एक घंटे पहले होगी।',
        ])->assertCreated()->json('data.id');

        $this->postJson("/api/admin/announcements/{$id}/publish")->assertOk();
        $this->postJson("/api/admin/announcements/{$id}/send", [
            'channels' => [AnnouncementChannel::SITE],
        ])->assertOk();
    }

    public function test_a_blocked_account_loses_the_module_even_with_the_right_role(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create([
            'status' => User::STATUS_BLOCKED,
        ]), 'web');

        $this->getJson('/api/admin/announcements')->assertStatus(403);
    }

    public function test_status_and_send_columns_cannot_be_set_by_naming_them(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        // Publishing and sending are decisions with their own endpoints, not
        // fields a payload can reach (PHASE_8_PLAN assumption N1).
        $id = $this->postJson('/api/admin/announcements', [
            'title_hi' => 'चुपके से',
            'message_hi' => 'यह मसौदा ही रहना चाहिए, चाहे पेलोड कुछ भी कहे।',
            'status' => Announcement::STATUS_PUBLISHED,
            'sent_at' => now()->toIso8601String(),
            'recipient_count' => 999,
        ])->assertCreated()->json('data.id');

        $announcement = Announcement::query()->findOrFail($id);
        $this->assertSame(Announcement::STATUS_DRAFT, $announcement->status);
        $this->assertNull($announcement->sent_at);
        $this->assertNull($announcement->recipient_count);
    }

    public function test_a_window_that_ends_before_it_starts_is_refused(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $this->postJson('/api/admin/announcements', [
            'title_hi' => 'उल्टी तारीख',
            'message_hi' => 'शुरू होने से पहले ही समाप्त, कम से कम बीस अक्षर।',
            'start_at' => now()->addDays(5)->toIso8601String(),
            'end_at' => now()->addDay()->toIso8601String(),
        ])->assertStatus(422);
    }

    public function test_a_start_date_a_decade_away_is_refused(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        // A guard against a mistyped year, which would otherwise hide a notice
        // with no error anywhere.
        $this->postJson('/api/admin/announcements', [
            'title_hi' => 'गलत वर्ष',
            'message_hi' => 'वर्ष गलत टाइप हो गया, कम से कम बीस अक्षर।',
            'start_at' => now()->addYears(10)->toIso8601String(),
        ])->assertStatus(422);
    }
}

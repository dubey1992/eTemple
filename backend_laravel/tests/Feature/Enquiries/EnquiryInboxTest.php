<?php

declare(strict_types=1);

namespace Tests\Feature\Enquiries;

use App\Models\Enquiry;
use App\Models\Role;
use App\Models\User;
use App\Support\EnquiryCategory;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The committee's inbox: what it shows, in what order, and what moving an
 * enquiry along actually writes.
 */
class EnquiryInboxTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        $this->admin = User::factory()->withRole(Role::ADMIN)->create();
        $this->actingAs($this->admin, 'web');
    }

    public function test_the_inbox_puts_unanswered_messages_first(): void
    {
        Enquiry::factory()->resolved()->create(['created_at' => now()->subMinute()]);
        Enquiry::factory()->inProgress()->create(['created_at' => now()->subHour()]);
        $newest = Enquiry::factory()->create(['created_at' => now()->subDay()]);

        $statuses = $this->getJson('/api/admin/enquiries')
            ->assertOk()
            ->json('data.*.status');

        // Oldest of the three, and still first: what needs doing outranks what
        // arrived recently.
        $this->assertSame(
            [Enquiry::STATUS_NEW, Enquiry::STATUS_IN_PROGRESS, Enquiry::STATUS_RESOLVED],
            $statuses,
        );
        $this->assertSame(
            $newest->reference,
            $this->getJson('/api/admin/enquiries')->json('data.0.reference'),
        );
    }

    public function test_spam_is_kept_but_out_of_the_way(): void
    {
        Enquiry::factory()->create();
        $junk = Enquiry::factory()->spam()->create();

        $references = $this->getJson('/api/admin/enquiries')->json('data.*.reference');
        $this->assertNotContains($junk->reference, $references);

        // Kept: asked for by name, it is still there (assumption N8).
        $this->assertContains(
            $junk->reference,
            $this->getJson('/api/admin/enquiries?status=spam')->json('data.*.reference'),
        );
        $this->assertSame(2, Enquiry::query()->count());
    }

    public function test_the_inbox_filters_by_status_category_assignee_and_text(): void
    {
        $mine = Enquiry::factory()->create([
            'category' => EnquiryCategory::COMPLAINT,
            'assigned_to' => $this->admin->id,
            'name' => 'गीता कुमारी',
        ]);
        Enquiry::factory()->create(['category' => EnquiryCategory::EVENT]);

        $this->assertSame(
            [$mine->reference],
            $this->getJson('/api/admin/enquiries?category=complaint')->json('data.*.reference'),
        );
        $this->assertSame(
            [$mine->reference],
            $this->getJson('/api/admin/enquiries?assigned_to='.$this->admin->id)->json('data.*.reference'),
        );
        $this->assertSame(
            [$mine->reference],
            $this->getJson('/api/admin/enquiries?search=गीता')->json('data.*.reference'),
        );
        $this->assertCount(
            1,
            $this->getJson('/api/admin/enquiries?assigned_to=unassigned')->json('data'),
        );
    }

    public function test_the_summary_counts_the_whole_table_not_the_page(): void
    {
        Enquiry::factory()->count(3)->create();
        Enquiry::factory()->inProgress()->create();
        Enquiry::factory()->resolved()->count(2)->create();
        Enquiry::factory()->spam()->create();

        $summary = $this->getJson('/api/admin/enquiries/summary')->assertOk()->json('data');

        $this->assertSame(
            ['new' => 3, 'in_progress' => 1, 'resolved' => 2, 'spam' => 1, 'open' => 4],
            $summary,
        );
    }

    public function test_the_summary_ignores_the_status_filter(): void
    {
        Enquiry::factory()->count(2)->create();
        Enquiry::factory()->resolved()->create();

        // A summary that honoured the tab the reader is on would tell somebody
        // looking at "resolved" that nothing is waiting.
        $summary = $this->getJson('/api/admin/enquiries/summary?status=resolved')->json('data');

        $this->assertSame(2, $summary['new']);
        $this->assertSame(1, $summary['resolved']);
    }

    public function test_resolving_stamps_when_and_by_whom_and_reopening_clears_it(): void
    {
        $enquiry = Enquiry::factory()->create();

        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'status' => Enquiry::STATUS_RESOLVED,
        ])->assertOk()->assertJsonPath('data.status', Enquiry::STATUS_RESOLVED);

        $enquiry->refresh();
        $this->assertNotNull($enquiry->resolved_at);
        $this->assertSame($this->admin->id, $enquiry->resolved_by);

        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'status' => Enquiry::STATUS_IN_PROGRESS,
        ])->assertOk();

        // The column means "when was this closed", so reopening empties it
        // rather than leaving a lie behind (assumption N7).
        $enquiry->refresh();
        $this->assertNull($enquiry->resolved_at);
        $this->assertNull($enquiry->resolved_by);
    }

    public function test_resolving_twice_keeps_the_first_closing_time(): void
    {
        $enquiry = Enquiry::factory()->create();

        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'status' => Enquiry::STATUS_RESOLVED,
        ])->assertOk();

        $first = $enquiry->refresh()->resolved_at;

        $this->travel(2)->hours();
        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'status' => Enquiry::STATUS_RESOLVED,
        ])->assertOk();

        $this->assertTrue($first->equalTo($enquiry->refresh()->resolved_at));
    }

    public function test_an_enquiry_can_only_be_assigned_to_somebody_who_can_open_the_inbox(): void
    {
        $enquiry = Enquiry::factory()->create();
        $treasurer = User::factory()->withRole(Role::TREASURER)->create();

        // A Treasurer cannot read the inbox, so assigning to one is a silent
        // black hole (assumption N11).
        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'assigned_to' => $treasurer->id,
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->assertNull($enquiry->refresh()->assigned_to);

        $contentManager = User::factory()->withRole(Role::CONTENT_MANAGER)->create();
        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'assigned_to' => $contentManager->id,
        ])->assertOk();

        $this->assertSame($contentManager->id, $enquiry->refresh()->assigned_to);
    }

    public function test_an_inactive_member_cannot_be_assigned_an_enquiry(): void
    {
        $enquiry = Enquiry::factory()->create();
        $blocked = User::factory()->withRole(Role::CONTENT_MANAGER)->create([
            'status' => User::STATUS_BLOCKED,
        ]);

        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'assigned_to' => $blocked->id,
        ])->assertStatus(422);
    }

    public function test_an_enquiry_can_be_unassigned(): void
    {
        $enquiry = Enquiry::factory()->create(['assigned_to' => $this->admin->id]);

        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'assigned_to' => null,
        ])->assertOk()->assertJsonPath('data.assigned_to', null);
    }

    public function test_there_is_no_way_to_delete_an_enquiry(): void
    {
        $enquiry = Enquiry::factory()->create();

        $this->deleteJson("/api/admin/enquiries/{$enquiry->id}")
            ->assertStatus(405);

        $this->assertSame(1, Enquiry::query()->count());
    }

    public function test_the_inbox_never_puts_the_address_hash_on_screen(): void
    {
        Enquiry::factory()->create(['submitted_ip_hash' => str_repeat('a', 64)]);

        $body = $this->getJson('/api/admin/enquiries')->getContent();

        // It exists to correlate abuse inside the database, not to be read.
        $this->assertStringNotContainsString('submitted_ip_hash', $body);
        $this->assertStringNotContainsString(str_repeat('a', 64), $body);
    }
}

<?php

declare(strict_types=1);

namespace Tests\Feature\Audit;

use App\Models\AccountingCategory;
use App\Models\Album;
use App\Models\AuditLog;
use App\Models\CommitteeMember;
use App\Models\Event;
use App\Models\Media;
use App\Models\Role;
use App\Models\User;
use App\Support\AuditAction;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The call sites Phase 11 named in its catalogue and did not reach: committee
 * members, and the four things on this site that are really destroyed rather
 * than retired.
 *
 * Phase 11 §10 listed them as outstanding. A handover that carries a list of
 * things the builder said they would do is not a handover.
 */
class AuditCoverageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function admin(): User
    {
        return User::factory()->withRole(Role::ADMIN)->create();
    }

    private function entry(string $action): AuditLog
    {
        return AuditLog::query()->where('action', $action)->latest('id')->firstOrFail();
    }

    // --- the committee -------------------------------------------------------

    public function test_adding_a_committee_member_is_recorded(): void
    {
        $this->actingAs($this->admin(), 'web')
            ->postJson('/api/admin/committee-members', [
                'name_hi' => 'रामप्रसाद यादव',
                'designation_hi' => 'कोषाध्यक्ष',
            ])
            ->assertCreated();

        $entry = $this->entry(AuditAction::COMMITTEE_MEMBER_CREATED);

        $this->assertSame('committee_members', $entry->entity_type);
        $this->assertSame('रामप्रसाद यादव', $entry->entity_label);
        $this->assertSame('कोषाध्यक्ष', $entry->after_data['designation_hi']);
        $this->assertFalse($entry->after_data['has_consent']);
    }

    /**
     * The change worth finding later.
     *
     * Not "somebody edited a member" but "somebody recorded that Ramesh agreed
     * his telephone number could be shown, and on which day".
     */
    public function test_recording_consent_is_recorded_on_both_sides(): void
    {
        $member = CommitteeMember::factory()->create();

        $this->actingAs($this->admin(), 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => $member->name_hi,
                'designation_hi' => $member->designation_hi,
                'has_consent' => true,
                'show_phone_publicly' => true,
            ])
            ->assertOk();

        $entry = $this->entry(AuditAction::COMMITTEE_MEMBER_UPDATED);

        $this->assertFalse($entry->before_data['has_consent']);
        $this->assertTrue($entry->after_data['has_consent']);
        $this->assertFalse($entry->before_data['show_phone_publicly']);
        $this->assertTrue($entry->after_data['show_phone_publicly']);
    }

    /**
     * The point of the whole snapshot design.
     *
     * A withdrawal that copies the telephone number into an append-only table
     * has withdrawn nothing: the number has simply moved somewhere only the
     * Super Admin can read, and stayed there for ever.
     */
    public function test_withdrawing_consent_does_not_copy_the_telephone_number_into_the_trail(): void
    {
        $member = CommitteeMember::factory()->consented()->create([
            'phone' => '+91 98765 43210',
            'email' => 'ramesh@example.test',
        ]);
        $member->forceFill(['show_phone_publicly' => true])->save();

        $this->actingAs($this->admin(), 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => $member->name_hi,
                'designation_hi' => $member->designation_hi,
                'has_consent' => false,
            ])
            ->assertOk();

        $entry = $this->entry(AuditAction::COMMITTEE_MEMBER_UPDATED);
        $written = json_encode($entry->toArray(), JSON_UNESCAPED_UNICODE);

        $this->assertStringNotContainsString('98765', (string) $written);
        $this->assertStringNotContainsString('ramesh@example.test', (string) $written);
        $this->assertStringNotContainsString('photo', (string) $written);

        // What it does say: the permission was taken away.
        $this->assertTrue($entry->before_data['has_consent']);
        $this->assertFalse($entry->after_data['has_consent']);
        $this->assertTrue($entry->before_data['show_phone_publicly']);
        $this->assertFalse($entry->after_data['show_phone_publicly']);
    }

    public function test_an_edit_that_changes_nothing_about_a_member_writes_no_entry(): void
    {
        $member = CommitteeMember::factory()->create();

        $this->actingAs($this->admin(), 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => $member->name_hi,
                'designation_hi' => $member->designation_hi,
            ])
            ->assertOk();

        $this->assertSame(
            0,
            AuditLog::query()->where('action', AuditAction::COMMITTEE_MEMBER_UPDATED)->count(),
        );
    }

    // --- the four things that are really destroyed ---------------------------

    public function test_deleting_an_event_is_recorded(): void
    {
        $event = Event::factory()->create(['title_hi' => 'जन्माष्टमी']);

        $this->actingAs($this->admin(), 'web')
            ->deleteJson("/api/admin/events/{$event->id}")
            ->assertNoContent();

        $entry = $this->entry(AuditAction::CONTENT_DELETED);

        $this->assertSame('events', $entry->entity_type);
        $this->assertSame('जन्माष्टमी', $entry->entity_label);
        $this->assertArrayHasKey('starts_at', $entry->before_data);
    }

    public function test_deleting_a_photograph_is_recorded_before_the_row_goes(): void
    {
        $media = Media::factory()->create(['title_hi' => 'मंदिर का द्वार']);

        $this->actingAs($this->admin(), 'web')
            ->deleteJson("/api/admin/media/{$media->id}")
            ->assertNoContent();

        $entry = $this->entry(AuditAction::CONTENT_DELETED);

        $this->assertSame('media', $entry->entity_type);
        $this->assertSame($media->id, $entry->entity_id);
        $this->assertSame('मंदिर का द्वार', $entry->entity_label);

        // The row is gone; the entry is the only thing that still names it.
        $this->assertDatabaseMissing('media', ['id' => $media->id]);
    }

    /**
     * Deleting an album destroys no photograph — it unfiles them. The count is
     * the answer to "where did the forty photographs go".
     */
    public function test_deleting_an_album_records_how_many_photographs_it_unfiled(): void
    {
        $album = Album::factory()->create(['title_hi' => 'जन्माष्टमी 2026']);
        Media::factory()->count(3)->create(['album_id' => $album->id]);

        $this->actingAs($this->admin(), 'web')
            ->deleteJson("/api/admin/albums/{$album->id}")
            ->assertNoContent();

        $entry = $this->entry(AuditAction::CONTENT_DELETED);

        $this->assertSame('albums', $entry->entity_type);
        $this->assertSame(3, $entry->before_data['photographs_unfiled']);
        $this->assertDatabaseCount('media', 3);
    }

    public function test_deleting_an_unused_accounting_heading_is_recorded(): void
    {
        $treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $category = AccountingCategory::factory()->create([
            'code' => 'lighting',
            'name_hi' => 'रोशनी',
        ]);

        $this->actingAs($treasurer, 'web')
            ->deleteJson("/api/admin/accounting-categories/{$category->id}")
            ->assertNoContent();

        $entry = $this->entry(AuditAction::CONTENT_DELETED);

        $this->assertSame('accounting_categories', $entry->entity_type);
        $this->assertSame('lighting', $entry->before_data['code']);
    }
}

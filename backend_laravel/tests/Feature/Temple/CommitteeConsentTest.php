<?php

declare(strict_types=1);

namespace Tests\Feature\Temple;

use App\Models\CommitteeMember;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The consent gate on committee members' personal details.
 *
 * These rows describe named villagers. Each of the three layers is proven
 * separately here, because a single end-to-end test would pass even if two of
 * them were removed — and the remaining one would then be the only thing
 * standing between a bug and somebody's phone number on the public internet.
 */
class CommitteeConsentTest extends TestCase
{
    use RefreshDatabase;

    private User $editor;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->editor = User::factory()->withRole(Role::ADMIN)->create();
    }

    // --- Layer 1: the service refuses to set a flag without consent ---------

    public function test_a_visibility_flag_cannot_be_set_without_recorded_consent(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/committee-members', [
                'name_hi' => 'सदस्य',
                'designation_hi' => 'सदस्य',
                'phone' => '+91 90000 00000',
                'has_consent' => false,
                'show_phone_publicly' => true,
            ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure(['error' => ['details' => ['show_phone_publicly']]]);

        $this->assertSame(0, CommitteeMember::query()->count());
    }

    public function test_each_gated_flag_is_refused_by_its_own_name(): void
    {
        foreach (array_keys(CommitteeMember::CONSENT_GATED) as $flag) {
            $this->actingAs($this->editor, 'web')
                ->postJson('/api/admin/committee-members', [
                    'name_hi' => 'सदस्य',
                    'designation_hi' => 'सदस्य',
                    $flag => true,
                ])
                ->assertStatus(422)
                ->assertJsonStructure(['error' => ['details' => [$flag]]]);
        }
    }

    public function test_recording_consent_then_setting_a_flag_is_allowed(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/committee-members', [
                'name_hi' => 'सदस्य',
                'designation_hi' => 'अध्यक्ष',
                'phone' => '+91 90000 00000',
                'has_consent' => true,
                'show_phone_publicly' => true,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.has_consent', true)
            ->assertJsonPath('data.show_phone_publicly', true);

        $member = CommitteeMember::query()->sole();
        $this->assertNotNull($member->contact_consent_at);
        $this->assertSame($this->editor->id, $member->consent_recorded_by);
    }

    public function test_the_consent_date_is_a_fact_and_is_not_refreshed_by_later_edits(): void
    {
        $member = CommitteeMember::factory()->consented()->create();
        $recordedAt = $member->contact_consent_at;

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => 'बदला हुआ नाम',
                'designation_hi' => 'अध्यक्ष',
                'has_consent' => true,
            ])
            ->assertOk();

        $this->assertTrue($recordedAt->equalTo($member->refresh()->contact_consent_at));
    }

    // --- Layer 2: withdrawal clears the flags ------------------------------

    public function test_withdrawing_consent_clears_every_visibility_flag(): void
    {
        $member = CommitteeMember::factory()->fullyPublic()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => $member->name_hi,
                'designation_hi' => $member->designation_hi,
                'has_consent' => false,
            ])
            ->assertOk()
            ->assertJsonPath('data.has_consent', false)
            ->assertJsonPath('data.show_phone_publicly', false)
            ->assertJsonPath('data.show_email_publicly', false)
            ->assertJsonPath('data.show_photo_publicly', false);

        $member->refresh();
        $this->assertNull($member->contact_consent_at);
        $this->assertNull($member->consent_recorded_by);
        $this->assertFalse($member->show_phone_publicly);
        $this->assertFalse($member->show_email_publicly);
        $this->assertFalse($member->show_photo_publicly);
    }

    public function test_withdrawing_consent_removes_the_details_from_the_public_endpoint(): void
    {
        $member = CommitteeMember::factory()->fullyPublic()->create();

        $before = $this->getJson('/api/public/committee')->assertOk();
        $this->assertArrayHasKey('phone', $before->json('data.0'));

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => $member->name_hi,
                'designation_hi' => $member->designation_hi,
                'has_consent' => false,
            ])
            ->assertOk();

        $after = $this->getJson('/api/public/committee')->assertOk();
        $this->assertArrayNotHasKey('phone', $after->json('data.0'));
        $this->assertStringNotContainsString('90000', $after->getContent() ?: '');
    }

    // --- Layer 3: the serializer checks again ------------------------------

    public function test_the_public_resource_ignores_a_flag_left_set_without_consent(): void
    {
        // Force the database into the state the service refuses to create, which
        // is what a future bug or a direct SQL edit would look like. The public
        // endpoint must still withhold the detail.
        $member = CommitteeMember::factory()->published()->create();
        $member->forceFill([
            'contact_consent_at' => null,
            'show_phone_publicly' => true,
            'show_email_publicly' => true,
            'show_photo_publicly' => true,
        ])->save();

        $response = $this->getJson('/api/public/committee')->assertOk();

        $this->assertArrayNotHasKey('phone', $response->json('data.0'));
        $this->assertArrayNotHasKey('email', $response->json('data.0'));
        $this->assertArrayNotHasKey('photo_url', $response->json('data.0'));
        $this->assertStringNotContainsString('90000', $response->getContent() ?: '');
        $this->assertStringNotContainsString('member@example.test', $response->getContent() ?: '');
    }

    public function test_a_detail_that_may_not_be_published_is_absent_not_null(): void
    {
        CommitteeMember::factory()->published()->consented()->create([
            'show_phone_publicly' => false,
        ]);

        $member = $this->getJson('/api/public/committee')->assertOk()->json('data.0');

        // Absent, not "phone": null — an absent key cannot be rendered by
        // accident or misread as "unknown, ask again".
        $this->assertArrayNotHasKey('phone', $member);
        $this->assertArrayHasKey('name', $member);
    }

    public function test_consent_alone_does_not_publish_anything(): void
    {
        // Consent recorded but no flag chosen: the committee said "you may",
        // not "please do".
        CommitteeMember::factory()->published()->consented()->create();

        $member = $this->getJson('/api/public/committee')->assertOk()->json('data.0');

        $this->assertArrayNotHasKey('phone', $member);
        $this->assertArrayNotHasKey('email', $member);
        $this->assertArrayNotHasKey('photo_url', $member);
    }

    public function test_each_detail_is_gated_independently(): void
    {
        CommitteeMember::factory()->published()->consented()->create([
            'show_phone_publicly' => true,
            'show_email_publicly' => false,
            'show_photo_publicly' => false,
        ]);

        $member = $this->getJson('/api/public/committee')->assertOk()->json('data.0');

        $this->assertSame('+91 90000 00000', $member['phone']);
        $this->assertArrayNotHasKey('email', $member);
        $this->assertArrayNotHasKey('photo_url', $member);
    }

    public function test_an_unpublished_member_never_appears_however_consented(): void
    {
        CommitteeMember::factory()->fullyPublic()->create(['is_published' => false]);

        $this->getJson('/api/public/committee')
            ->assertOk()
            ->assertJsonPath('data', []);
    }
}

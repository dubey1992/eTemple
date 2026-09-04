<?php

declare(strict_types=1);

namespace Tests\Feature\Temple;

use App\Models\CommitteeMember;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CommitteeManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $editor;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->editor = User::factory()->withRole(Role::ADMIN)->create();
    }

    public function test_the_public_list_is_empty_on_a_fresh_site(): void
    {
        $this->getJson('/api/public/committee')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', []);
    }

    public function test_the_public_list_shows_published_serving_members_in_order(): void
    {
        CommitteeMember::factory()->published()->create(['name_hi' => 'दूसरा', 'sort_order' => 2]);
        CommitteeMember::factory()->published()->create(['name_hi' => 'पहला', 'sort_order' => 1]);

        $names = $this->getJson('/api/public/committee')->assertOk()->json('data.*.name.value');

        $this->assertSame(['पहला', 'दूसरा'], $names);
    }

    public function test_an_unpublished_member_is_not_reachable_publicly(): void
    {
        CommitteeMember::factory()->create(['name_hi' => 'गुप्त सदस्य']);

        $response = $this->getJson('/api/public/committee')->assertOk();

        $this->assertSame([], $response->json('data'));
        $this->assertStringNotContainsString('गुप्त', $response->getContent() ?: '');
    }

    public function test_a_member_whose_tenure_ended_drops_off_the_public_list(): void
    {
        CommitteeMember::factory()->pastMember()->create(['name_hi' => 'पूर्व अध्यक्ष']);
        CommitteeMember::factory()->published()->create(['name_hi' => 'वर्तमान अध्यक्ष']);

        $names = $this->getJson('/api/public/committee')->assertOk()->json('data.*.name.value');

        $this->assertSame(['वर्तमान अध्यक्ष'], $names);
    }

    public function test_a_tenure_ending_today_is_still_serving(): void
    {
        CommitteeMember::factory()->published()->create([
            'name_hi' => 'आज तक',
            'tenure_end' => today()->toDateString(),
        ]);

        $this->getJson('/api/public/committee')
            ->assertOk()
            ->assertJsonPath('data.0.name.value', 'आज तक');
    }

    public function test_a_past_member_is_kept_as_history_for_the_committee(): void
    {
        CommitteeMember::factory()->pastMember()->create(['name_hi' => 'पूर्व अध्यक्ष']);

        // Retired from the public site, still on the admin list: committee
        // membership is village history and is not lost when a term ends.
        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/committee-members')
            ->assertOk()
            ->assertJsonPath('data.0.name_hi', 'पूर्व अध्यक्ष')
            ->assertJsonPath('data.0.tenure_has_ended', true);
    }

    public function test_the_committee_list_is_resolved_for_the_requested_language(): void
    {
        CommitteeMember::factory()->published()->create();

        $this->getJson('/api/public/committee?lang=en')
            ->assertOk()
            ->assertJsonPath('data.0.name.value', 'Test Member')
            ->assertJsonPath('data.0.designation.value', 'President')
            ->assertJsonPath('data.0.name.fallback_used', false);
    }

    public function test_a_member_without_english_falls_back_to_hindi_and_says_so(): void
    {
        CommitteeMember::factory()->published()->hindiOnly()->create();

        $this->getJson('/api/public/committee?lang=en')
            ->assertOk()
            ->assertJsonPath('data.0.name.value', 'परीक्षण सदस्य')
            ->assertJsonPath('data.0.name.language', 'hi')
            ->assertJsonPath('data.0.name.fallback_used', true);
    }

    public function test_an_editor_can_create_a_member(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/committee-members', [
                'name_hi' => 'राम प्रसाद',
                'name_en' => 'Ram Prasad',
                'designation_hi' => 'सचिव',
                'designation_en' => 'Secretary',
                'tenure_start' => '2024-04-01',
                'is_published' => true,
                'sort_order' => 3,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.name_hi', 'राम प्रसाद')
            ->assertJsonPath('data.is_published', true);

        $member = CommitteeMember::query()->sole();
        $this->assertSame($this->editor->id, $member->created_by);
        $this->assertSame($this->editor->id, $member->updated_by);
    }

    public function test_a_new_member_is_unpublished_and_unconsented_by_default(): void
    {
        // Publishing a person is a decision somebody has to make on purpose.
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/committee-members', [
                'name_hi' => 'नया सदस्य',
                'designation_hi' => 'सदस्य',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.is_published', false)
            ->assertJsonPath('data.has_consent', false);
    }

    public function test_hindi_name_and_designation_are_required(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/committee-members', ['name_en' => 'English only'])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['name_hi', 'designation_hi']]]);
    }

    public function test_a_tenure_cannot_end_before_it_starts(): void
    {
        $this->actingAs($this->editor, 'web')
            ->postJson('/api/admin/committee-members', [
                'name_hi' => 'सदस्य',
                'designation_hi' => 'सदस्य',
                'tenure_start' => '2025-01-01',
                'tenure_end' => '2024-01-01',
            ])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['tenure_end']]]);
    }

    public function test_an_editor_can_update_a_member(): void
    {
        $member = CommitteeMember::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->putJson("/api/admin/committee-members/{$member->id}", [
                'name_hi' => 'सुधारा हुआ नाम',
                'designation_hi' => 'कोषाध्यक्ष',
                'is_published' => true,
            ])
            ->assertOk()
            ->assertJsonPath('data.name_hi', 'सुधारा हुआ नाम')
            ->assertJsonPath('data.designation_hi', 'कोषाध्यक्ष');
    }

    public function test_an_editor_can_delete_a_member(): void
    {
        $member = CommitteeMember::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->deleteJson("/api/admin/committee-members/{$member->id}")
            ->assertNoContent();

        $this->assertSame(0, CommitteeMember::query()->count());
    }

    public function test_an_unknown_member_is_a_404(): void
    {
        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/committee-members/9999')
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_the_admin_list_carries_personal_details_and_the_consent_record(): void
    {
        // Consent governs publication, not administration: an editor working on
        // the record has to be able to see the phone number they are deciding
        // about.
        CommitteeMember::factory()->consented()->create();

        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/committee-members')
            ->assertOk()
            ->assertJsonPath('data.0.phone', '+91 90000 00000')
            ->assertJsonPath('data.0.has_consent', true)
            ->assertJsonPath('data.0.show_phone_publicly', false);
    }
}

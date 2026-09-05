<?php

declare(strict_types=1);

namespace Tests\Feature\Temple;

use App\Models\Role;
use App\Models\SiteSetting;
use App\Models\TempleProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TempleProfileTest extends TestCase
{
    use RefreshDatabase;

    private User $editor;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->editor = User::factory()->withRole(Role::ADMIN)->create();
    }

    public function test_the_public_endpoint_works_on_a_freshly_installed_site(): void
    {
        // Nothing configured yet. The specification forbids shipping invented
        // temple content, so an empty profile is the correct initial state and
        // must answer with empty values rather than an error.
        $this->getJson('/api/public/temple-profile')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name.value', null)
            ->assertJsonPath('data.history.value', null)
            ->assertJsonPath('data.address.village', null);

        $this->assertSame(1, TempleProfile::query()->count());
    }

    public function test_repeated_reads_do_not_create_extra_singleton_rows(): void
    {
        $this->getJson('/api/public/temple-profile')->assertOk();
        $this->getJson('/api/public/temple-profile')->assertOk();
        $this->actingAs($this->editor, 'web')->getJson('/api/admin/temple-profile')->assertOk();

        $this->assertSame(1, TempleProfile::query()->count());
    }

    public function test_the_profile_is_resolved_for_the_requested_language(): void
    {
        TempleProfile::factory()->create();

        $this->getJson('/api/public/temple-profile?lang=en')
            ->assertOk()
            ->assertJsonPath('data.name.value', 'Test Temple')
            ->assertJsonPath('data.name.language', 'en')
            ->assertJsonPath('data.name.fallback_used', false);

        $this->getJson('/api/public/temple-profile')
            ->assertOk()
            ->assertJsonPath('data.name.value', 'परीक्षण मंदिर')
            ->assertJsonPath('data.name.language', 'hi');
    }

    public function test_a_missing_english_name_falls_back_to_hindi_and_says_so(): void
    {
        TempleProfile::factory()->hindiOnly()->create();

        $this->getJson('/api/public/temple-profile?lang=en')
            ->assertOk()
            ->assertJsonPath('data.name.value', 'परीक्षण मंदिर')
            ->assertJsonPath('data.name.language', 'hi')
            ->assertJsonPath('data.name.fallback_used', true);
    }

    public function test_the_public_endpoint_needs_no_authentication(): void
    {
        TempleProfile::factory()->create();

        $this->getJson('/api/public/temple-profile')->assertOk();
    }

    public function test_the_address_is_served_from_the_profile_not_from_site_settings(): void
    {
        TempleProfile::factory()->create([
            'village_hi' => 'अमरपुर पंखोरिया',
            'village_en' => 'Amarpur Pankhoriya',
        ]);
        SiteSetting::factory()->create();

        // The public address arrives resolved for the requested language, so a
        // Hindi page never shows the Roman spelling of the village.
        $this->getJson('/api/public/temple-profile')
            ->assertOk()
            ->assertJsonPath('data.address.village', 'अमरपुर पंखोरिया');

        $this->getJson('/api/public/temple-profile?lang=en')
            ->assertOk()
            ->assertJsonPath('data.address.village', 'Amarpur Pankhoriya');

        // The address moved; site settings must not carry a second copy of it.
        $settings = $this->getJson('/api/public/site-settings')->assertOk();
        $this->assertArrayNotHasKey('village_hi', $settings->json('data.contact'));
        $this->assertArrayNotHasKey('address_line1', $settings->json('data.contact'));
        $this->assertArrayNotHasKey('map_url', $settings->json('data.contact'));
    }

    public function test_an_editor_reads_both_languages_raw(): void
    {
        TempleProfile::factory()->create();

        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/temple-profile')
            ->assertOk()
            ->assertJsonPath('data.name_hi', 'परीक्षण मंदिर')
            ->assertJsonPath('data.name_en', 'Test Temple');
    }

    public function test_an_editor_can_update_the_profile(): void
    {
        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/temple-profile', [
                'name_hi' => 'राधा कृष्ण ठाकुरबाड़ी',
                'name_en' => 'Radha Krishna Thakurbari',
                'village_hi' => 'अमरपुर पंखोरिया',
                'village_en' => 'Amarpur Pankhoriya',
                'district_hi' => 'भागलपुर',
                'established_year' => 1965,
            ])
            ->assertOk()
            ->assertJsonPath('data.name_hi', 'राधा कृष्ण ठाकुरबाड़ी')
            ->assertJsonPath('data.village_hi', 'अमरपुर पंखोरिया')
            ->assertJsonPath('data.village_en', 'Amarpur Pankhoriya')
            ->assertJsonPath('data.established_year', 1965);

        $profile = TempleProfile::query()->sole();
        $this->assertSame($this->editor->id, $profile->updated_by);
    }

    public function test_a_half_configured_profile_still_saves(): void
    {
        // The committee usually has the address before they have agreed the
        // wording of the history, so no field may be mandatory.
        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/temple-profile', ['village_hi' => 'अमरपुर पंखोरिया'])
            ->assertOk()
            ->assertJsonPath('data.name_hi', null)
            ->assertJsonPath('data.village_hi', 'अमरपुर पंखोरिया');
    }

    public function test_invalid_profile_input_is_rejected_by_field(): void
    {
        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/temple-profile', [
                'logo_url' => 'not a url',
                'map_url' => 'also not a url',
                'established_year' => 3000,
            ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure([
                'error' => ['details' => ['logo_url', 'map_url', 'established_year']],
            ]);
    }
}

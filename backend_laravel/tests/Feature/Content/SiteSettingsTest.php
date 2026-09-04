<?php

declare(strict_types=1);

namespace Tests\Feature\Content;

use App\Models\NavigationItem;
use App\Models\Role;
use App\Models\SiteSetting;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SiteSettingsTest extends TestCase
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
        // Nothing configured yet: the site must answer with empty values rather
        // than an error, so the UI can show its empty states.
        $this->getJson('/api/public/site-settings')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.tagline.value', null)
            ->assertJsonPath('data.navigation', []);

        $this->assertSame(1, SiteSetting::query()->count());
    }

    public function test_repeated_reads_do_not_create_extra_singleton_rows(): void
    {
        $this->getJson('/api/public/site-settings')->assertOk();
        $this->getJson('/api/public/site-settings')->assertOk();
        $this->getJson('/api/admin/site-settings');

        $this->assertSame(1, SiteSetting::query()->count());
    }

    public function test_settings_are_resolved_for_the_requested_language(): void
    {
        SiteSetting::factory()->create();

        $this->getJson('/api/public/site-settings?lang=en')
            ->assertOk()
            ->assertJsonPath('data.tagline.value', 'A place of devotion and service')
            ->assertJsonPath('data.tagline.fallback_used', false);

        $this->getJson('/api/public/site-settings')
            ->assertOk()
            ->assertJsonPath('data.tagline.value', 'भक्ति और सेवा का केंद्र');
    }

    public function test_a_missing_english_tagline_falls_back_to_hindi(): void
    {
        SiteSetting::factory()->create(['tagline_en' => null]);

        $this->getJson('/api/public/site-settings?lang=en')
            ->assertOk()
            ->assertJsonPath('data.tagline.language', 'hi')
            ->assertJsonPath('data.tagline.fallback_used', true);
    }

    public function test_the_public_menu_is_ordered_and_hides_invisible_items(): void
    {
        NavigationItem::factory()->create(['label_hi' => 'दूसरा', 'route' => '/b', 'sort_order' => 2]);
        NavigationItem::factory()->create(['label_hi' => 'पहला', 'route' => '/a', 'sort_order' => 1]);
        NavigationItem::factory()->hidden()->create(['label_hi' => 'छिपा', 'route' => '/hidden']);

        $response = $this->getJson('/api/public/site-settings')->assertOk();

        $this->assertSame(['पहला', 'दूसरा'], array_column($response->json('data.navigation'), 'label.value')
            ?: array_map(static fn ($i) => $i['label']['value'], $response->json('data.navigation')));
        $this->assertStringNotContainsString('छिपा', $response->getContent() ?: '');
    }

    public function test_the_admin_view_includes_hidden_items_and_both_languages(): void
    {
        NavigationItem::factory()->hidden()->create(['label_hi' => 'छिपा', 'route' => '/hidden']);

        $this->actingAs($this->editor, 'web')
            ->getJson('/api/admin/site-settings')
            ->assertOk()
            ->assertJsonPath('data.navigation.0.label_hi', 'छिपा')
            ->assertJsonPath('data.navigation.0.is_visible', false);
    }

    public function test_an_editor_can_update_settings_and_replace_the_menu(): void
    {
        NavigationItem::factory()->create(['label_hi' => 'पुराना', 'route' => '/old']);

        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/site-settings', [
                'tagline_hi' => 'नई पंक्ति',
                'village' => 'Amarpur Pankhoriya',
                'contact_email' => 'committee@thakurbari.in',
                'navigation' => [
                    ['label_hi' => 'मुख पृष्ठ', 'label_en' => 'Home', 'route' => '/', 'sort_order' => 0],
                    ['label_hi' => 'हमारे बारे में', 'route' => '/about', 'sort_order' => 1],
                ],
            ])
            ->assertOk()
            ->assertJsonPath('data.tagline_hi', 'नई पंक्ति')
            ->assertJsonCount(2, 'data.navigation');

        // Replacement, not merge: the old entry is gone.
        $this->assertSame(2, NavigationItem::query()->count());
        $this->assertSame(0, NavigationItem::query()->where('route', '/old')->count());
    }

    public function test_settings_can_be_updated_without_touching_the_menu(): void
    {
        NavigationItem::factory()->create(['route' => '/keep']);

        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/site-settings', ['tagline_hi' => 'केवल पंक्ति'])
            ->assertOk();

        $this->assertSame(1, NavigationItem::query()->where('route', '/keep')->count());
    }

    public function test_invalid_settings_are_rejected(): void
    {
        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/site-settings', [
                'contact_email' => 'not-an-email',
                'map_url' => 'not a url',
                'navigation' => [['label_en' => 'missing hindi label']],
            ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure([
                'error' => ['details' => ['contact_email', 'map_url', 'navigation.0.label_hi']],
            ]);
    }

    public function test_a_failed_menu_replacement_leaves_the_old_menu_intact(): void
    {
        NavigationItem::factory()->create(['route' => '/original']);

        $this->actingAs($this->editor, 'web')
            ->putJson('/api/admin/site-settings', [
                'navigation' => [['label_hi' => 'ठीक', 'route' => '/ok'], ['route' => '/broken']],
            ])
            ->assertStatus(422);

        $this->assertSame(1, NavigationItem::query()->count());
        $this->assertSame('/original', NavigationItem::query()->value('route'));
    }
}

<?php

declare(strict_types=1);

namespace Tests\Feature\Content;

use App\Models\Page;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * GET /api/public/pages/{slug} — the visitor-facing content endpoint.
 */
class PublicPageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_a_published_page_is_served_in_hindi_by_default(): void
    {
        Page::factory()->published()->create(['slug' => 'about']);

        $this->getJson('/api/public/pages/about')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.slug', 'about')
            ->assertJsonPath('data.requested_language', 'hi')
            ->assertJsonPath('data.title.value', 'हिन्दी शीर्षक')
            ->assertJsonPath('data.title.language', 'hi')
            ->assertJsonPath('data.title.fallback_used', false);
    }

    public function test_english_is_served_when_requested_and_present(): void
    {
        Page::factory()->published()->create(['slug' => 'about']);

        $this->getJson('/api/public/pages/about?lang=en')
            ->assertOk()
            ->assertJsonPath('data.requested_language', 'en')
            ->assertJsonPath('data.title.value', 'English title')
            ->assertJsonPath('data.title.language', 'en')
            ->assertJsonPath('data.title.fallback_used', false);
    }

    public function test_missing_english_falls_back_to_hindi_and_says_so(): void
    {
        Page::factory()->published()->hindiOnly()->create(['slug' => 'about']);

        $this->getJson('/api/public/pages/about?lang=en')
            ->assertOk()
            ->assertJsonPath('data.requested_language', 'en')
            ->assertJsonPath('data.content.value', 'हिन्दी सामग्री का एक अनुच्छेद।')
            ->assertJsonPath('data.content.language', 'hi')
            // The whole point of the rule: the client is told, not misled.
            ->assertJsonPath('data.content.fallback_used', true);
    }

    public function test_a_blank_english_value_counts_as_missing(): void
    {
        Page::factory()->published()->create(['slug' => 'about', 'content_en' => '   ']);

        $this->getJson('/api/public/pages/about?lang=en')
            ->assertOk()
            ->assertJsonPath('data.content.language', 'hi')
            ->assertJsonPath('data.content.fallback_used', true);
    }

    public function test_an_unrecognised_language_falls_back_to_hindi(): void
    {
        Page::factory()->published()->create(['slug' => 'about']);

        $this->getJson('/api/public/pages/about?lang=fr')
            ->assertOk()
            ->assertJsonPath('data.requested_language', 'hi')
            ->assertJsonPath('data.title.value', 'हिन्दी शीर्षक');
    }

    public function test_a_draft_page_is_not_reachable_publicly(): void
    {
        Page::factory()->create(['slug' => 'secret-draft']);

        $this->getJson('/api/public/pages/secret-draft')
            ->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_a_draft_is_indistinguishable_from_a_missing_page(): void
    {
        Page::factory()->create(['slug' => 'secret-draft']);

        $draft = $this->getJson('/api/public/pages/secret-draft');
        $missing = $this->getJson('/api/public/pages/no-such-page');

        $this->assertSame($draft->getStatusCode(), $missing->getStatusCode());
        $this->assertSame($draft->json('error.code'), $missing->json('error.code'));
    }

    public function test_draft_content_never_appears_in_the_response_body(): void
    {
        Page::factory()->create([
            'slug' => 'secret-draft',
            'content_hi' => 'गोपनीय मसौदा सामग्री',
        ]);

        $response = $this->getJson('/api/public/pages/secret-draft');

        $this->assertResponseDoesNotLeak($response, 'गोपनीय');
    }

    public function test_the_public_endpoint_needs_no_authentication(): void
    {
        Page::factory()->published()->create(['slug' => 'about']);

        $this->assertGuest();
        $this->getJson('/api/public/pages/about')->assertOk();
    }

    public function test_metadata_is_returned_for_seo(): void
    {
        Page::factory()->published()->create([
            'slug' => 'about',
            'meta_title_hi' => 'मेटा शीर्षक',
            'meta_description_hi' => 'मेटा विवरण',
        ]);

        $this->getJson('/api/public/pages/about')
            ->assertOk()
            ->assertJsonPath('data.meta_title.value', 'मेटा शीर्षक')
            ->assertJsonPath('data.meta_description.value', 'मेटा विवरण');
    }
}

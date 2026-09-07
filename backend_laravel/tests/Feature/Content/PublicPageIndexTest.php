<?php

declare(strict_types=1);

namespace Tests\Feature\Content;

use App\Models\Page;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * GET /api/public/pages — which pages exist.
 *
 * Added because the home page asked for the `about` slug on every visit and
 * took a 404 whenever nobody had written one. The visitor saw a correct empty
 * state, so nothing looked broken, but every page load logged a failed request
 * in the browser console.
 */
class PublicPageIndexTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_lists_published_pages(): void
    {
        Page::factory()->create([
            'slug' => 'about',
            'title_hi' => 'मंदिर परिचय',
            'status' => Page::STATUS_PUBLISHED,
        ]);

        $this->getJson('/api/public/pages')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.slug', 'about')
            ->assertJsonPath('data.0.title.value', 'मंदिर परिचय');
    }

    public function test_a_draft_is_not_listed(): void
    {
        Page::factory()->create(['slug' => 'draft-page', 'status' => Page::STATUS_DRAFT]);

        $response = $this->getJson('/api/public/pages')->assertOk();

        // Listing must not reveal a page that fetching would refuse: the two
        // have to agree, or the index becomes a way to enumerate drafts.
        $this->assertResponseDoesNotLeak($response, 'draft-page');
        $this->getJson('/api/public/pages/draft-page')->assertNotFound();
    }

    public function test_an_empty_site_returns_an_empty_list_not_an_error(): void
    {
        $this->getJson('/api/public/pages')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', []);
    }

    public function test_the_index_carries_no_page_content(): void
    {
        Page::factory()->create([
            'slug' => 'about',
            'content_hi' => 'यह पूरा पाठ है जो सूची में नहीं आना चाहिए।',
            'status' => Page::STATUS_PUBLISHED,
        ]);

        // The home page fetches this list. Shipping every page's full text to
        // answer "which pages exist" grows without limit as the committee writes.
        $this->assertResponseDoesNotLeak(
            $this->getJson('/api/public/pages')->assertOk(),
            'यह पूरा पाठ है जो सूची में नहीं आना चाहिए।',
        );
    }

    public function test_it_needs_no_authentication(): void
    {
        $this->getJson('/api/public/pages')->assertOk();
    }
}

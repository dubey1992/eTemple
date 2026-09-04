<?php

declare(strict_types=1);

namespace Tests\Feature\Media;

use App\Models\Album;
use App\Models\Media;
use App\Services\Media\MediaService;
use App\Support\MediaType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * The public gallery: what a visitor may see, in which order, and never more
 * than a page at a time.
 */
class MediaPublicTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        config()->set('media.disk', 'public');
    }

    public function test_the_gallery_needs_no_authentication(): void
    {
        $this->getJson('/api/public/media')->assertOk();
    }

    public function test_only_published_items_appear(): void
    {
        Media::factory()->published()->create(['title_hi' => 'प्रकाशित चित्र']);
        Media::factory()->create(['title_hi' => 'मसौदा चित्र']);

        $response = $this->getJson('/api/public/media')->assertOk();

        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.title.value', 'प्रकाशित चित्र');
    }

    public function test_a_draft_is_indistinguishable_from_an_item_that_does_not_exist(): void
    {
        $draft = Media::factory()->create();

        // Same 404 as an unknown id: the filter is in the query, so there is no
        // presentation mistake that could leak one.
        $this->getJson("/api/public/media/{$draft->id}")->assertNotFound();
        $this->getJson('/api/public/media/999999')->assertNotFound();
    }

    public function test_every_image_size_is_offered_so_the_client_can_choose(): void
    {
        $media = Media::factory()->published()->create();

        $response = $this->getJson("/api/public/media/{$media->id}")->assertOk();

        // A grid tile takes `thumb` and a lightbox takes `large`; sending one
        // size only would mean a grid that downloads full photographs or a
        // lightbox that shows blurred ones.
        $this->assertStringContainsString('-sm.jpg', $response->json('data.thumb_url'));
        $this->assertStringContainsString('-md.jpg', $response->json('data.medium_url'));
        $this->assertStringContainsString('-lg.jpg', $response->json('data.large_url'));
    }

    public function test_a_small_photograph_falls_back_to_the_size_it_has(): void
    {
        // Nothing is ever upscaled, so the smaller variants resolve to the one
        // stored file rather than to null (assumption M4).
        $media = Media::factory()->published()->singleVariant()->create();

        $response = $this->getJson("/api/public/media/{$media->id}")->assertOk();

        $this->assertStringContainsString('-lg.jpg', $response->json('data.thumb_url'));
        $this->assertStringContainsString('-lg.jpg', $response->json('data.medium_url'));
    }

    public function test_a_video_carries_an_embed_url_built_from_the_stored_id(): void
    {
        Media::factory()->published()->video('abcdefghijk')->create();

        $response = $this->getJson('/api/public/media?type='.MediaType::VIDEO)->assertOk();

        $response->assertJsonPath('data.0.media_type', MediaType::VIDEO);
        $response->assertJsonPath(
            'data.0.embed_url',
            'https://www.youtube-nocookie.com/embed/abcdefghijk',
        );
    }

    public function test_a_photograph_has_no_embed_url(): void
    {
        $media = Media::factory()->published()->create();

        $this->getJson("/api/public/media/{$media->id}")
            ->assertOk()
            ->assertJsonPath('data.embed_url', null);
    }

    public function test_the_type_filter_separates_photographs_from_videos(): void
    {
        Media::factory()->published()->count(2)->create();
        Media::factory()->published()->video()->create();

        $this->getJson('/api/public/media?type='.MediaType::PHOTO)
            ->assertOk()->assertJsonCount(2, 'data');

        $this->getJson('/api/public/media?type='.MediaType::VIDEO)
            ->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_an_unknown_type_filter_is_ignored_rather_than_failing(): void
    {
        Media::factory()->published()->count(2)->create();

        $this->getJson('/api/public/media?type=nonsense')
            ->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_the_committee_arrangement_decides_the_order(): void
    {
        Media::factory()->published()->create(['title_hi' => 'तीसरा', 'sort_order' => 3]);
        Media::factory()->published()->create(['title_hi' => 'पहला', 'sort_order' => 1]);
        Media::factory()->published()->create(['title_hi' => 'दूसरा', 'sort_order' => 2]);

        $response = $this->getJson('/api/public/media')->assertOk();

        $this->assertSame(
            ['पहला', 'दूसरा', 'तीसरा'],
            array_column(array_column($response->json('data'), 'title'), 'value'),
        );
    }

    public function test_the_gallery_is_paginated(): void
    {
        Media::factory()->published()->count(30)->create();

        $response = $this->getJson('/api/public/media?per_page=10')->assertOk();

        $response->assertJsonCount(10, 'data');
        $response->assertJsonPath('meta.total', 30);
        $response->assertJsonPath('meta.per_page', 10);
        $response->assertJsonPath('meta.last_page', 3);
        $response->assertJsonPath('meta.has_more', true);

        $this->getJson('/api/public/media?per_page=10&page=3')
            ->assertOk()
            ->assertJsonPath('meta.has_more', false);
    }

    public function test_an_oversized_page_request_is_capped(): void
    {
        // An unbounded gallery response is a denial-of-service against our own
        // API, and worse here because every row carries three URLs.
        Media::factory()->published()->count(70)->create();

        $this->getJson('/api/public/media?per_page=5000')
            ->assertOk()
            ->assertJsonPath('meta.per_page', MediaService::MAX_PER_PAGE)
            ->assertJsonCount(MediaService::MAX_PER_PAGE, 'data');
    }

    public function test_the_album_filter_uses_the_shareable_slug(): void
    {
        $album = Album::factory()->published()->create(['slug' => 'janmashtami-2026']);
        Media::factory()->published()->count(2)->create(['album_id' => $album->id]);
        Media::factory()->published()->create();

        $this->getJson('/api/public/media?album=janmashtami-2026')
            ->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_an_unpublished_album_shows_nothing_even_when_its_photographs_are_published(): void
    {
        // The album is the arrangement the committee has not finished, so the
        // arrangement is what stays private.
        $album = Album::factory()->create(['slug' => 'unfinished']);
        Media::factory()->published()->count(2)->create(['album_id' => $album->id]);

        $this->getJson('/api/public/media?album=unfinished')
            ->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_albums_list_only_published_ones_with_their_public_counts(): void
    {
        $album = Album::factory()->published()->create(['title_hi' => 'जन्माष्टमी']);
        Album::factory()->create(['title_hi' => 'छिपा हुआ']);

        Media::factory()->published()->count(2)->create(['album_id' => $album->id]);
        Media::factory()->create(['album_id' => $album->id]);

        $response = $this->getJson('/api/public/albums')->assertOk();

        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.title.value', 'जन्माष्टमी');
        // Two published, one draft: a visitor is told what they can look at.
        $response->assertJsonPath('data.0.media_count', 2);
    }

    public function test_english_falls_back_to_hindi_and_says_so(): void
    {
        Media::factory()->published()->hindiOnly()->create(['title_hi' => 'मंदिर प्रांगण']);

        $response = $this->getJson('/api/public/media?lang=en')->assertOk();

        $response->assertJsonPath('data.0.title.value', 'मंदिर प्रांगण');
        $response->assertJsonPath('data.0.title.language', 'hi');
        $response->assertJsonPath('data.0.title.fallback_used', true);
    }

    public function test_english_is_used_when_it_exists(): void
    {
        Media::factory()->published()->create([
            'title_hi' => 'मंदिर प्रांगण',
            'title_en' => 'Temple courtyard',
        ]);

        $response = $this->getJson('/api/public/media?lang=en')->assertOk();

        $response->assertJsonPath('data.0.title.value', 'Temple courtyard');
        $response->assertJsonPath('data.0.title.fallback_used', false);
    }

    public function test_hindi_is_the_default_language(): void
    {
        Media::factory()->published()->create([
            'title_hi' => 'मंदिर प्रांगण',
            'title_en' => 'Temple courtyard',
        ]);

        $this->getJson('/api/public/media')
            ->assertOk()
            ->assertJsonPath('data.0.requested_language', 'hi')
            ->assertJsonPath('data.0.title.value', 'मंदिर प्रांगण');
    }

    public function test_the_public_payload_carries_no_administrative_detail(): void
    {
        $media = Media::factory()->published()->create();

        $data = $this->getJson("/api/public/media/{$media->id}")->assertOk()->json('data');

        // Who uploaded it, what it was called on their phone and what it weighs
        // are internal facts; a visitor is shown the photograph.
        foreach (['status', 'original_name', 'checksum', 'uploaded_by', 'byte_size'] as $key) {
            $this->assertArrayNotHasKey($key, $data);
        }
    }
}

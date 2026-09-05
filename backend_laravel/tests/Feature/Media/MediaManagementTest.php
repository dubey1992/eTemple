<?php

declare(strict_types=1);

namespace Tests\Feature\Media;

use App\Models\Album;
use App\Models\CommitteeMember;
use App\Models\DonationSetting;
use App\Models\Event;
use App\Models\Media;
use App\Models\Page;
use App\Models\Role;
use App\Models\TempleProfile;
use App\Models\User;
use App\Support\MediaType;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The library as an editor uses it: uploading, linking, arranging — and the
 * deletion guard, which is the rule this phase exists to enforce.
 */
class MediaManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        if (! extension_loaded('gd')) {
            $this->markTestSkipped('GD is required to process images.');
        }

        Storage::fake('public');
        config()->set('media.disk', 'public');

        $this->seed(RoleSeeder::class);
        $this->actingAs(User::factory()->withRole(Role::CONTENT_MANAGER)->create(), 'web');
    }

    /** A real JPEG, because the upload endpoint really processes it. */
    private function photograph(int $width = 1400, int $height = 900): UploadedFile
    {
        $image = imagecreatetruecolor($width, $height);
        imagefilledrectangle($image, 0, 0, $width, $height, (int) imagecolorallocate($image, 180, 60, 90));

        ob_start();
        imagejpeg($image, null, 88);
        $bytes = (string) ob_get_clean();
        imagedestroy($image);

        $path = tempnam(sys_get_temp_dir(), 'rkt').'.jpg';
        file_put_contents($path, $bytes);

        return new UploadedFile($path, 'aarti.jpg', 'image/jpeg', null, true);
    }

    // --- uploading ---------------------------------------------------------

    public function test_a_photograph_is_uploaded_stored_and_recorded(): void
    {
        $response = $this->post('/api/admin/media', [
            'file' => $this->photograph(),
            'title_hi' => 'संध्या आरती',
            'title_en' => 'Evening aarti',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(201);

        $media = Media::query()->firstOrFail();

        $this->assertSame(MediaType::PHOTO, $media->media_type);
        $this->assertSame('image/jpeg', $media->mime_type);
        $this->assertSame(1400, $media->width);
        $this->assertSame('aarti.jpg', $media->original_name);
        $this->assertNotNull($media->checksum);

        foreach ($media->storedPaths() as $path) {
            Storage::disk('public')->assertExists($path);
        }

        $response->assertJsonPath('data.title_hi', 'संध्या आरती');
    }

    public function test_the_uploader_is_recorded(): void
    {
        $this->post('/api/admin/media', [
            'file' => $this->photograph(),
            'title_hi' => 'चित्र',
            'status' => Media::STATUS_DRAFT,
        ])->assertStatus(201);

        $this->assertNotNull(Media::query()->firstOrFail()->uploaded_by);
    }

    public function test_an_upload_without_a_title_is_refused(): void
    {
        $this->postJson('/api/admin/media', ['status' => Media::STATUS_DRAFT])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->assertSame(0, Media::query()->count());
    }

    public function test_a_refused_upload_stores_neither_a_row_nor_a_file(): void
    {
        $path = tempnam(sys_get_temp_dir(), 'rkt').'.jpg';
        file_put_contents($path, 'this is not an image');

        $this->post('/api/admin/media', [
            'file' => new UploadedFile($path, 'fake.jpg', 'image/jpeg', null, true),
            'title_hi' => 'नकली',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(422);

        $this->assertSame(0, Media::query()->count());
        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    // --- videos ------------------------------------------------------------

    public function test_a_youtube_link_is_stored_as_a_video_id(): void
    {
        $this->postJson('/api/admin/media/video', [
            'external_url' => 'https://www.youtube.com/watch?v=abcdefghijk&list=tracking&t=42',
            'title_hi' => 'आरती दर्शन',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(201);

        $media = Media::query()->firstOrFail();

        $this->assertSame(MediaType::VIDEO, $media->media_type);
        $this->assertSame('abcdefghijk', $media->provider_ref);
        // Rebuilt from the id, so the tracking parameters the admin pasted are
        // not stored and never handed to a browser.
        $this->assertSame('https://www.youtube.com/watch?v=abcdefghijk', $media->external_url);
        $this->assertNull($media->file_path);
    }

    /** @return array<string, array{string}> */
    public static function youtubeUrlShapes(): array
    {
        return [
            'short link' => ['https://youtu.be/abcdefghijk'],
            'embed' => ['https://www.youtube.com/embed/abcdefghijk'],
            'shorts' => ['https://www.youtube.com/shorts/abcdefghijk'],
            'live' => ['https://www.youtube.com/live/abcdefghijk'],
            'mobile' => ['https://m.youtube.com/watch?v=abcdefghijk'],
        ];
    }

    #[DataProvider('youtubeUrlShapes')]
    public function test_the_shapes_a_committee_member_might_paste_all_work(string $url): void
    {
        $this->postJson('/api/admin/media/video', [
            'external_url' => $url,
            'title_hi' => 'दर्शन',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(201);

        $this->assertSame('abcdefghijk', Media::query()->firstOrFail()->provider_ref);
    }

    /** @return array<string, array{string}> */
    public static function refusedVideoUrls(): array
    {
        return [
            'another host' => ['https://vimeo.com/123456789'],
            'javascript' => ['javascript:alert(1)'],
            'lookalike host' => ['https://youtube.com.evil.example/watch?v=abcdefghijk'],
            'no video id' => ['https://www.youtube.com/'],
            'malformed id' => ['https://youtu.be/short'],
        ];
    }

    #[DataProvider('refusedVideoUrls')]
    public function test_a_link_that_is_not_a_youtube_video_is_refused(string $url): void
    {
        // An arbitrary embed source out of an admin form is a stored-XSS
        // vector; only a validated video id is stored.
        $this->postJson('/api/admin/media/video', [
            'external_url' => $url,
            'title_hi' => 'घुसपैठ',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(422);

        $this->assertSame(0, Media::query()->count());
    }

    // --- editing and arranging ---------------------------------------------

    public function test_titles_captions_and_status_can_be_edited(): void
    {
        $media = Media::factory()->create();

        $this->putJson("/api/admin/media/{$media->id}", [
            'title_hi' => 'नया शीर्षक',
            'caption_hi' => 'नया विवरण',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertOk();

        $media->refresh();
        $this->assertSame('नया शीर्षक', $media->title_hi);
        $this->assertTrue($media->isPublished());
    }

    public function test_a_blank_english_title_is_stored_as_absent(): void
    {
        // The bilingual fallback keys on absence, and an empty string is not
        // absence.
        $media = Media::factory()->create(['title_en' => 'Old']);

        $this->putJson("/api/admin/media/{$media->id}", [
            'title_hi' => 'शीर्षक',
            'title_en' => '   ',
            'status' => Media::STATUS_DRAFT,
        ])->assertOk();

        $this->assertNull($media->refresh()->title_en);
    }

    public function test_the_stored_file_cannot_be_replaced_through_an_edit(): void
    {
        $media = Media::factory()->create();
        $original = $media->large_path;

        $this->put("/api/admin/media/{$media->id}", [
            'file' => $this->photograph(),
            'title_hi' => 'शीर्षक',
            'status' => Media::STATUS_DRAFT,
        ])->assertOk();

        // Every reference on this site is by URL, so swapping the bytes under a
        // URL would silently change a page, a poster and a portrait at once.
        $this->assertSame($original, $media->refresh()->large_path);
    }

    public function test_reordering_applies_the_whole_arrangement(): void
    {
        $first = Media::factory()->published()->create(['sort_order' => 0]);
        $second = Media::factory()->published()->create(['sort_order' => 1]);
        $third = Media::factory()->published()->create(['sort_order' => 2]);

        $this->postJson('/api/admin/media/reorder', [
            'ids' => [$third->id, $first->id, $second->id],
        ])->assertOk();

        $this->assertSame(0, $third->refresh()->sort_order);
        $this->assertSame(1, $first->refresh()->sort_order);
        $this->assertSame(2, $second->refresh()->sort_order);
    }

    public function test_the_admin_list_includes_drafts_and_can_be_filtered(): void
    {
        Media::factory()->published()->count(2)->create();
        Media::factory()->create();

        $this->getJson('/api/admin/media')->assertOk()->assertJsonCount(3, 'data');
        $this->getJson('/api/admin/media?status=draft')->assertOk()->assertJsonCount(1, 'data');
    }

    // --- the deletion guard ------------------------------------------------

    public function test_an_unreferenced_item_is_deleted_with_its_files(): void
    {
        $this->post('/api/admin/media', [
            'file' => $this->photograph(),
            'title_hi' => 'चित्र',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(201);

        $media = Media::query()->firstOrFail();
        $paths = $media->storedPaths();

        $this->deleteJson("/api/admin/media/{$media->id}")->assertNoContent();

        $this->assertSame(0, Media::query()->count());
        foreach ($paths as $path) {
            Storage::disk('public')->assertMissing($path);
        }
    }

    public function test_an_event_poster_blocks_deletion(): void
    {
        $media = Media::factory()->published()->create();
        Event::factory()->create([
            'title_hi' => 'जन्माष्टमी',
            'poster_url' => $media->fileUrl(),
        ]);

        $response = $this->deleteJson("/api/admin/media/{$media->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'MEDIA_IN_USE');

        // The referrer is named: "cannot delete" with no reason is a dead end
        // for a committee member who cannot read the database.
        $response->assertJsonPath('error.details.references.0.type', 'event_poster');
        $response->assertJsonPath('error.details.references.0.label', 'जन्माष्टमी');

        $this->assertSame(1, Media::query()->count());
    }

    public function test_a_committee_portrait_blocks_deletion(): void
    {
        $media = Media::factory()->published()->create();
        CommitteeMember::factory()->create([
            'name_hi' => 'अध्यक्ष जी',
            'photo_url' => $media->variantUrl('medium'),
        ]);

        $this->deleteJson("/api/admin/media/{$media->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.details.references.0.type', 'committee_member');
    }

    public function test_the_temple_logo_blocks_deletion(): void
    {
        $media = Media::factory()->published()->create();
        TempleProfile::query()->create([
            'name_hi' => 'ठाकुरबाड़ी',
            'logo_url' => $media->fileUrl(),
        ]);

        $this->deleteJson("/api/admin/media/{$media->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.details.references.0.type', 'temple_logo');
    }

    public function test_an_album_cover_blocks_deletion(): void
    {
        $media = Media::factory()->published()->create();
        Album::factory()->create(['cover_media_id' => $media->id, 'title_hi' => 'जन्माष्टमी']);

        $this->deleteJson("/api/admin/media/{$media->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.details.references.0.type', 'album_cover');
    }

    public function test_the_donation_qr_code_blocks_deletion(): void
    {
        // Phase 6 started pointing at the media library, so the guard learned
        // about it in the same change. A referrer that does not register itself
        // here is a hole nobody notices until a QR code disappears from the
        // donation page.
        $media = Media::factory()->published()->create();
        DonationSetting::query()->create([
            'upi_id' => 'thakurbari@upi',
            'qr_url' => $media->fileUrl(),
            'is_published' => true,
        ]);

        $this->deleteJson("/api/admin/media/{$media->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.details.references.0.type', 'donation_qr');
    }

    public function test_a_page_that_embeds_the_image_blocks_deletion(): void
    {
        $media = Media::factory()->published()->create();
        Page::query()->create([
            'slug' => 'about',
            'title_hi' => 'मंदिर परिचय',
            'content_hi' => 'देखें: '.$media->fileUrl().' — मंदिर का चित्र।',
            'status' => Page::STATUS_PUBLISHED,
        ]);

        $this->deleteJson("/api/admin/media/{$media->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.details.references.0.type', 'page');
    }

    public function test_a_similar_but_different_url_does_not_block_deletion(): void
    {
        $media = Media::factory()->published()->create();
        $other = Media::factory()->published()->create();

        Event::factory()->create(['poster_url' => $other->fileUrl()]);

        $this->deleteJson("/api/admin/media/{$media->id}")->assertNoContent();
    }

    public function test_references_can_be_asked_for_before_deleting(): void
    {
        $media = Media::factory()->published()->create();

        $this->getJson("/api/admin/media/{$media->id}/references")
            ->assertOk()
            ->assertJsonPath('data.can_delete', true);

        Event::factory()->create(['poster_url' => $media->fileUrl()]);

        $this->getJson("/api/admin/media/{$media->id}/references")
            ->assertOk()
            ->assertJsonPath('data.can_delete', false);
    }

    // --- albums ------------------------------------------------------------

    public function test_an_album_is_created_with_a_generated_slug(): void
    {
        $this->postJson('/api/admin/albums', [
            'title_hi' => 'जन्माष्टमी महोत्सव',
            'title_en' => 'Janmashtami Festival',
            'status' => Album::STATUS_PUBLISHED,
        ])->assertStatus(201);

        $this->assertSame('janmashtami-festival', Album::query()->firstOrFail()->slug);
    }

    public function test_two_albums_with_the_same_name_get_distinct_slugs(): void
    {
        foreach ([1, 2] as $_) {
            $this->postJson('/api/admin/albums', [
                'title_hi' => 'जन्माष्टमी',
                'title_en' => 'Janmashtami',
                'status' => Album::STATUS_DRAFT,
            ])->assertStatus(201);
        }

        $this->assertSame(
            ['janmashtami', 'janmashtami-2'],
            Album::query()->orderBy('id')->pluck('slug')->all(),
        );
    }

    public function test_a_hindi_only_album_still_gets_a_usable_slug(): void
    {
        // A Hindi title transliterates to nothing usable, so an empty slug
        // would collide with the next Hindi-only album's.
        $this->postJson('/api/admin/albums', [
            'title_hi' => 'रथ यात्रा',
            'status' => Album::STATUS_DRAFT,
        ])->assertStatus(201);

        $slug = Album::query()->firstOrFail()->slug;
        $this->assertNotSame('', $slug);
        $this->assertMatchesRegularExpression('/^[a-z0-9-]+$/', $slug);
    }

    public function test_deleting_an_album_keeps_its_photographs(): void
    {
        $album = Album::factory()->create();
        Media::factory()->published()->count(2)->create(['album_id' => $album->id]);

        $this->deleteJson("/api/admin/albums/{$album->id}")->assertNoContent();

        // An album is an arrangement; losing an arrangement must never lose the
        // content (assumption M6).
        $this->assertSame(2, Media::query()->count());
        $this->assertSame(0, Media::query()->whereNotNull('album_id')->count());
    }
}

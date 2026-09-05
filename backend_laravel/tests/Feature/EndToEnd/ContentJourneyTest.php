<?php

declare(strict_types=1);

namespace Tests\Feature\EndToEnd;

use App\Models\Event;
use App\Models\Media;
use App\Models\Role;
use App\Models\User;
use Carbon\CarbonImmutable;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * A photograph from the committee member's phone to the village's screen.
 *
 * The steps are the ones a content manager really performs — upload, file it in
 * an album, publish it, put it on a festival poster, try to delete it — and the
 * assertions are about what survives each boundary: the location data must not,
 * the draft must not, and the file must not disappear while a page still points
 * at it.
 */
class ContentJourneyTest extends TestCase
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

    /** A real JPEG carrying a real EXIF block, as a phone would produce. */
    private function photographWithLocation(): UploadedFile
    {
        $image = imagecreatetruecolor(1400, 900);
        imagefilledrectangle($image, 0, 0, 1400, 900, (int) imagecolorallocate($image, 180, 60, 90));

        ob_start();
        imagejpeg($image, null, 88);
        $jpeg = (string) ob_get_clean();
        imagedestroy($image);

        // A minimal APP1/Exif segment spliced in after SOI. Its contents do not
        // have to be a valid IFD for this journey — what is asserted is that
        // the marker does not survive the re-encode.
        $exif = "\xFF\xE1\x00\x20Exif\x00\x00MM\x00\x2A".str_repeat("\x00", 22);
        $withExif = substr($jpeg, 0, 2).$exif.substr($jpeg, 2);

        $path = tempnam(sys_get_temp_dir(), 'rkt').'.jpg';
        file_put_contents($path, $withExif);

        return new UploadedFile($path, 'IMG_2026.jpg', 'image/jpeg', null, true);
    }

    /**
     * Upload to publication, with the two things that must not travel with it:
     * the visitor must not see it while it is a draft, and nobody must be able
     * to read where it was taken.
     */
    public function test_a_photograph_is_stripped_stored_and_only_then_public(): void
    {
        $created = $this->post('/api/admin/media', [
            'file' => $this->photographWithLocation(),
            'title_hi' => 'संध्या आरती',
            'title_en' => 'Evening aarti',
            'status' => Media::STATUS_DRAFT,
        ])->assertStatus(201);

        $media = Media::query()->sole();

        // Three variants, because a village connection should not download a
        // 1400px original to draw a thumbnail.
        foreach ([$media->file_path, $media->thumb_path, $media->medium_path] as $path) {
            $this->assertNotNull($path);
            Storage::disk('public')->assertExists($path);

            // The re-encode is the strip: the marker is gone from every stored
            // variant, not only from the one that gets displayed.
            $bytes = (string) Storage::disk('public')->get($path);
            $this->assertStringNotContainsString('Exif', $bytes);
        }

        // A draft is invisible, and the gallery says nothing about it existing.
        $gallery = $this->getJson('/api/public/media')->assertOk();
        $this->assertSame([], $gallery->json('data'));
        $this->assertResponseDoesNotLeak($gallery, 'संध्या आरती');

        // Published, and now it is there.
        $this->putJson("/api/admin/media/{$media->id}", [
            'title_hi' => 'संध्या आरती',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertOk();

        $this->getJson('/api/public/media')
            ->assertOk()
            ->assertJsonPath('data.0.title.value', 'संध्या आरती');
    }

    /**
     * The rule the media library exists to enforce: a file that something
     * points at cannot vanish, and the refusal says what is pointing at it.
     */
    public function test_a_photograph_in_use_cannot_be_deleted_until_it_is_freed(): void
    {
        $this->post('/api/admin/media', [
            'file' => $this->photographWithLocation(),
            'title_hi' => 'जन्माष्टमी पोस्टर',
            'status' => Media::STATUS_PUBLISHED,
        ])->assertStatus(201);

        $media = Media::query()->sole();

        $event = Event::factory()->create([
            'title_hi' => 'जन्माष्टमी',
            'start_at' => CarbonImmutable::parse('2026-09-05 19:00'),
            'poster_url' => $media->urls()[0] ?? null,
        ]);

        // Refused — and the refusal names the festival, because "cannot delete"
        // with no reason is a dead end for somebody who cannot read the
        // database.
        $refused = $this->deleteJson("/api/admin/media/{$media->id}")->assertStatus(409);
        $this->assertResponseCarries($refused, 'जन्माष्टमी');

        $this->assertDatabaseHas('media', ['id' => $media->id]);

        // Freed, and now it goes — row and files together.
        $paths = $media->storedPaths();
        $event->forceFill(['poster_url' => null])->save();

        $this->deleteJson("/api/admin/media/{$media->id}")->assertNoContent();

        $this->assertDatabaseMissing('media', ['id' => $media->id]);
        foreach ($paths as $path) {
            Storage::disk('public')->assertMissing($path);
        }
    }

    /**
     * A calendar entry is a rule, not a row per day, and the public site has to
     * show the days rather than the rule.
     */
    public function test_a_recurring_event_becomes_dates_the_village_can_read(): void
    {
        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web');

        $created = $this->postJson('/api/admin/events', [
            'event_type' => 'aarti',
            'title_hi' => 'संध्या आरती',
            'start_at' => CarbonImmutable::now()->addDay()->setTime(18, 30)->toDateTimeString(),
            'recurrence' => Event::RECURRENCE_DAILY,
            'status' => 'published',
        ])->assertCreated();

        $this->assertSame(Event::RECURRENCE_DAILY, $created->json('data.recurrence'));

        // One stored rule, many occurrences on the public calendar.
        $this->assertSame(1, Event::query()->count());

        $occurrences = $this->getJson('/api/public/events?days=7')->assertOk()->json('data');
        $this->assertGreaterThan(1, count($occurrences));
    }

    /**
     * The other half of the content rule: an account that may write content may
     * not touch the money, however the request is shaped.
     */
    public function test_a_content_manager_is_refused_the_financial_modules(): void
    {
        foreach ([
            '/api/admin/donations',
            '/api/admin/transactions',
            '/api/admin/reports',
        ] as $path) {
            $this->getJson($path)->assertForbidden();
        }
    }
}

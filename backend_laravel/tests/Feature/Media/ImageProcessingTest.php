<?php

declare(strict_types=1);

namespace Tests\Feature\Media;

use App\Exceptions\MediaGuardException;
use App\Services\Media\ImageProcessor;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * The security core of Phase 5, tested against **real bytes** rather than
 * `UploadedFile::fake()`.
 *
 * A fake file has no image structure, so it could not prove that a photograph
 * is stripped, that a resize happened, or that a polyglot is refused — which is
 * everything this class exists to check.
 */
class ImageProcessingTest extends TestCase
{
    private ImageProcessor $processor;

    protected function setUp(): void
    {
        parent::setUp();

        if (! extension_loaded('gd')) {
            $this->markTestSkipped('GD is required to process images.');
        }

        Storage::fake('public');
        config()->set('media.disk', 'public');

        $this->processor = new ImageProcessor;
    }

    // --- helpers -----------------------------------------------------------

    /** A real JPEG of the requested size, written to a temporary file. */
    private function jpeg(int $width, int $height, ?string $exifMarker = null): string
    {
        $image = imagecreatetruecolor($width, $height);
        $this->assertNotFalse($image);

        // Some actual variation, so a resize is measurable rather than a
        // uniform block that would compress identically at any size.
        for ($x = 0; $x < $width; $x += 8) {
            $colour = imagecolorallocate($image, $x % 255, ($x * 3) % 255, 120);
            imagefilledrectangle($image, $x, 0, $x + 4, $height, (int) $colour);
        }

        ob_start();
        imagejpeg($image, null, 90);
        $bytes = (string) ob_get_clean();
        imagedestroy($image);

        if ($exifMarker !== null) {
            $bytes = $this->withExif($bytes, $exifMarker);
        }

        $path = tempnam(sys_get_temp_dir(), 'rkt').'.jpg';
        file_put_contents($path, $bytes);

        return $path;
    }

    /**
     * Splices a minimal, *valid* EXIF APP1 segment carrying one ASCII tag.
     *
     * Valid on purpose: a test that injected arbitrary bytes would only prove
     * that arbitrary bytes are dropped. This proves that a block a camera
     * really writes — the same block that carries GPS coordinates — does not
     * survive (PHASE_5_PLAN assumption M3).
     */
    private function withExif(string $jpeg, string $marker): string
    {
        $value = $marker."\0";
        $tiff = "MM\x00\x2a\x00\x00\x00\x08"          // big-endian TIFF header
            ."\x00\x01"                                // one IFD entry
            ."\x01\x0e"                                // tag 0x010E ImageDescription
            ."\x00\x02"                                // type 2 = ASCII
            .pack('N', strlen($value))                 // component count
            .pack('N', 26)                             // value offset within TIFF
            ."\x00\x00\x00\x00"                        // no next IFD
            .$value;

        $payload = "Exif\x00\x00".$tiff;
        $app1 = "\xff\xe1".pack('n', strlen($payload) + 2).$payload;

        // Immediately after SOI, which is where a camera puts it.
        return substr($jpeg, 0, 2).$app1.substr($jpeg, 2);
    }

    private function upload(string $path, string $name = 'temple.jpg', string $type = 'image/jpeg'): UploadedFile
    {
        return new UploadedFile($path, $name, $type, null, true);
    }

    private function storedBytes(string $path): string
    {
        return (string) Storage::disk('public')->get($path);
    }

    // --- the strip ---------------------------------------------------------

    public function test_exif_metadata_does_not_survive_processing(): void
    {
        $marker = 'GPS-SECRET-VILLAGE';
        $source = $this->jpeg(1200, 800, $marker);

        // The premise: the marker really is in the file we are about to upload,
        // and a reader really can find it.
        $this->assertStringContainsString($marker, (string) file_get_contents($source));
        if (function_exists('exif_read_data')) {
            $exif = @exif_read_data($source);
            $this->assertIsArray($exif);
            $this->assertSame($marker, trim((string) ($exif['ImageDescription'] ?? '')));
        }

        $result = $this->processor->process($this->upload($source), 'media/test');

        foreach ($result->paths as $path) {
            $this->assertStringNotContainsString(
                $marker,
                $this->storedBytes($path),
                "Metadata survived into {$path}.",
            );
        }
    }

    public function test_bytes_appended_after_the_image_do_not_survive(): void
    {
        // A payload smuggled onto the end of an otherwise valid JPEG. Nothing
        // decodes it, so nothing copies it: the strip is a re-encode, not an
        // edit (assumption M3).
        $source = $this->jpeg(800, 600);
        file_put_contents($source, '<?php echo "smuggled"; ?>', FILE_APPEND);

        $result = $this->processor->process($this->upload($source), 'media/test');

        foreach ($result->paths as $path) {
            $this->assertStringNotContainsString('smuggled', $this->storedBytes($path));
        }
    }

    // --- variants ----------------------------------------------------------

    public function test_a_large_photograph_is_resized_into_three_variants(): void
    {
        $result = $this->processor->process(
            $this->upload($this->jpeg(3000, 2000)),
            'media/test',
        );

        $this->assertNotNull($result->mediumPath);
        $this->assertNotNull($result->thumbPath);
        $this->assertCount(3, $result->paths);

        // `large` is capped at its bound, never left at the source size.
        $this->assertSame(1920, $result->width);
        $this->assertSame(1280, $result->height);

        $sizes = [];
        foreach (['large' => $result->largePath, 'medium' => $result->mediumPath, 'thumb' => $result->thumbPath] as $name => $path) {
            $info = getimagesizefromstring($this->storedBytes((string) $path));
            $this->assertNotFalse($info);
            $sizes[$name] = $info[0];
        }

        $this->assertSame(1920, $sizes['large']);
        $this->assertSame(1080, $sizes['medium']);
        $this->assertSame(480, $sizes['thumb']);
    }

    public function test_a_small_photograph_is_never_upscaled(): void
    {
        // 400px is below every bound, so one file is written and the smaller
        // variants resolve to it (assumption M4).
        $result = $this->processor->process(
            $this->upload($this->jpeg(400, 300)),
            'media/test',
        );

        $this->assertNull($result->mediumPath);
        $this->assertNull($result->thumbPath);
        $this->assertCount(1, $result->paths);
        $this->assertSame(400, $result->width);
        $this->assertSame(300, $result->height);
    }

    public function test_the_aspect_ratio_survives_the_resize(): void
    {
        $result = $this->processor->process(
            $this->upload($this->jpeg(2400, 600)),
            'media/test',
        );

        $this->assertSame(1920, $result->width);
        $this->assertSame(480, $result->height);
    }

    public function test_the_stored_file_is_smaller_than_the_original(): void
    {
        $source = $this->jpeg(3000, 2000);
        $result = $this->processor->process($this->upload($source), 'media/test');

        $this->assertLessThan((int) filesize($source), $result->byteSize);
    }

    public function test_a_checksum_identifies_the_stored_image(): void
    {
        $result = $this->processor->process(
            $this->upload($this->jpeg(800, 600)),
            'media/test',
        );

        $this->assertSame(
            hash('sha256', $this->storedBytes($result->largePath)),
            $result->checksum,
        );
    }

    public function test_a_transparent_png_stays_a_png(): void
    {
        $image = imagecreatetruecolor(600, 400);
        $this->assertNotFalse($image);
        imagesavealpha($image, true);
        $transparent = imagecolorallocatealpha($image, 0, 0, 0, 127);
        imagefill($image, 0, 0, (int) $transparent);

        ob_start();
        imagepng($image);
        $bytes = (string) ob_get_clean();
        imagedestroy($image);

        $path = tempnam(sys_get_temp_dir(), 'rkt').'.png';
        file_put_contents($path, $bytes);

        $result = $this->processor->process(
            $this->upload($path, 'logo.png', 'image/png'),
            'media/test',
        );

        // A logo flattened onto white would be unusable on the maroon header.
        $this->assertSame('image/png', $result->mimeType);
        $this->assertStringEndsWith('.png', $result->largePath);
    }

    public function test_an_opaque_photograph_uploaded_as_png_becomes_a_jpeg(): void
    {
        $image = imagecreatetruecolor(1200, 800);
        $this->assertNotFalse($image);
        imagefilledrectangle($image, 0, 0, 1200, 800, (int) imagecolorallocate($image, 20, 90, 160));

        ob_start();
        imagepng($image);
        $bytes = (string) ob_get_clean();
        imagedestroy($image);

        $path = tempnam(sys_get_temp_dir(), 'rkt').'.png';
        file_put_contents($path, $bytes);

        // A photograph stored as PNG is several times larger for no visible
        // gain, and this site is read on village mobile data.
        $result = $this->processor->process(
            $this->upload($path, 'aarti.png', 'image/png'),
            'media/test',
        );

        $this->assertSame('image/jpeg', $result->mimeType);
    }

    public function test_stored_names_come_from_the_server_not_the_upload(): void
    {
        $result = $this->processor->process(
            $this->upload($this->jpeg(800, 600), '../../etc/passwd.jpg'),
            'media/test',
        );

        foreach ($result->paths as $path) {
            $this->assertStringStartsWith('media/test/', $path);
            $this->assertStringNotContainsString('..', $path);
            $this->assertStringNotContainsString('passwd', $path);
        }
    }

    // --- refusals ----------------------------------------------------------

    public function test_a_script_renamed_as_a_jpeg_is_refused(): void
    {
        $path = tempnam(sys_get_temp_dir(), 'rkt').'.jpg';
        file_put_contents($path, "#!/bin/sh\necho hello\n");

        // The name says .jpg and the request says image/jpeg. Neither is
        // consulted: the bytes decide (assumption M2).
        //
        // A shell script rather than a PHP one purely so the fixture does not
        // trip a developer machine's antivirus while it sits in the temporary
        // directory; what is under test is that a non-image is refused.
        $this->expectException(MediaGuardException::class);
        $this->processor->process($this->upload($path), 'media/test');
    }

    public function test_an_svg_is_refused_even_though_it_is_an_image(): void
    {
        $path = tempnam(sys_get_temp_dir(), 'rkt').'.svg';
        file_put_contents(
            $path,
            '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>',
        );

        // SVG is a script container, and there is no safe way to serve one from
        // the same origin as the admin session.
        $this->expectException(MediaGuardException::class);
        $this->processor->process($this->upload($path, 'logo.svg', 'image/svg+xml'), 'media/test');
    }

    public function test_a_truncated_image_is_refused(): void
    {
        $source = $this->jpeg(1200, 800);
        $bytes = (string) file_get_contents($source);
        file_put_contents($source, substr($bytes, 0, 60));

        $this->expectException(MediaGuardException::class);
        $this->processor->process($this->upload($source), 'media/test');
    }

    public function test_a_file_over_the_size_limit_is_refused(): void
    {
        config()->set('media.max_upload_kb', 1);

        $this->expectException(MediaGuardException::class);
        $this->processor->process($this->upload($this->jpeg(2000, 2000)), 'media/test');
    }

    public function test_an_image_below_the_minimum_dimension_is_refused(): void
    {
        $this->expectException(MediaGuardException::class);
        $this->processor->process($this->upload($this->jpeg(8, 8)), 'media/test');
    }

    public function test_a_refused_upload_leaves_nothing_on_disk(): void
    {
        $path = tempnam(sys_get_temp_dir(), 'rkt').'.jpg';
        file_put_contents($path, 'not an image at all');

        try {
            $this->processor->process($this->upload($path), 'media/test');
            $this->fail('The upload should have been refused.');
        } catch (MediaGuardException) {
            $this->assertSame([], Storage::disk('public')->allFiles());
        }
    }

    public function test_forget_removes_every_stored_variant(): void
    {
        $result = $this->processor->process(
            $this->upload($this->jpeg(3000, 2000)),
            'media/test',
        );
        $this->assertCount(3, Storage::disk('public')->allFiles());

        $this->processor->forget($result->paths);

        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_uploads_are_partitioned_by_month(): void
    {
        $this->assertSame('media/'.date('Y/m'), $this->processor->directoryForNow());
    }
}

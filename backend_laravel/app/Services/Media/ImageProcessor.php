<?php

declare(strict_types=1);

namespace App\Services\Media;

use App\Exceptions\MediaGuardException;
use GdImage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Accepts a photograph, or refuses it — the security core of Phase 5.
 *
 * This is the first place in the application that takes a **file** from the
 * outside world, which makes it the first place where a validation mistake is
 * an arbitrary file write and a careless success is a privacy leak: a phone
 * photograph of a villager's home carries GPS coordinates in its EXIF block.
 *
 * Three independent checks, in this order, all server-side. The browser's
 * `Content-Type` header and the uploaded file name are attacker-controlled and
 * are used for **nothing** (PHASE_5_PLAN assumption M2):
 *
 *  1. size, from the file itself;
 *  2. the MIME the server detects from the bytes, against an allow-list;
 *  3. that the bytes actually decode as an image of that type, within bounds.
 *
 * The strip is then a **re-encode**, not an edit (assumption M3): pixels are
 * read and written afresh, so EXIF, XMP, IPTC, colour profiles and anything
 * appended to the file are simply not carried across. Editing metadata out in
 * place would mean trusting a parser on hostile input and keeping whatever it
 * failed to recognise.
 *
 * The same pass produces the responsive variants, so one decode satisfies both
 * halves of the specification's third requirement.
 */
class ImageProcessor
{
    /** True when this deployment can process images at all. */
    public function isAvailable(): bool
    {
        return extension_loaded('gd') && function_exists('imagecreatefromstring');
    }

    /**
     * Validates, strips and stores one uploaded photograph.
     *
     * @param  string  $directory  disk-relative prefix, e.g. `media/2026/09`
     *
     * @throws MediaGuardException
     */
    public function process(UploadedFile $file, string $directory): ProcessedImage
    {
        // Refuse before allocating anything: an unavailable GD must never fall
        // through to storing an unstripped original (assumption M3).
        if (! $this->isAvailable()) {
            throw MediaGuardException::imageSupportMissing();
        }

        if (! $file->isValid()) {
            throw MediaGuardException::uploadFailed();
        }

        $path = $file->getRealPath();
        if ($path === false || ! is_readable($path)) {
            throw MediaGuardException::uploadFailed();
        }

        // 1. Size, from the file on disk rather than any declared length. This
        //    is checked before the bytes are read, so an oversized upload is
        //    never pulled into memory.
        $maxKb = (int) config('media.max_upload_kb', 8192);
        if ($file->getSize() > $maxKb * 1024) {
            throw MediaGuardException::tooLarge($maxKb);
        }

        // Suppressed and checked rather than left to warn: a temporary file that
        // has gone away, or that the host refuses to hand over, is an upload
        // that failed — not a 500.
        $bytes = @file_get_contents($path);
        if ($bytes === false || $bytes === '') {
            throw MediaGuardException::uploadFailed();
        }

        // 2. The type the *bytes* say, never the one the request claimed. Read
        //    once and inspected in memory: `finfo_file` re-opens the file and
        //    warns on some content it recognises, which under Laravel's error
        //    handler becomes an exception in place of our own refusal.
        $detected = $this->detectMime($bytes);
        /** @var array<string, string> $accepted */
        $accepted = (array) config('media.accepted_mimes', []);
        if (! array_key_exists($detected, $accepted)) {
            throw MediaGuardException::unsupportedType($detected);
        }

        // 3. It must genuinely decode as an image of that type, within bounds.
        //    A polyglot that sniffs as JPEG but does not decode is refused here.
        $info = @getimagesizefromstring($bytes);
        if ($info === false || ! isset($info[0], $info[1])) {
            throw MediaGuardException::notAnImage();
        }

        [$width, $height] = [(int) $info[0], (int) $info[1]];
        $declared = $info['mime'] ?? null;
        if (! is_string($declared) || $declared !== $detected) {
            throw MediaGuardException::notAnImage();
        }

        $min = (int) config('media.min_dimension', 16);
        $maxPixels = (int) config('media.max_pixels', 50_000_000);
        if ($width < $min || $height < $min || $width * $height > $maxPixels) {
            throw MediaGuardException::dimensionsOutOfRange();
        }

        $source = @imagecreatefromstring($bytes);
        if (! $source instanceof GdImage) {
            throw MediaGuardException::notAnImage();
        }

        try {
            $source = $this->applyOrientation($source, $detected, $path);

            // Alpha survives only where the source had it and the output format
            // can carry it; a photograph stored as PNG is several times larger
            // for no visible gain, so opaque PNGs become JPEG.
            $hasAlpha = $this->hasAlpha($detected, $bytes);
            [$outputMime, $extension] = $this->outputFormat($detected, $hasAlpha);

            return $this->writeVariants(
                $source,
                $directory,
                $outputMime,
                $extension,
                $hasAlpha,
            );
        } finally {
            // Free the decode before the response is built: a 50-megapixel
            // source is ~200 MB of GD memory and PHP will not release it on its
            // own until the request ends.
            imagedestroy($source);
        }
    }

    /** Removes every stored file for one media row. @param list<string> $paths */
    public function forget(array $paths): void
    {
        $disk = Storage::disk((string) config('media.disk'));

        foreach ($paths as $path) {
            if ($path !== '' && $disk->exists($path)) {
                $disk->delete($path);
            }
        }
    }

    /** The directory new uploads go to, partitioned by month. */
    public function directoryForNow(): string
    {
        $prefix = trim((string) config('media.path', 'media'), '/');

        return $prefix.'/'.date('Y/m');
    }

    // --- internals ---------------------------------------------------------

    private function detectMime(string $bytes): string
    {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo === false) {
            throw MediaGuardException::notAnImage();
        }

        $mime = finfo_buffer($finfo, $bytes);
        finfo_close($finfo);

        return is_string($mime) ? strtolower($mime) : 'application/octet-stream';
    }

    /**
     * Rotates the pixels to match the camera's EXIF orientation.
     *
     * Because the strip drops EXIF entirely, a portrait photograph whose
     * orientation lived only in that block would otherwise display sideways
     * forever. Doing it here bakes the rotation into the pixels, which is the
     * only place it can survive.
     *
     * Guarded on the extension rather than required: a host without `exif`
     * loses auto-rotation, which is cosmetic, and must not lose the upload.
     */
    private function applyOrientation(GdImage $image, string $mime, string $path): GdImage
    {
        if ($mime !== 'image/jpeg' || ! function_exists('exif_read_data')) {
            return $image;
        }

        $exif = @exif_read_data($path);
        $orientation = is_array($exif) ? ($exif['Orientation'] ?? null) : null;
        if (! is_int($orientation) && ! is_numeric($orientation)) {
            return $image;
        }

        $rotated = match ((int) $orientation) {
            3 => imagerotate($image, 180, 0),
            6 => imagerotate($image, -90, 0),
            8 => imagerotate($image, 90, 0),
            default => null,
        };

        if (! $rotated instanceof GdImage) {
            return $image;
        }

        imagedestroy($image);

        return $rotated;
    }

    /**
     * Whether the source carries transparency.
     *
     * Read from the PNG header's colour-type byte rather than by scanning
     * pixels: the IHDR chunk is at a fixed offset and says so exactly, where a
     * scan of a 12-megapixel image would cost more than the resize.
     */
    private function hasAlpha(string $mime, string $bytes): bool
    {
        if ($mime === 'image/webp') {
            // WebP keeps its own format either way, so alpha costs nothing to
            // assume and losing it would be visible.
            return true;
        }

        if ($mime !== 'image/png' || strlen($bytes) < 26) {
            return false;
        }

        // PNG colour types 4 (grey+alpha) and 6 (RGB+alpha) carry an alpha
        // channel; 3 (palette) may carry a tRNS chunk.
        $colourType = ord($bytes[25]);

        return in_array($colourType, [4, 6], true) || str_contains($bytes, 'tRNS');
    }

    /** @return array{0: string, 1: string} the output MIME and its extension */
    private function outputFormat(string $sourceMime, bool $hasAlpha): array
    {
        return match (true) {
            $sourceMime === 'image/webp' => ['image/webp', 'webp'],
            $sourceMime === 'image/png' && $hasAlpha => ['image/png', 'png'],
            default => ['image/jpeg', 'jpg'],
        };
    }

    private function writeVariants(
        GdImage $source,
        string $directory,
        string $mime,
        string $extension,
        bool $hasAlpha,
    ): ProcessedImage {
        /** @var array<string, int> $bounds */
        $bounds = (array) config('media.variants', []);
        $sourceWidth = imagesx($source);
        $sourceHeight = imagesy($source);
        $longest = max($sourceWidth, $sourceHeight);

        $stem = (string) Str::ulid();
        $written = [];

        try {
            // `large` is always produced: it is the re-encoded, stripped image,
            // capped at its bound but never upscaled.
            $largeBound = min((int) ($bounds['large'] ?? 1920), $longest);
            $large = $this->writeOne(
                $source, $directory, $stem, 'lg', $largeBound, $mime, $extension, $hasAlpha,
            );
            $written[] = $large['path'];

            // Smaller variants only where they would actually be smaller.
            $medium = null;
            if ($longest > (int) ($bounds['medium'] ?? 1080)) {
                $medium = $this->writeOne(
                    $source, $directory, $stem, 'md',
                    (int) $bounds['medium'], $mime, $extension, $hasAlpha,
                );
                $written[] = $medium['path'];
            }

            $thumb = null;
            if ($longest > (int) ($bounds['thumb'] ?? 480)) {
                $thumb = $this->writeOne(
                    $source, $directory, $stem, 'sm',
                    (int) $bounds['thumb'], $mime, $extension, $hasAlpha,
                );
                $written[] = $thumb['path'];
            }

            return new ProcessedImage(
                largePath: $large['path'],
                mediumPath: $medium['path'] ?? null,
                thumbPath: $thumb['path'] ?? null,
                mimeType: $mime,
                byteSize: $large['bytes'],
                width: $large['width'],
                height: $large['height'],
                checksum: $large['checksum'],
                paths: $written,
            );
        } catch (\Throwable $e) {
            // A half-written set is worse than none: it leaves orphan files no
            // row points at, which nothing will ever clean up.
            $this->forget($written);

            throw $e;
        }
    }

    /**
     * @return array{path: string, bytes: int, width: int, height: int, checksum: string}
     */
    private function writeOne(
        GdImage $source,
        string $directory,
        string $stem,
        string $suffix,
        int $longestEdge,
        string $mime,
        string $extension,
        bool $hasAlpha,
    ): array {
        $sourceWidth = imagesx($source);
        $sourceHeight = imagesy($source);
        $scale = min(1.0, $longestEdge / max($sourceWidth, $sourceHeight));

        $width = max(1, (int) round($sourceWidth * $scale));
        $height = max(1, (int) round($sourceHeight * $scale));

        $canvas = imagecreatetruecolor($width, $height);
        if (! $canvas instanceof GdImage) {
            throw MediaGuardException::notAnImage();
        }

        try {
            if ($hasAlpha && $mime !== 'image/jpeg') {
                imagealphablending($canvas, false);
                imagesavealpha($canvas, true);
                $transparent = imagecolorallocatealpha($canvas, 0, 0, 0, 127);
                if ($transparent !== false) {
                    imagefilledrectangle($canvas, 0, 0, $width, $height, $transparent);
                }
            } else {
                // JPEG has no alpha, so anything transparent must land on
                // white rather than on GD's default black.
                $white = imagecolorallocate($canvas, 255, 255, 255);
                if ($white !== false) {
                    imagefilledrectangle($canvas, 0, 0, $width, $height, $white);
                }
            }

            imagecopyresampled(
                $canvas, $source,
                0, 0, 0, 0,
                $width, $height, $sourceWidth, $sourceHeight,
            );

            $bytes = $this->encode($canvas, $mime);
        } finally {
            imagedestroy($canvas);
        }

        $path = sprintf('%s/%s-%s.%s', trim($directory, '/'), $stem, $suffix, $extension);

        $stored = Storage::disk((string) config('media.disk'))
            ->put($path, $bytes, ['visibility' => 'public']);

        if ($stored === false) {
            throw MediaGuardException::uploadFailed();
        }

        return [
            'path' => $path,
            'bytes' => strlen($bytes),
            'width' => $width,
            'height' => $height,
            'checksum' => hash('sha256', $bytes),
        ];
    }

    private function encode(GdImage $canvas, string $mime): string
    {
        $quality = (int) config('media.quality', 82);

        ob_start();
        $ok = match ($mime) {
            'image/png' => imagepng($canvas, null, 6),
            'image/webp' => imagewebp($canvas, null, $quality),
            default => imagejpeg($canvas, null, $quality),
        };
        $bytes = (string) ob_get_clean();

        if ($ok === false || $bytes === '') {
            throw MediaGuardException::uploadFailed();
        }

        return $bytes;
    }
}

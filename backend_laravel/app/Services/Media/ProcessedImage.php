<?php

declare(strict_types=1);

namespace App\Services\Media;

/**
 * What {@see ImageProcessor} wrote to disk for one accepted upload.
 *
 * `medium` and `thumb` are null when the source was already smaller than that
 * bound: nothing is ever upscaled, so a 600-pixel photograph has one stored
 * file and the smaller variants resolve to it (PHASE_5_PLAN assumption M4).
 */
final class ProcessedImage
{
    /** @param list<string> $paths every disk-relative path written */
    public function __construct(
        public readonly string $largePath,
        public readonly ?string $mediumPath,
        public readonly ?string $thumbPath,
        public readonly string $mimeType,
        public readonly int $byteSize,
        public readonly int $width,
        public readonly int $height,
        public readonly string $checksum,
        public readonly array $paths,
    ) {}
}

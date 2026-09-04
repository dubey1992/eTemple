<?php

declare(strict_types=1);

namespace App\Support;

/**
 * What a media row is: an uploaded photograph, or a linked video.
 *
 * A code-defined catalogue like {@see EventType} and {@see Permission}: the
 * labels are translated in the Flutter client, so the set is two constants
 * rather than a table and a seeder.
 */
final class MediaType
{
    public const PHOTO = 'photo';

    public const VIDEO = 'video';

    /** @return list<string> */
    public static function all(): array
    {
        return [self::PHOTO, self::VIDEO];
    }

    public static function exists(string $type): bool
    {
        return in_array($type, self::all(), true);
    }
}

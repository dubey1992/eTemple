<?php

declare(strict_types=1);

namespace App\Support;

/**
 * The kinds of event the calendar carries.
 *
 * A code-defined catalogue rather than a database table, exactly like
 * `Permission`: the labels are translated in the Flutter client, so adding a
 * type is one constant and two ARB entries instead of a migration and a
 * seeder (PHASE_4_PLAN assumption E7).
 */
final class EventType
{
    public const AARTI = 'aarti';

    public const BHAJAN_KIRTAN = 'bhajan_kirtan';

    public const FESTIVAL = 'festival';

    public const PUJA = 'puja';

    public const OTHER = 'other';

    /** @return list<string> */
    public static function all(): array
    {
        return [
            self::AARTI,
            self::BHAJAN_KIRTAN,
            self::FESTIVAL,
            self::PUJA,
            self::OTHER,
        ];
    }

    public static function exists(string $type): bool
    {
        return in_array($type, self::all(), true);
    }
}

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

    /**
     * Bilingual labels, for the same reason {@see PaymentMode::label()} has
     * them: the Flutter client translates these codes from its own ARB files
     * and cannot help when the **server** is the one rendering the document —
     * a printed events report, or a spreadsheet a committee opens offline.
     */
    public static function label(string $type): string
    {
        return match ($type) {
            self::AARTI => 'आरती / Aarti',
            self::BHAJAN_KIRTAN => 'भजन-कीर्तन / Bhajan-kirtan',
            self::FESTIVAL => 'त्योहार / Festival',
            self::PUJA => 'पूजा / Puja',
            default => 'अन्य / Other',
        };
    }
}

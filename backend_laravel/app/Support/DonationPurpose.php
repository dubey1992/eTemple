<?php

declare(strict_types=1);

namespace App\Support;

/**
 * What a donation was given for.
 *
 * Codes rather than free text, because this is the column the Phase 10 report
 * groups by — "how much came in for the festival this year" is not a question
 * you can answer over a text box that says "festival", "Festival" and
 * "जन्माष्टमी के लिए". The free text goes in `notes`.
 *
 * The set follows the approved prototype's own description of what donations
 * support: worship arrangements, maintenance, festivals and community service.
 */
final class DonationPurpose
{
    public const GENERAL = 'general';

    public const PUJA = 'puja';

    public const MAINTENANCE = 'maintenance';

    public const FESTIVAL = 'festival';

    /** Community meals — the प्रसाद / भंडारा the prototype's events describe. */
    public const ANNADAN = 'annadan';

    public const CONSTRUCTION = 'construction';

    public const OTHER = 'other';

    /** @return list<string> */
    public static function all(): array
    {
        return [
            self::GENERAL,
            self::PUJA,
            self::MAINTENANCE,
            self::FESTIVAL,
            self::ANNADAN,
            self::CONSTRUCTION,
            self::OTHER,
        ];
    }

    public static function exists(string $purpose): bool
    {
        return in_array($purpose, self::all(), true);
    }

    /** Bilingual labels for the printed receipt — see {@see PaymentMode::label()}. */
    public static function label(string $purpose): string
    {
        return match ($purpose) {
            self::GENERAL => 'सामान्य / General',
            self::PUJA => 'पूजा व्यवस्था / Worship',
            self::MAINTENANCE => 'रखरखाव / Maintenance',
            self::FESTIVAL => 'त्योहार / Festival',
            self::ANNADAN => 'भंडारा एवं प्रसाद / Community meals',
            self::CONSTRUCTION => 'निर्माण कार्य / Construction',
            default => 'अन्य / Other',
        };
    }
}

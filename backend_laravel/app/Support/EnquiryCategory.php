<?php

declare(strict_types=1);

namespace App\Support;

/**
 * What a devotee is writing to the temple about.
 *
 * A code catalogue like {@see PaymentMode} and {@see DonationPurpose}: codes in
 * the column, labels beside them, so adding a category is one constant and two
 * ARB entries rather than a migration.
 *
 * The set follows what a village temple is actually asked — arranging a puja,
 * joining a festival, offering help, and the two that every organisation
 * receives whether it plans for them or not.
 */
final class EnquiryCategory
{
    public const GENERAL = 'general';

    /** Asking the priest to perform a puja, or to book a date for one. */
    public const PUJA_BOOKING = 'puja_booking';

    /** A question about giving — not a donation itself, which is Phase 6. */
    public const DONATION = 'donation';

    public const EVENT = 'event';

    /** Offering to help: seva, shramdaan, a skill the temple needs. */
    public const VOLUNTEER = 'volunteer';

    public const SUGGESTION = 'suggestion';

    public const COMPLAINT = 'complaint';

    public const OTHER = 'other';

    /** @return list<string> */
    public static function all(): array
    {
        return [
            self::GENERAL,
            self::PUJA_BOOKING,
            self::DONATION,
            self::EVENT,
            self::VOLUNTEER,
            self::SUGGESTION,
            self::COMPLAINT,
            self::OTHER,
        ];
    }

    public static function exists(string $category): bool
    {
        return in_array($category, self::all(), true);
    }

    /**
     * Bilingual labels for anything the **server** renders.
     *
     * The Flutter client translates these codes from its own ARB files and
     * cannot help the acknowledgement e-mail, which leaves from PHP. Phase 6
     * learned this the expensive way: its first receipts printed `festival` and
     * `cash` at a villager (PHASE_6_COMPLETION §8.4), and the words had to be
     * added afterwards. They are here from the start.
     */
    public static function label(string $category): string
    {
        return match ($category) {
            self::GENERAL => 'सामान्य जानकारी / General enquiry',
            self::PUJA_BOOKING => 'पूजा बुकिंग / Puja booking',
            self::DONATION => 'दान संबंधी / About donations',
            self::EVENT => 'कार्यक्रम संबंधी / About an event',
            self::VOLUNTEER => 'सेवा एवं सहयोग / Volunteering',
            self::SUGGESTION => 'सुझाव / Suggestion',
            self::COMPLAINT => 'शिकायत / Complaint',
            default => 'अन्य / Other',
        };
    }
}

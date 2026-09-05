<?php

declare(strict_types=1);

namespace App\Support;

/**
 * How loudly an announcement is shown.
 *
 * Prominence, not permission. An urgent announcement obeys exactly the same
 * schedule and publication rules as an ordinary one — it is simply louder
 * (PHASE_8_PLAN assumption N8). Nothing in this catalogue lets a notice skip a
 * start date or reach anybody it otherwise could not.
 */
final class AnnouncementPriority
{
    public const NORMAL = 'normal';

    /** Worth stopping for: a change of timing, a date to remember. */
    public const IMPORTANT = 'important';

    /** A cancellation, a closure, a warning. Rare by design. */
    public const URGENT = 'urgent';

    /** @return list<string> */
    public static function all(): array
    {
        return [self::NORMAL, self::IMPORTANT, self::URGENT];
    }

    public static function exists(string $priority): bool
    {
        return in_array($priority, self::all(), true);
    }

    /**
     * Sort weight — highest first.
     *
     * Used by the public endpoint, which shows **one** announcement: a page
     * whose top third is a pile of notices is a page nobody reads (N9).
     */
    public static function weight(string $priority): int
    {
        return match ($priority) {
            self::URGENT => 3,
            self::IMPORTANT => 2,
            default => 1,
        };
    }

    public static function label(string $priority): string
    {
        return match ($priority) {
            self::IMPORTANT => 'महत्वपूर्ण / Important',
            self::URGENT => 'अत्यावश्यक / Urgent',
            default => 'सामान्य / Normal',
        };
    }
}

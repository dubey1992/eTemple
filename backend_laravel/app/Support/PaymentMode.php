<?php

declare(strict_types=1);

namespace App\Support;

/**
 * How a donation reached the temple.
 *
 * A code-defined catalogue like {@see EventType} and {@see MediaType}: the
 * labels are translated in the Flutter client, so adding a mode is one constant
 * and two ARB entries rather than a migration and a seeder.
 */
final class PaymentMode
{
    public const CASH = 'cash';

    public const UPI = 'upi';

    public const BANK_TRANSFER = 'bank_transfer';

    public const CHEQUE = 'cheque';

    public const CARD = 'card';

    public const OTHER = 'other';

    /** @return list<string> */
    public static function all(): array
    {
        return [
            self::CASH,
            self::UPI,
            self::BANK_TRANSFER,
            self::CHEQUE,
            self::CARD,
            self::OTHER,
        ];
    }

    public static function exists(string $mode): bool
    {
        return in_array($mode, self::all(), true);
    }

    /**
     * Bilingual labels for the printed receipt.
     *
     * The Flutter client translates these codes from its own ARB files, and it
     * cannot help here: the receipt is a document the **server** renders. A
     * receipt that says "cash" to a villager in Amarpur Pankhoriya is not a
     * receipt they can read, so the words live beside the codes.
     *
     * One bilingual string because the receipt itself is bilingual — every
     * other line on it carries both languages too.
     */
    public static function label(string $mode): string
    {
        return match ($mode) {
            self::CASH => 'नकद / Cash',
            self::UPI => 'UPI',
            self::BANK_TRANSFER => 'बैंक ट्रांसफर / Bank transfer',
            self::CHEQUE => 'चेक / Cheque',
            self::CARD => 'कार्ड / Card',
            default => 'अन्य / Other',
        };
    }

    /**
     * Whether this mode leaves a reference the treasurer can match against a
     * statement — a UPI reference, a cheque number, an NEFT/UTR.
     *
     * Cash is the only one that does not, which is why it is the only one
     * allowed to arrive without one (PHASE_6_PLAN assumption N9).
     */
    public static function requiresReference(string $mode): bool
    {
        return $mode !== self::CASH;
    }
}

<?php

declare(strict_types=1);

namespace App\Support;

/**
 * Which way the money went.
 *
 * Two values and no third. A "transfer" would be a third, and it is deliberately
 * absent: moving money from the cash box to the bank changes nothing about what
 * the temple received or spent, and recording it as both an income and an
 * expense — which is how it is usually mis-entered — would inflate both
 * published figures by the same amount.
 */
final class TransactionType
{
    public const INCOME = 'income';

    public const EXPENSE = 'expense';

    /** @return list<string> */
    public static function all(): array
    {
        return [self::INCOME, self::EXPENSE];
    }

    public static function exists(string $type): bool
    {
        return in_array($type, self::all(), true);
    }

    /** Bilingual, for the same reason {@see PaymentMode::label()} is. */
    public static function label(string $type): string
    {
        return match ($type) {
            self::INCOME => 'आय / Income',
            default => 'व्यय / Expense',
        };
    }
}

<?php

declare(strict_types=1);

namespace App\Support;

/**
 * Rupee amounts, held as integer paise.
 *
 * Every amount in this application is an integer number of paise and is only
 * ever turned into rupees for display. A float is exact for one amount and
 * inexact for a sum of them, which is precisely the operation a treasurer cares
 * about (PHASE_6_PLAN assumption N1).
 *
 * Formatting follows the **Indian** grouping the prototype uses — ₹1,25,500,
 * not ₹125,500 — because that is what the committee and the village read.
 */
final class Money
{
    public const PAISE_PER_RUPEE = 100;

    /**
     * Parses what a person typed into paise.
     *
     * Accepts "500", "500.50", "1,25,500" and "₹500". Returns null for anything
     * it does not fully understand rather than guessing — a misread amount is
     * worse than a refused one.
     */
    public static function parse(string $input): ?int
    {
        $cleaned = str_replace([',', ' ', '₹', "\u{20B9}"], '', trim($input));

        if ($cleaned === '' || preg_match('/^\d+(\.\d{1,2})?$/', $cleaned) !== 1) {
            return null;
        }

        [$rupees, $paise] = array_pad(explode('.', $cleaned, 2), 2, '0');

        return (int) $rupees * self::PAISE_PER_RUPEE
            + (int) str_pad($paise, 2, '0');
    }

    /** "125500.00" — the exact decimal string, for a receipt or an export. */
    public static function toDecimalString(int $paise): string
    {
        $sign = $paise < 0 ? '-' : '';
        $paise = abs($paise);

        return sprintf(
            '%s%d.%02d',
            $sign,
            intdiv($paise, self::PAISE_PER_RUPEE),
            $paise % self::PAISE_PER_RUPEE,
        );
    }

    /**
     * "₹1,25,500.00" — Indian digit grouping: the last three digits, then pairs.
     */
    public static function format(int $paise, bool $withSymbol = true): string
    {
        $sign = $paise < 0 ? '-' : '';
        $paise = abs($paise);

        $rupees = (string) intdiv($paise, self::PAISE_PER_RUPEE);
        $fraction = sprintf('%02d', $paise % self::PAISE_PER_RUPEE);

        $grouped = self::groupIndian($rupees);

        return $sign.($withSymbol ? '₹' : '').$grouped.'.'.$fraction;
    }

    /**
     * "Rupees Five Hundred One and Fifty Paise Only" — the line an Indian
     * receipt carries beneath the figure.
     *
     * In English rather than Hindi, and deliberately: this is the wording a
     * bank, an auditor and a printed receipt book all use, and it is the line
     * whose whole purpose is to be unambiguous. The rest of the receipt is
     * bilingual.
     *
     * Indian scale — lakh and crore, not million — because the figure above it
     * is grouped that way.
     */
    public static function toWords(int $paise): string
    {
        $paise = max(0, $paise);
        $rupees = intdiv($paise, self::PAISE_PER_RUPEE);
        $fraction = $paise % self::PAISE_PER_RUPEE;

        $words = 'Rupees '.self::numberToWords($rupees);

        if ($fraction > 0) {
            $words .= ' and '.self::numberToWords($fraction).' Paise';
        }

        return $words.' Only';
    }

    private static function numberToWords(int $number): string
    {
        if ($number === 0) {
            return 'Zero';
        }

        $units = [
            '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
            'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen',
            'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
        ];
        $tens = [
            '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
            'Eighty', 'Ninety',
        ];

        $below100 = static function (int $n) use ($units, $tens): string {
            if ($n < 20) {
                return $units[$n];
            }

            return trim($tens[intdiv($n, 10)].' '.$units[$n % 10]);
        };

        $below1000 = static function (int $n) use ($units, $below100): string {
            $parts = [];
            if ($n >= 100) {
                $parts[] = $units[intdiv($n, 100)].' Hundred';
                $n %= 100;
            }
            if ($n > 0) {
                $parts[] = $below100($n);
            }

            return implode(' ', $parts);
        };

        // Indian scale: crore, lakh, thousand, then the last three digits.
        $parts = [];
        foreach ([
            10_000_000 => 'Crore',
            100_000 => 'Lakh',
            1_000 => 'Thousand',
        ] as $value => $name) {
            if ($number >= $value) {
                $parts[] = $below1000(intdiv($number, $value)).' '.$name;
                $number %= $value;
            }
        }

        if ($number > 0) {
            $parts[] = $below1000($number);
        }

        return implode(' ', $parts);
    }

    /** 1234567 → "12,34,567". */
    public static function groupIndian(string $digits): string
    {
        if (strlen($digits) <= 3) {
            return $digits;
        }

        $last3 = substr($digits, -3);
        $rest = substr($digits, 0, -3);

        // Everything before the final three digits is grouped in pairs.
        $pairs = [];
        while (strlen($rest) > 2) {
            $pairs[] = substr($rest, -2);
            $rest = substr($rest, 0, -2);
        }
        if ($rest !== '') {
            $pairs[] = $rest;
        }

        return implode(',', array_reverse($pairs)).','.$last3;
    }
}

<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Support\Money;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

/**
 * Money is integer paise, and this is why.
 *
 * Every one of these is a way a rupee amount goes wrong when it is a float or
 * when it is grouped the way an American reads it.
 */
class MoneyTest extends TestCase
{
    /** @return array<string, array{string, int|null}> */
    public static function parsedAmounts(): array
    {
        return [
            'whole rupees' => ['500', 50_000],
            'with paise' => ['500.50', 50_050],
            'one decimal place' => ['500.5', 50_050],
            'indian grouping' => ['1,25,500', 12_550_000],
            'with the symbol' => ['₹501', 50_100],
            'with spaces' => [' 501 ', 50_100],
            'zero' => ['0', 0],

            'empty' => ['', null],
            'letters' => ['five hundred', null],
            'negative' => ['-500', null],
            'three decimal places' => ['500.555', null],
            'two dots' => ['500.5.5', null],
            'trailing text' => ['500 rupees', null],
        ];
    }

    #[DataProvider('parsedAmounts')]
    public function test_it_reads_what_a_person_types_or_refuses_it(string $input, ?int $expected): void
    {
        // Refused rather than guessed at: a misread amount is worse than one
        // the treasurer has to type again.
        $this->assertSame($expected, Money::parse($input));
    }

    public function test_the_classic_float_error_cannot_happen(): void
    {
        // 0.1 + 0.2 !== 0.3 in binary floating point, and a temple's books are
        // exactly a long column of such additions.
        $total = 0;
        for ($i = 0; $i < 10; $i++) {
            $total += Money::parse('0.10');
        }

        $this->assertSame(100, $total);
        $this->assertSame('₹1.00', Money::format($total));
    }

    /** @return array<string, array{int, string}> */
    public static function formattedAmounts(): array
    {
        return [
            'under a thousand' => [50_100, '₹501.00'],
            'exactly a thousand' => [100_000, '₹1,000.00'],
            'a lakh, grouped the Indian way' => [12_550_000, '₹1,25,500.00'],
            'a crore' => [1_000_000_000, '₹1,00,00,000.00'],
            'with paise' => [50_050, '₹500.50'],
            'zero' => [0, '₹0.00'],
        ];
    }

    #[DataProvider('formattedAmounts')]
    public function test_it_groups_digits_the_way_the_village_reads_them(int $paise, string $expected): void
    {
        // ₹1,25,500 and not ₹125,500 — the prototype's own figure.
        $this->assertSame($expected, Money::format($paise));
    }

    public function test_the_decimal_string_is_exact_for_an_export(): void
    {
        $this->assertSame('1255.00', Money::toDecimalString(125_500));
        $this->assertSame('0.05', Money::toDecimalString(5));
    }

    /** @return array<string, array{int, string}> */
    public static function amountsInWords(): array
    {
        return [
            'a common offering' => [50_100, 'Rupees Five Hundred One Only'],
            'with paise' => [50_050, 'Rupees Five Hundred and Fifty Paise Only'],
            'a teen' => [1_500, 'Rupees Fifteen Only'],
            'a round thousand' => [100_000, 'Rupees One Thousand Only'],
            'a lakh, Indian scale' => [12_550_000, 'Rupees One Lakh Twenty Five Thousand Five Hundred Only'],
            'a crore' => [1_000_000_000, 'Rupees One Crore Only'],
            'zero' => [0, 'Rupees Zero Only'],
        ];
    }

    #[DataProvider('amountsInWords')]
    public function test_the_receipt_line_reads_in_indian_scale(int $paise, string $expected): void
    {
        // Lakh and crore, not million: the figure above it is grouped that way,
        // and the words exist precisely to remove ambiguity.
        $this->assertSame($expected, Money::toWords($paise));
    }
}

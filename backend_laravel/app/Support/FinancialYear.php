<?php

declare(strict_types=1);

namespace App\Support;

use Illuminate\Support\Carbon;

/**
 * The Indian financial year: 1 April to 31 March.
 *
 * Not the calendar year, and not a configurable window. This is the year the
 * committee's own accounts, its auditor and every form it files already use, so
 * a published figure that covered January to December would have to be
 * recalculated by hand before it could be quoted anywhere else
 * (PHASE_9_PLAN assumption N10).
 *
 * The year is named by the April it starts in: `2026` is 1 April 2026 to
 * 31 March 2027, written "2026–27".
 */
final class FinancialYear
{
    public const START_MONTH = 4;

    private function __construct(public readonly int $year) {}

    public static function of(int $year): self
    {
        return new self($year);
    }

    /** The financial year a given day falls in. */
    public static function containing(Carbon $date): self
    {
        return new self($date->month >= self::START_MONTH ? $date->year : $date->year - 1);
    }

    public static function current(): self
    {
        return self::containing(Carbon::now());
    }

    /**
     * Whether a year is one this application will report on.
     *
     * Bounded on both sides. The lower bound keeps a typo like `?year=20` from
     * scanning the whole table; the upper one keeps the public page from
     * offering to report on a year that has not begun.
     */
    public static function isReportable(int $year): bool
    {
        return $year >= 2000 && $year <= self::current()->year;
    }

    public function startsOn(): Carbon
    {
        return Carbon::create($this->year, self::START_MONTH, 1)->startOfDay();
    }

    public function endsOn(): Carbon
    {
        return $this->startsOn()->addYear()->subDay()->endOfDay();
    }

    /** "2026–27", with an en dash, as an Indian financial year is written. */
    public function label(): string
    {
        return sprintf('%d–%02d', $this->year, ($this->year + 1) % 100);
    }

    public function previous(): self
    {
        return new self($this->year - 1);
    }

    /**
     * The years worth offering in a picker: this one and the [$count - 1]
     * before it, newest first, never earlier than [$earliest].
     *
     * @return list<self>
     */
    public static function recent(int $count = 5, ?int $earliest = null): array
    {
        $current = self::current()->year;
        $years = [];

        for ($year = $current; $year > $current - $count; $year--) {
            if ($earliest !== null && $year < $earliest) {
                break;
            }

            $years[] = new self($year);
        }

        return $years;
    }
}

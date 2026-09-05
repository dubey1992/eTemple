<?php

declare(strict_types=1);

namespace App\Reports;

use App\Support\Language;

/**
 * One column of a report.
 *
 * The type is not decoration. It decides how the value is written into a file:
 * money as a plain decimal a spreadsheet can add up, a date as an ISO string
 * every spreadsheet parses, a number as a number. Getting this wrong turns a
 * treasurer's column of amounts into text and every total they try to compute
 * silently fails (PHASE_10_PLAN assumption N6).
 */
final class ReportColumn
{
    public const TEXT = 'text';

    /** Integer paise on the way in; a plain decimal on the way out. */
    public const MONEY = 'money';

    public const NUMBER = 'number';

    /** `YYYY-MM-DD`. */
    public const DATE = 'date';

    public const DATETIME = 'datetime';

    private function __construct(
        public readonly string $key,
        public readonly string $labelHi,
        public readonly string $labelEn,
        public readonly string $type,
        /**
         * True for a column carrying somebody's name, telephone number or
         * address. Absent from every response unless the caller both holds the
         * permission and asked for it (assumption N2).
         */
        public readonly bool $personal,
    ) {}

    public static function make(
        string $key,
        string $labelHi,
        string $labelEn,
        string $type = self::TEXT,
    ): self {
        return new self($key, $labelHi, $labelEn, $type, personal: false);
    }

    /** A column that identifies a person. */
    public static function personal(
        string $key,
        string $labelHi,
        string $labelEn,
        string $type = self::TEXT,
    ): self {
        return new self($key, $labelHi, $labelEn, $type, personal: true);
    }

    public function label(Language $language): string
    {
        return $language === Language::English ? $this->labelEn : $this->labelHi;
    }

    /** @return array<string, mixed> */
    public function toArray(Language $language): array
    {
        return [
            'key' => $this->key,
            'label' => $this->label($language),
            'type' => $this->type,
            'personal' => $this->personal,
        ];
    }
}

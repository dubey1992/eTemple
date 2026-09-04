<?php

declare(strict_types=1);

namespace App\Support;

/**
 * The two languages the product supports.
 *
 * Hindi is the source language: it is always required on content, and it is what
 * the API falls back to when the English value is missing.
 */
enum Language: string
{
    case Hindi = 'hi';
    case English = 'en';

    public static function fromRequest(?string $value): self
    {
        return self::tryFrom(mb_strtolower(trim((string) $value))) ?? self::Hindi;
    }

    public function isFallback(): bool
    {
        return $this === self::Hindi;
    }

    /** @return list<string> */
    public static function values(): array
    {
        return array_map(static fn (self $l) => $l->value, self::cases());
    }
}

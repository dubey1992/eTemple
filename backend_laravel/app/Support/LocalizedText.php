<?php

declare(strict_types=1);

namespace App\Support;

/**
 * One piece of bilingual content resolved for a requested language.
 *
 * Implements the Phase 1 fallback rule: when the requested language has no
 * value, the Hindi value is served and the response says so, so the UI can tell
 * the visitor rather than silently showing the wrong language. Neither stored
 * language is ever merged or overwritten (spec: "never silently destroy or
 * overwrite either language").
 */
final class LocalizedText
{
    private function __construct(
        public readonly ?string $value,
        public readonly Language $language,
        public readonly bool $fallbackUsed,
    ) {}

    public static function resolve(?string $hindi, ?string $english, Language $requested): self
    {
        $hindi = self::blankToNull($hindi);
        $english = self::blankToNull($english);

        if ($requested === Language::English) {
            return $english !== null
                ? new self($english, Language::English, false)
                : new self($hindi, Language::Hindi, true);
        }

        return new self($hindi, Language::Hindi, false);
    }

    /** @return array{value: string|null, language: string, fallback_used: bool} */
    public function toArray(): array
    {
        return [
            'value' => $this->value,
            'language' => $this->language->value,
            'fallback_used' => $this->fallbackUsed,
        ];
    }

    public function isEmpty(): bool
    {
        return $this->value === null;
    }

    private static function blankToNull(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        return trim($value) === '' ? null : $value;
    }
}

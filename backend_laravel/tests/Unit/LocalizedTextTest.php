<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Support\Language;
use App\Support\LocalizedText;
use Tests\TestCase;

/**
 * The Phase 1 fallback rule, isolated from HTTP.
 */
class LocalizedTextTest extends TestCase
{
    public function test_hindi_is_served_as_is(): void
    {
        $t = LocalizedText::resolve('हिन्दी', 'English', Language::Hindi);

        $this->assertSame('हिन्दी', $t->value);
        $this->assertSame(Language::Hindi, $t->language);
        $this->assertFalse($t->fallbackUsed);
    }

    public function test_english_is_served_when_present(): void
    {
        $t = LocalizedText::resolve('हिन्दी', 'English', Language::English);

        $this->assertSame('English', $t->value);
        $this->assertSame(Language::English, $t->language);
        $this->assertFalse($t->fallbackUsed);
    }

    public function test_missing_english_falls_back_and_flags_it(): void
    {
        $t = LocalizedText::resolve('हिन्दी', null, Language::English);

        $this->assertSame('हिन्दी', $t->value);
        $this->assertSame(Language::Hindi, $t->language);
        $this->assertTrue($t->fallbackUsed);
    }

    public function test_whitespace_only_english_counts_as_missing(): void
    {
        foreach (['', '   ', "\n\t"] as $blank) {
            $t = LocalizedText::resolve('हिन्दी', $blank, Language::English);
            $this->assertTrue($t->fallbackUsed, 'expected blank English to fall back');
        }
    }

    public function test_hindi_is_never_replaced_by_english(): void
    {
        // Requesting Hindi must never surface the English value, even if Hindi
        // happens to be empty - that would silently show the wrong language.
        $t = LocalizedText::resolve(null, 'English', Language::Hindi);

        $this->assertNull($t->value);
        $this->assertTrue($t->isEmpty());
        $this->assertFalse($t->fallbackUsed);
    }

    public function test_the_serialized_shape_is_the_documented_contract(): void
    {
        $this->assertSame(
            ['value' => 'हिन्दी', 'language' => 'hi', 'fallback_used' => true],
            LocalizedText::resolve('हिन्दी', null, Language::English)->toArray(),
        );
    }

    public function test_language_parsing_is_lenient_but_defaults_to_hindi(): void
    {
        $this->assertSame(Language::English, Language::fromRequest('en'));
        $this->assertSame(Language::English, Language::fromRequest(' EN '));
        $this->assertSame(Language::Hindi, Language::fromRequest('hi'));
        $this->assertSame(Language::Hindi, Language::fromRequest(null));
        $this->assertSame(Language::Hindi, Language::fromRequest('fr'));
        $this->assertSame(['hi', 'en'], Language::values());
    }
}

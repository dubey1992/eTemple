<?php

declare(strict_types=1);

namespace Tests\Feature\EndToEnd;

use Illuminate\Support\Facades\Route;
use Illuminate\Testing\TestResponse;
use PHPUnit\Framework\AssertionFailedError;
use Tests\TestCase;

/**
 * A test about the tests.
 *
 * Phase 12 found that a whole class of privacy assertion in this suite could
 * not fail: `json_encode` escapes non-ASCII, so a Devanagari name that leaked
 * into a JSON response never appeared in the body as itself, and
 * `assertStringNotContainsString('शर्मा', $body)` passed either way. Since
 * every person's name on this site is in Devanagari, the assertions guarding
 * donors, payees and enquiry senders were the ones affected.
 *
 * `assertResponseDoesNotLeak` is the fix. This file is what stops it becoming
 * the same problem one layer up: **the helper is proved to fail** on a body
 * that really does carry the name, in the escaped form a real response uses.
 */
class PrivacyAssertionTest extends TestCase
{
    /** @param array<string, mixed> $payload */
    private function jsonResponse(array $payload): TestResponse
    {
        Route::get('/_privacy-probe', fn () => response()->json($payload));

        return $this->getJson('/_privacy-probe');
    }

    public function test_the_helper_catches_a_leaked_devanagari_name(): void
    {
        $response = $this->jsonResponse(['payee' => 'शर्मा ट्रेडर्स']);

        // First, the fact that made the old assertions vacuous: the characters
        // are simply not in the body.
        $this->assertStringNotContainsString('शर्मा', (string) $response->getContent());

        // And the helper catches it anyway, which is the whole point.
        $this->expectException(AssertionFailedError::class);
        $this->assertResponseDoesNotLeak($response, 'शर्मा');
    }

    public function test_the_helper_passes_when_the_name_really_is_absent(): void
    {
        $response = $this->jsonResponse(['heading' => 'निर्माण कार्य', 'total_paise' => 320000]);

        $this->assertResponseDoesNotLeak($response, 'शर्मा ट्रेडर्स', 'CHQ-884412');
    }

    public function test_the_helper_still_works_on_a_body_that_is_not_json(): void
    {
        Route::get(
            '/_privacy-probe-csv',
            fn () => response("दिनांक,विवरण\n2026-09-01,शर्मा ट्रेडर्स\n", 200, ['Content-Type' => 'text/csv']),
        );

        $response = $this->get('/_privacy-probe-csv');

        $this->assertResponseCarries($response, 'शर्मा ट्रेडर्स');

        $this->expectException(AssertionFailedError::class);
        $this->assertResponseDoesNotLeak($response, 'शर्मा ट्रेडर्स');
    }
}

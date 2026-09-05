<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Testing\TestResponse;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // The Flutter Web client always calls the API cross-origin from a
        // stateful domain. Sending the same Origin header here means the tests
        // exercise the real Sanctum stateful (cookie/session) path rather than a
        // stateless shortcut.
        $this->withHeader('Origin', (string) config('app.frontend_url'));
        $this->withHeader('Accept', 'application/json');
    }

    /**
     * Act as a user, the way a fresh browser would.
     *
     * Two pieces of in-process state have to be cleared first, and both are
     * correct behaviour in production:
     *
     * 1. Sanctum authenticates through a `RequestGuard`, which caches the first
     *    user it resolves and does not clear that cache when the request object
     *    is replaced. Real requests are separate processes, so it never matters
     *    there.
     * 2. Sanctum's stateful pipeline runs `AuthenticateSession`, which stores
     *    the signed-in user's password hash in the session and force-logs-out
     *    when a later request's user does not match. That is the mechanism that
     *    ends other sessions when someone changes their password — but in a test
     *    that switches actor it means the second person inherits the first
     *    person's session and is thrown out with a 401.
     *
     * A different person signing in is a different browser, so the session is
     * flushed and the guards dropped.
     */
    public function actingAs(Authenticatable $user, $guard = null): static
    {
        $this->flushSession();
        $this->app->make('auth')->forgetGuards();

        return parent::actingAs($user, $guard);
    }

    /**
     * Assert that a response does not carry any of these values — in **any**
     * encoding it could plausibly arrive in.
     *
     * This exists because of a whole class of privacy assertion in this suite
     * that could never fail. `json_encode` escapes non-ASCII by default, so a
     * leaked Devanagari name arrives in the body as a run of `\uXXXX` escapes
     * and never as the characters themselves — which means
     * `assertStringNotContainsString('शर्मा', $body)` passed whether the name
     * leaked or not. Every person's name on this site is in Devanagari, so
     * that was most of them (PHASE_12_PLAN §C).
     *
     * The body is normalised through a decode first, so the assertion is made
     * against the text a reader would actually see. Non-JSON bodies — a CSV, a
     * printable receipt — are checked as they are.
     */
    protected function assertResponseDoesNotLeak(TestResponse $response, string ...$values): void
    {
        $raw = (string) $response->getContent();
        $decoded = json_decode($raw, true);
        $searchable = $decoded === null
            ? $raw
            : $raw.' '.json_encode($decoded, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        foreach ($values as $value) {
            $this->assertStringNotContainsString(
                $value,
                (string) $searchable,
                "The response carries \"{$value}\", which must never reach this audience.",
            );
        }
    }

    /**
     * The other half: that a value really is present, whatever the encoding.
     */
    protected function assertResponseCarries(TestResponse $response, string ...$values): void
    {
        $raw = (string) $response->getContent();
        $decoded = json_decode($raw, true);
        $searchable = $decoded === null
            ? $raw
            : $raw.' '.json_encode($decoded, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        foreach ($values as $value) {
            $this->assertStringContainsString($value, (string) $searchable);
        }
    }
}

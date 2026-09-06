<?php

declare(strict_types=1);

namespace Tests\Feature\Http;

use Tests\TestCase;

/**
 * The preflight must allow every header the Flutter client actually sends.
 *
 * A missing entry here does not fail the preflight — the OPTIONS request still
 * answers 204 and looks healthy. It is the *real* request the browser then
 * declines to send, and the page sees a bare `net::ERR_FAILED` with no status
 * and no body to report. That is how this arrived: "403" and "blocked by CORS
 * policy" in the same console line, describing two different requests.
 *
 * `X-HTTP-Method-Override` matters most, because every edit and every delete
 * rides on it (see {@see MethodOverrideTest}). It cannot be checked with curl:
 * curl sends whatever it is told and never enforces CORS, so the API answers
 * perfectly while every browser refuses.
 */
class CorsPreflightTest extends TestCase
{
    private const ORIGIN = 'http://localhost:5000';

    /**
     * @return list<string>
     */
    private function allowedHeaders(string $requested): array
    {
        $response = $this->call('OPTIONS', '/api/admin/temple-profile', [], [], [], [
            'HTTP_ORIGIN' => self::ORIGIN,
            'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
            'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => $requested,
        ]);

        $response->assertSuccessful();

        return array_map(
            'trim',
            explode(',', strtolower((string) $response->headers->get('Access-Control-Allow-Headers'))),
        );
    }

    public function test_the_method_override_header_is_allowed(): void
    {
        $this->assertContains(
            'x-http-method-override',
            $this->allowedHeaders('x-http-method-override,content-type'),
            'The browser will refuse to send any edit or delete without this.',
        );
    }

    public function test_every_header_the_client_sends_is_allowed(): void
    {
        $sentByTheClient = [
            'accept',
            'content-type',
            'x-requested-with',
            'x-xsrf-token',
            'x-http-method-override',
        ];

        $allowed = $this->allowedHeaders(implode(',', $sentByTheClient));

        foreach ($sentByTheClient as $header) {
            $this->assertContains($header, $allowed, "ApiClient sends {$header}; CORS does not allow it.");
        }
    }

    public function test_credentials_are_allowed_and_the_origin_is_never_a_wildcard(): void
    {
        $response = $this->call('OPTIONS', '/api/admin/temple-profile', [], [], [], [
            'HTTP_ORIGIN' => self::ORIGIN,
            'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
        ]);

        // A wildcard origin with credentials is rejected by every browser, and
        // Sanctum's cookie session needs credentials.
        $this->assertSame('true', $response->headers->get('Access-Control-Allow-Credentials'));
        $this->assertSame(self::ORIGIN, $response->headers->get('Access-Control-Allow-Origin'));
    }
}

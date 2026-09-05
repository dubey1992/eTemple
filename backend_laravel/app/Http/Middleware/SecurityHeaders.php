<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * The headers every response carries (spec Phase 11).
 *
 * Deliberate choices, not a copied list:
 *
 *  * **HSTS only over HTTPS.** Sending `Strict-Transport-Security` from a
 *    development site teaches the browser to refuse plain HTTP for that host
 *    for a year, and the only cure is clearing the browser's internal state.
 *    The header belongs on the production site, and only there.
 *
 *  * **`frame-ancestors 'none'` as well as `X-Frame-Options`.** The old header
 *    is what older browsers obey and the CSP directive is what current ones do;
 *    a temple's donation page framed inside somebody else's site is the attack
 *    both of them prevent.
 *
 *  * **A stricter policy on the documents the server composes.** The receipt,
 *    the transaction bill and the printable export are the only HTML this API
 *    emits. They are assembled from stored content, so they get a policy that
 *    forbids scripts outright — if one of them ever tried to run something, it
 *    would be because content got into the wrong place (assumption S8).
 */
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var Response $response */
        $response = $next($request);

        $headers = $response->headers;

        $headers->set('X-Content-Type-Options', 'nosniff');
        $headers->set('X-Frame-Options', 'DENY');
        $headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $headers->set(
            'Permissions-Policy',
            'camera=(), microphone=(), geolocation=(), payment=(), usb=()',
        );

        $headers->set(
            'Content-Security-Policy',
            $this->isServerRenderedDocument($response)
                // Inline styles only: these documents style themselves for the
                // printer and load nothing at all from anywhere.
                ? "default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; font-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"
                : "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
        );

        if ($request->isSecure()) {
            $headers->set(
                'Strict-Transport-Security',
                'max-age=31536000; includeSubDomains',
            );
        }

        return $response;
    }

    private function isServerRenderedDocument(Response $response): bool
    {
        return str_contains((string) $response->headers->get('Content-Type'), 'text/html');
    }
}

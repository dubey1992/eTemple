<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

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
}

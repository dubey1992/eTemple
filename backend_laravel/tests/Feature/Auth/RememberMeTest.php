<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Database\Factories\UserFactory;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

/**
 * "Remember me" on the sign-in screen.
 *
 * The Flutter side already proves the checkbox puts `remember: true` into the
 * request body. Nothing proved the other half — that the flag reaches
 * `Auth::login($user, $remember)` and produces a cookie that still signs the
 * user in once the session is gone. That is the half a refactor can quietly
 * break: the checkbox keeps ticking, the login keeps succeeding, and the only
 * symptom is a committee member being asked for their password every time,
 * which nobody reports as a bug.
 */
class RememberMeTest extends TestCase
{
    use RefreshDatabase;

    private const EMAIL = 'committee@example.test';

    /** Matches SANCTUM_STATEFUL_DOMAINS in phpunit.xml. */
    private const ORIGIN = 'http://localhost:5000';

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        User::factory()->withRole(Role::ADMIN)->create(['email' => self::EMAIL]);

        // Sanctum only makes a request stateful when it looks like it came from
        // the SPA, and only a stateful request gets StartSession and
        // EncryptCookies. Without this the cookie under test is never even
        // decrypted, every assertion below returns 401, and the negative tests
        // pass for entirely the wrong reason.
        $this->withHeader('Origin', self::ORIGIN);
    }

    private function login(bool $remember): TestResponse
    {
        return $this->postJson('/api/auth/login', [
            'email' => self::EMAIL,
            'password' => UserFactory::TEST_PASSWORD,
            'remember' => $remember,
        ]);
    }

    /**
     * The recaller cookie from a sign-in response, name and encrypted value.
     *
     * @return array{0: string|null, 1: string|null}
     */
    private function recaller(TestResponse $response): array
    {
        foreach ($response->headers->getCookies() as $cookie) {
            if (str_starts_with($cookie->getName(), 'remember_web_')) {
                return [$cookie->getName(), $cookie->getValue()];
            }
        }

        return [null, null];
    }

    /**
     * Ask who is signed in, carrying exactly the given cookies and nothing else.
     *
     * Deliberately `call()` rather than `withUnencryptedCookie()`: that helper
     * did not put the cookie on the request at all — the application saw an
     * empty cookie bag — so the test failed while the behaviour it was meant to
     * check worked perfectly against the live site. This is also the more
     * faithful reproduction, since it states the whole cookie jar a browser
     * would send.
     *
     * @param  array<string, string>  $cookies
     */
    private function whoAmI(array $cookies): TestResponse
    {
        return $this->call('GET', '/api/auth/me', [], $cookies, [], [
            'HTTP_ORIGIN' => self::ORIGIN,
            'HTTP_ACCEPT' => 'application/json',
        ]);
    }

    public function test_ticking_remember_me_issues_a_recaller_cookie(): void
    {
        $response = $this->login(remember: true);
        $response->assertOk();

        [$name] = $this->recaller($response);

        $this->assertNotNull($name, 'Signing in with remember=true issued no remember_web_* cookie.');
    }

    public function test_leaving_remember_me_unticked_issues_no_recaller_cookie(): void
    {
        $response = $this->login(remember: false);
        $response->assertOk();

        [$name] = $this->recaller($response);

        $this->assertNull($name, 'A remember_web_* cookie was issued for a visitor who did not ask to be remembered.');
    }

    public function test_the_recaller_cookie_signs_the_user_back_in_without_a_session(): void
    {
        [$name, $value] = $this->recaller($this->login(remember: true));
        $this->assertNotNull($name);

        // Everything the sign-in established is thrown away — the session and
        // the resolved guard both — so the cookie is the only thing left that
        // could authenticate what follows.
        $this->forgetTheSession();

        $this->whoAmI([$name => $value])
            ->assertOk()
            ->assertJsonPath('data.email', self::EMAIL);
    }

    public function test_without_the_recaller_cookie_the_same_request_is_refused(): void
    {
        $this->login(remember: true)->assertOk();
        $this->forgetTheSession();

        // The control for the test above: proves it passes because of the
        // cookie it carries, not because the session survived the flush.
        $this->whoAmI([])->assertUnauthorized();
    }

    public function test_rotating_the_remember_token_invalidates_the_cookie(): void
    {
        [$name, $value] = $this->recaller($this->login(remember: true));
        $this->assertNotNull($name);

        // What AuthService::resetPassword does, and why. A 400-day cookie that
        // outlived a password reset would mean an account compromised today
        // stays reachable for over a year — so the reset has to end the
        // remembered session, not only the active one.
        User::query()->where('email', self::EMAIL)
            ->first()
            ?->forceFill(['remember_token' => Str::random(60)])
            ->save();

        $this->forgetTheSession();

        $this->whoAmI([$name => $value])->assertUnauthorized();
    }

    /**
     * Closing the browser, as far as the server is concerned.
     *
     * `forgetGuards` matters as much as the session: the guard caches whichever
     * user it resolved during sign-in, and without dropping it the next request
     * would answer from that cache rather than from the cookie.
     */
    private function forgetTheSession(): void
    {
        $this->flushSession();
        Auth::forgetGuards();
    }
}

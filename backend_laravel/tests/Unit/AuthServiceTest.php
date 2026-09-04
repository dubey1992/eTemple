<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Exceptions\AuthenticationFailedException;
use App\Models\User;
use App\Services\Auth\AuthService;
use App\Support\ApiErrorCode;
use Database\Factories\UserFactory;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;

class AuthServiceTest extends TestCase
{
    use RefreshDatabase;

    private AuthService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->service = new AuthService;
    }

    public function test_it_returns_the_user_with_its_role_on_success(): void
    {
        $user = User::factory()->create(['email' => 'committee@example.test']);

        $result = $this->service->login(
            $this->request(),
            'committee@example.test',
            UserFactory::TEST_PASSWORD,
        );

        $this->assertTrue($result->is($user));
        $this->assertTrue($result->relationLoaded('role'));
        $this->assertNotNull($result->last_login_at);
    }

    public function test_it_rejects_a_wrong_password(): void
    {
        User::factory()->create(['email' => 'committee@example.test']);

        $this->expectExceptionObject(AuthenticationFailedException::invalidCredentials());

        $this->service->login($this->request(), 'committee@example.test', 'wrong-password');
    }

    public function test_it_rejects_an_unknown_address_with_the_same_code(): void
    {
        try {
            $this->service->login($this->request(), 'nobody@example.test', 'any-password');
            $this->fail('Expected an AuthenticationFailedException.');
        } catch (AuthenticationFailedException $e) {
            $this->assertSame(ApiErrorCode::INVALID_CREDENTIALS, $e->errorCode);
            $this->assertSame(401, $e->status);
        }
    }

    public function test_status_is_only_checked_after_the_password_is_verified(): void
    {
        User::factory()->blocked()->create(['email' => 'blocked@example.test']);

        // Wrong password on a blocked account must still look like bad credentials,
        // otherwise the endpoint leaks which addresses are registered.
        try {
            $this->service->login($this->request(), 'blocked@example.test', 'wrong-password');
            $this->fail('Expected an AuthenticationFailedException.');
        } catch (AuthenticationFailedException $e) {
            $this->assertSame(ApiErrorCode::INVALID_CREDENTIALS, $e->errorCode);
        }
    }

    public function test_it_rejects_a_blocked_account(): void
    {
        User::factory()->blocked()->create(['email' => 'blocked@example.test']);

        try {
            $this->service->login($this->request(), 'blocked@example.test', UserFactory::TEST_PASSWORD);
            $this->fail('Expected an AuthenticationFailedException.');
        } catch (AuthenticationFailedException $e) {
            $this->assertSame(ApiErrorCode::ACCOUNT_BLOCKED, $e->errorCode);
            $this->assertSame(403, $e->status);
        }
    }

    public function test_it_rejects_an_inactive_account_without_stamping_a_login(): void
    {
        $user = User::factory()->inactive()->create(['email' => 'inactive@example.test']);

        try {
            $this->service->login($this->request(), 'inactive@example.test', UserFactory::TEST_PASSWORD);
            $this->fail('Expected an AuthenticationFailedException.');
        } catch (AuthenticationFailedException $e) {
            $this->assertSame(ApiErrorCode::ACCOUNT_INACTIVE, $e->errorCode);
        }

        $this->assertNull($user->fresh()->last_login_at);
    }

    public function test_the_password_is_stored_hashed_not_in_plain_text(): void
    {
        $user = User::factory()->create();

        $this->assertNotSame(UserFactory::TEST_PASSWORD, $user->password);
        $this->assertTrue(password_verify(UserFactory::TEST_PASSWORD, $user->password));
    }

    private function request(): Request
    {
        $request = Request::create('/api/auth/login', 'POST');
        $request->setLaravelSession(app('session.store'));

        return $request;
    }
}

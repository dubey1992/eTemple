<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Database\Factories\UserFactory;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_an_active_user_can_sign_in(): void
    {
        $user = User::factory()->withRole(Role::ADMIN)->create([
            'email' => 'committee@example.test',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'committee@example.test',
            'password' => UserFactory::TEST_PASSWORD,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.email', 'committee@example.test')
            ->assertJsonPath('data.role.slug', Role::ADMIN);

        $this->assertAuthenticatedAs($user->fresh());
    }

    public function test_the_response_never_exposes_the_password_hash(): void
    {
        User::factory()->create(['email' => 'committee@example.test']);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'committee@example.test',
            'password' => UserFactory::TEST_PASSWORD,
        ]);

        $response->assertOk();
        $this->assertStringNotContainsString('password', $response->getContent() ?: '');
        $this->assertArrayNotHasKey('password', $response->json('data'));
    }

    public function test_last_login_at_is_stamped(): void
    {
        $user = User::factory()->create(['email' => 'committee@example.test']);
        $this->assertNull($user->last_login_at);

        $this->postJson('/api/auth/login', [
            'email' => 'committee@example.test',
            'password' => UserFactory::TEST_PASSWORD,
        ])->assertOk();

        $this->assertNotNull($user->fresh()->last_login_at);
    }

    public function test_the_email_is_matched_case_insensitively(): void
    {
        User::factory()->create(['email' => 'committee@example.test']);

        $this->postJson('/api/auth/login', [
            'email' => '  Committee@Example.Test ',
            'password' => UserFactory::TEST_PASSWORD,
        ])->assertOk();
    }

    public function test_a_wrong_password_is_rejected_with_a_generic_message(): void
    {
        User::factory()->create(['email' => 'committee@example.test']);

        $this->postJson('/api/auth/login', [
            'email' => 'committee@example.test',
            'password' => 'not-the-right-password',
        ])
            ->assertUnauthorized()
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'INVALID_CREDENTIALS');

        $this->assertGuest();
    }

    public function test_an_unknown_email_is_indistinguishable_from_a_wrong_password(): void
    {
        $this->postJson('/api/auth/login', [
            'email' => 'nobody@example.test',
            'password' => 'not-the-right-password',
        ])
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'INVALID_CREDENTIALS');
    }

    public function test_a_blocked_user_cannot_sign_in(): void
    {
        User::factory()->blocked()->create(['email' => 'blocked@example.test']);

        $this->postJson('/api/auth/login', [
            'email' => 'blocked@example.test',
            'password' => UserFactory::TEST_PASSWORD,
        ])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_BLOCKED');

        $this->assertGuest();
    }

    public function test_an_inactive_user_cannot_sign_in(): void
    {
        User::factory()->inactive()->create(['email' => 'inactive@example.test']);

        $this->postJson('/api/auth/login', [
            'email' => 'inactive@example.test',
            'password' => UserFactory::TEST_PASSWORD,
        ])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_INACTIVE');

        $this->assertGuest();
    }

    public function test_validation_failures_use_the_error_envelope(): void
    {
        $this->postJson('/api/auth/login', ['email' => 'not-an-email', 'password' => 'short'])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure(['error' => ['details' => ['email', 'password']]]);
    }

    public function test_login_attempts_are_rate_limited(): void
    {
        User::factory()->create(['email' => 'committee@example.test']);

        for ($attempt = 0; $attempt < 5; $attempt++) {
            $this->postJson('/api/auth/login', [
                'email' => 'committee@example.test',
                'password' => 'wrong-password-value',
            ])->assertUnauthorized();
        }

        $this->postJson('/api/auth/login', [
            'email' => 'committee@example.test',
            'password' => UserFactory::TEST_PASSWORD,
        ])
            ->assertStatus(429)
            ->assertJsonPath('error.code', 'TOO_MANY_REQUESTS');
    }
}

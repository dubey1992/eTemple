<?php

declare(strict_types=1);

namespace Tests\Feature\Admin;

use App\Models\LoginAttempt;
use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Factories\UserFactory;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class LoginHistoryAndResetTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->superAdmin = User::factory()->withRole(Role::SUPER_ADMIN)->create();
    }

    // --- Login history -----------------------------------------------------

    public function test_a_successful_sign_in_is_recorded(): void
    {
        $user = User::factory()->withRole(Role::VIEWER)->create(['email' => 'member@thakurbari.test']);

        $this->postJson('/api/auth/login', [
            'email' => 'member@thakurbari.test',
            'password' => UserFactory::TEST_PASSWORD,
        ])->assertOk();

        $attempt = LoginAttempt::query()->firstOrFail();
        $this->assertSame($user->id, $attempt->user_id);
        $this->assertSame(LoginAttempt::OUTCOME_SUCCESS, $attempt->outcome);
        $this->assertTrue($attempt->wasSuccessful());
        $this->assertNotNull($attempt->created_at);
    }

    public function test_failures_are_recorded_with_the_reason(): void
    {
        User::factory()->withRole(Role::VIEWER)->create(['email' => 'member@thakurbari.test']);
        User::factory()->withRole(Role::VIEWER)->blocked()->create(['email' => 'blocked@thakurbari.test']);

        $this->postJson('/api/auth/login', [
            'email' => 'member@thakurbari.test',
            'password' => 'wrong-password-here',
        ])->assertUnauthorized();

        $this->postJson('/api/auth/login', [
            'email' => 'blocked@thakurbari.test',
            'password' => UserFactory::TEST_PASSWORD,
        ])->assertForbidden();

        $outcomes = LoginAttempt::query()->pluck('outcome')->all();
        $this->assertContains(LoginAttempt::OUTCOME_INVALID_CREDENTIALS, $outcomes);
        $this->assertContains(LoginAttempt::OUTCOME_BLOCKED, $outcomes);
    }

    public function test_an_attempt_on_an_unknown_address_is_still_recorded(): void
    {
        $this->postJson('/api/auth/login', [
            'email' => 'nobody@thakurbari.test',
            'password' => 'some-password-value',
        ])->assertUnauthorized();

        $attempt = LoginAttempt::query()->firstOrFail();
        $this->assertNull($attempt->user_id);
        $this->assertSame('nobody@thakurbari.test', $attempt->email);
    }

    public function test_the_history_is_readable_with_security_view_and_newest_first(): void
    {
        $target = User::factory()->withRole(Role::VIEWER)->create();

        LoginAttempt::factory()->failed()->create([
            'user_id' => $target->id,
            'created_at' => now()->subHour(),
        ]);
        LoginAttempt::factory()->create([
            'user_id' => $target->id,
            'created_at' => now(),
        ]);

        $this->actingAs($this->superAdmin, 'web')
            ->getJson("/api/admin/users/{$target->id}/login-history")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.successful', true)
            ->assertJsonPath('data.1.successful', false)
            ->assertJsonPath('meta.total', 2);
    }

    public function test_the_history_shows_only_the_requested_account(): void
    {
        $a = User::factory()->withRole(Role::VIEWER)->create();
        $b = User::factory()->withRole(Role::VIEWER)->create();
        LoginAttempt::factory()->create(['user_id' => $a->id]);
        LoginAttempt::factory()->create(['user_id' => $b->id]);

        $this->actingAs($this->superAdmin, 'web')
            ->getJson("/api/admin/users/{$a->id}/login-history")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    // --- Password reset ----------------------------------------------------

    public function test_a_valid_token_resets_the_password_and_allows_sign_in(): void
    {
        $user = User::factory()->withRole(Role::VIEWER)->create(['email' => 'member@thakurbari.test']);
        $token = Password::broker()->createToken($user);

        $this->postJson('/api/auth/reset-password', [
            'token' => $token,
            'email' => 'member@thakurbari.test',
            'password' => 'a-brand-new-password',
            'password_confirmation' => 'a-brand-new-password',
        ])->assertOk();

        $this->assertTrue(Hash::check('a-brand-new-password', $user->fresh()->password));

        $this->postJson('/api/auth/login', [
            'email' => 'member@thakurbari.test',
            'password' => 'a-brand-new-password',
        ])->assertOk();
    }

    public function test_a_reset_token_cannot_be_used_twice(): void
    {
        $user = User::factory()->withRole(Role::VIEWER)->create(['email' => 'member@thakurbari.test']);
        $token = Password::broker()->createToken($user);

        $payload = [
            'token' => $token,
            'email' => 'member@thakurbari.test',
            'password' => 'first-new-password',
            'password_confirmation' => 'first-new-password',
        ];

        $this->postJson('/api/auth/reset-password', $payload)->assertOk();
        $this->postJson('/api/auth/reset-password', $payload)->assertStatus(422);
    }

    public function test_an_invalid_token_is_refused_without_revealing_why(): void
    {
        User::factory()->withRole(Role::VIEWER)->create(['email' => 'member@thakurbari.test']);

        $this->postJson('/api/auth/reset-password', [
            'token' => 'not-a-real-token',
            'email' => 'member@thakurbari.test',
            'password' => 'a-brand-new-password',
            'password_confirmation' => 'a-brand-new-password',
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonStructure(['error' => ['details' => ['token']]]);
    }

    public function test_a_weak_or_unconfirmed_password_is_rejected(): void
    {
        $user = User::factory()->withRole(Role::VIEWER)->create(['email' => 'member@thakurbari.test']);
        $token = Password::broker()->createToken($user);

        $this->postJson('/api/auth/reset-password', [
            'token' => $token,
            'email' => 'member@thakurbari.test',
            'password' => 'short',
            'password_confirmation' => 'short',
        ])->assertStatus(422);

        $this->postJson('/api/auth/reset-password', [
            'token' => $token,
            'email' => 'member@thakurbari.test',
            'password' => 'a-long-enough-password',
            'password_confirmation' => 'a-different-password',
        ])->assertStatus(422);
    }

    // --- /auth/me carries permissions --------------------------------------

    public function test_me_reports_the_callers_effective_permissions(): void
    {
        $manager = User::factory()->withRole(Role::CONTENT_MANAGER)->create();

        $response = $this->actingAs($manager, 'web')->getJson('/api/auth/me')->assertOk();

        $permissions = $response->json('data.permissions');
        $this->assertContains(Permission::CONTENT_MANAGE, $permissions);
        $this->assertNotContains(Permission::USERS_MANAGE, $permissions);
        $this->assertNotContains(Permission::DONATIONS_VIEW, $permissions);
    }

    public function test_me_reports_every_permission_for_a_super_admin(): void
    {
        $response = $this->actingAs($this->superAdmin, 'web')->getJson('/api/auth/me')->assertOk();

        $this->assertSame(Permission::all(), $response->json('data.permissions'));
    }
}

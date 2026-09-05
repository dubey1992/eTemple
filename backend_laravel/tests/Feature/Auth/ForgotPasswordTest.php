<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Mail\PasswordResetMail;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ForgotPasswordTest extends TestCase
{
    use RefreshDatabase;

    private const GENERIC_MESSAGE = 'If that e-mail address belongs to an active account, a password reset link has been sent.';

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        Mail::fake();
    }

    public function test_an_active_user_is_sent_a_reset_link(): void
    {
        $user = User::factory()->create(['email' => 'committee@example.test']);

        $this->postJson('/api/auth/forgot-password', ['email' => 'committee@example.test'])
            ->assertOk()
            ->assertJsonPath('data.message', self::GENERIC_MESSAGE);

        Mail::assertSent(
            PasswordResetMail::class,
            static fn (PasswordResetMail $mail): bool => $mail->hasTo($user->email),
        );
    }

    public function test_an_unknown_address_gets_the_same_answer_and_no_mail(): void
    {
        $this->postJson('/api/auth/forgot-password', ['email' => 'nobody@example.test'])
            ->assertOk()
            ->assertJsonPath('data.message', self::GENERIC_MESSAGE);

        Mail::assertNothingSent();
    }

    public function test_a_blocked_user_is_never_sent_a_reset_link(): void
    {
        User::factory()->blocked()->create(['email' => 'blocked@example.test']);

        $this->postJson('/api/auth/forgot-password', ['email' => 'blocked@example.test'])
            ->assertOk()
            ->assertJsonPath('data.message', self::GENERIC_MESSAGE);

        Mail::assertNothingSent();
    }

    public function test_the_address_must_be_valid(): void
    {
        $this->postJson('/api/auth/forgot-password', ['email' => 'not-an-email'])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
    }

    public function test_requests_are_rate_limited(): void
    {
        User::factory()->create(['email' => 'committee@example.test']);

        for ($attempt = 0; $attempt < 3; $attempt++) {
            $this->postJson('/api/auth/forgot-password', ['email' => 'committee@example.test'])
                ->assertOk();
        }

        $this->postJson('/api/auth/forgot-password', ['email' => 'committee@example.test'])
            ->assertStatus(429)
            ->assertJsonPath('error.code', 'TOO_MANY_REQUESTS');
    }
}

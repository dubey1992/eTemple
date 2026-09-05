<?php

declare(strict_types=1);

namespace Tests\Feature\Admin;

use App\Mail\AccountInvitation;
use App\Mail\PasswordResetMail;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        Mail::fake();
        $this->superAdmin = User::factory()->withRole(Role::SUPER_ADMIN)->create();
    }

    private function roleId(string $slug): int
    {
        return (int) Role::query()->where('slug', $slug)->value('id');
    }

    public function test_the_list_is_paginated_and_carries_each_users_role(): void
    {
        User::factory()->withRole(Role::VIEWER)->count(3)->create();

        $this->actingAs($this->superAdmin, 'web')
            ->getJson('/api/admin/users?per_page=2')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonPath('meta.total', 4)
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure(['data' => [['id', 'full_name', 'email', 'status', 'role' => ['slug']]]]);
    }

    public function test_the_list_can_be_filtered(): void
    {
        User::factory()->withRole(Role::TREASURER)->create(['first_name' => 'Ganga']);
        User::factory()->withRole(Role::VIEWER)->inactive()->create(['first_name' => 'Yamuna']);

        $this->actingAs($this->superAdmin, 'web')
            ->getJson('/api/admin/users?role='.Role::TREASURER)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.first_name', 'Ganga');

        $this->actingAs($this->superAdmin, 'web')
            ->getJson('/api/admin/users?status=inactive')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.first_name', 'Yamuna');

        $this->actingAs($this->superAdmin, 'web')
            ->getJson('/api/admin/users?search=amun')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_creating_an_account_mails_a_reset_link_and_sets_no_usable_password(): void
    {
        $response = $this->actingAs($this->superAdmin, 'web')
            ->postJson('/api/admin/users', [
                'first_name' => 'सीता',
                'last_name' => 'देवी',
                'email' => 'Sita@Thakurbari.test',
                'role_id' => $this->roleId(Role::CONTENT_MANAGER),
            ])
            ->assertCreated()
            ->assertJsonPath('data.email', 'sita@thakurbari.test')
            ->assertJsonPath('data.role.slug', Role::CONTENT_MANAGER);

        $created = User::query()->where('email', 'sita@thakurbari.test')->firstOrFail();

        // The creator never chose a password, so none of the obvious guesses work.
        foreach (['', 'password', 'sita@thakurbari.test'] as $guess) {
            $this->assertFalse(Hash::check($guess, $created->password));
        }
        $this->assertStringNotContainsString('password', $response->getContent() ?: '');

        // An invitation, not a reset: a member who has never had a password
        // must not be told somebody asked to reset it.
        Mail::assertSent(
            AccountInvitation::class,
            static fn (AccountInvitation $mail): bool => $mail->hasTo($created->email),
        );
        Mail::assertNotSent(PasswordResetMail::class);
    }

    public function test_a_duplicate_email_is_rejected_case_insensitively(): void
    {
        User::factory()->withRole(Role::VIEWER)->create(['email' => 'taken@thakurbari.test']);

        $this->actingAs($this->superAdmin, 'web')
            ->postJson('/api/admin/users', [
                'first_name' => 'Copy',
                'email' => 'TAKEN@thakurbari.test',
                'role_id' => $this->roleId(Role::VIEWER),
            ])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['email']]]);
    }

    public function test_an_account_cannot_be_created_against_a_missing_role(): void
    {
        $this->actingAs($this->superAdmin, 'web')
            ->postJson('/api/admin/users', [
                'first_name' => 'Ghost',
                'email' => 'ghost@thakurbari.test',
                'role_id' => 999999,
            ])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['role_id']]]);
    }

    public function test_an_account_can_be_edited_and_deactivated(): void
    {
        $target = User::factory()->withRole(Role::VIEWER)->create();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/users/{$target->id}", [
                'first_name' => 'राधा',
                'last_name' => null,
                'email' => $target->email,
                'mobile' => '9000000000',
                'role_id' => $this->roleId(Role::TREASURER),
                'status' => User::STATUS_INACTIVE,
            ])
            ->assertOk()
            ->assertJsonPath('data.first_name', 'राधा')
            ->assertJsonPath('data.last_name', null)
            ->assertJsonPath('data.mobile', '9000000000')
            ->assertJsonPath('data.status', User::STATUS_INACTIVE)
            ->assertJsonPath('data.role.slug', Role::TREASURER);
    }

    public function test_a_deactivated_account_loses_access_on_its_next_request(): void
    {
        $target = User::factory()->withRole(Role::ADMIN)->create();

        $this->actingAs($target, 'web')->getJson('/api/auth/me')->assertOk();

        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/users/{$target->id}", [
                'first_name' => $target->first_name,
                'email' => $target->email,
                'role_id' => $target->role_id,
                'status' => User::STATUS_BLOCKED,
            ])
            ->assertOk();

        $this->actingAs($target->fresh(), 'web')
            ->getJson('/api/auth/me')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'ACCOUNT_BLOCKED');
    }

    public function test_an_admin_can_resend_a_password_reset_link(): void
    {
        $target = User::factory()->withRole(Role::VIEWER)->create();

        $this->actingAs($this->superAdmin, 'web')
            ->postJson("/api/admin/users/{$target->id}/send-password-reset")
            ->assertOk();

        // Resending to an existing account is a reset, and says so.
        Mail::assertSent(
            PasswordResetMail::class,
            static fn (PasswordResetMail $mail): bool => $mail->hasTo($target->email),
        );
    }

    public function test_editing_a_missing_account_returns_not_found(): void
    {
        $this->actingAs($this->superAdmin, 'web')
            ->putJson('/api/admin/users/999999', [
                'first_name' => 'X',
                'email' => 'x@thakurbari.test',
                'role_id' => $this->roleId(Role::VIEWER),
                'status' => User::STATUS_ACTIVE,
            ])
            ->assertNotFound();
    }

    public function test_the_password_hash_is_never_returned(): void
    {
        $target = User::factory()->withRole(Role::VIEWER)->create();

        $response = $this->actingAs($this->superAdmin, 'web')
            ->getJson("/api/admin/users/{$target->id}")
            ->assertOk();

        $this->assertArrayNotHasKey('password', $response->json('data'));
        $this->assertStringNotContainsString($target->password, $response->getContent() ?: '');
    }
}

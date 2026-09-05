<?php

declare(strict_types=1);

namespace Tests\Feature\EndToEnd;

use App\Mail\AccountInvitation;
use App\Models\AuditLog;
use App\Models\Role;
use App\Models\User;
use App\Support\AuditAction;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

/**
 * A new committee member, from the day they are given an account to the day it
 * is taken away.
 *
 * This is the journey with the most modules in it and the least test coverage
 * of the whole thing at once: accounts, mail, password reset, sessions,
 * permissions and the audit trail each have their own suite, and the failure
 * that matters — somebody keeps working after the committee removed them —
 * lives between them.
 */
class CommitteeJourneyTest extends TestCase
{
    use RefreshDatabase;

    private User $superAdmin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->superAdmin = User::factory()->withRole(Role::SUPER_ADMIN)->create();
    }

    /**
     * Sign in over HTTP, as a new browser would.
     *
     * The guards are dropped on both sides of the request for the reason given
     * on {@see TestCase::actingAs}: a guard resolved earlier in the same
     * process outlives the request it belongs to, and `AuthenticateSession`
     * then sees one person's session against another person's cached user and
     * force-logs-out — a 401 that never happens in production, where every
     * request is its own process.
     */
    private function signIn(string $email, string $password): void
    {
        $this->flushSession();
        $this->app->make('auth')->forgetGuards();

        $this->postJson('/api/auth/login', ['email' => $email, 'password' => $password])
            ->assertOk();

        $this->app->make('auth')->forgetGuards();
    }

    /**
     * The whole life of an account, in one test.
     *
     * Every step is an HTTP request made the way the console makes it, so what
     * is asserted is the behaviour a real member would meet.
     */
    public function test_an_account_is_created_used_and_then_taken_away(): void
    {
        Mail::fake();

        // 1. The Super Admin adds a treasurer. No password is chosen for them
        //    and none is mailed: the account is created with an unusable hash.
        $created = $this->actingAs($this->superAdmin, 'web')
            ->postJson('/api/admin/users', [
                'first_name' => 'सीता',
                'last_name' => 'देवी',
                'email' => 'sita@thakurbari.test',
                'role_id' => Role::query()->where('slug', Role::TREASURER)->sole()->id,
            ])->assertCreated();

        $userId = $created->json('data.id');
        $this->assertResponseDoesNotLeak($created, 'password');

        // 2. They are invited — not sent a *reset*, which a person who has
        //    never had a password would read as phishing.
        Mail::assertSent(AccountInvitation::class, static fn ($mail): bool => $mail->hasTo('sita@thakurbari.test'));

        // 3. They set a password through the link in that mail and sign in.
        $token = Password::broker()->createToken(User::query()->findOrFail($userId));

        $this->postJson('/api/auth/reset-password', [
            'email' => 'sita@thakurbari.test',
            'token' => $token,
            'password' => 'TempleWork#2026',
            'password_confirmation' => 'TempleWork#2026',
        ])->assertOk();

        $this->signIn('sita@thakurbari.test', 'TempleWork#2026');

        // 4. And they can do a treasurer's work, and only a treasurer's work.
        $this->getJson('/api/auth/me')->assertOk()->assertJsonPath('data.email', 'sita@thakurbari.test');
        $this->getJson('/api/admin/donations')->assertOk();
        $this->getJson('/api/admin/users')->assertForbidden();
        $this->getJson('/api/admin/audit-logs')->assertForbidden();

        // 5. Their term ends and the committee deactivates the account. The
        //    console sends the whole form, so this does too.
        $this->actingAs($this->superAdmin, 'web')
            ->putJson("/api/admin/users/{$userId}", [
                'first_name' => 'सीता',
                'last_name' => 'देवी',
                'email' => 'sita@thakurbari.test',
                'role_id' => Role::query()->where('slug', Role::TREASURER)->sole()->id,
                'status' => User::STATUS_INACTIVE,
            ])
            ->assertOk();

        // 6. Which is the step that has to be true: the password still works,
        //    and the account still does not.
        $this->flushSession();
        $this->app->make('auth')->forgetGuards();
        $this->postJson('/api/auth/login', [
            'email' => 'sita@thakurbari.test',
            'password' => 'TempleWork#2026',
        ])->assertStatus(403);

        // 7. And the trail says who did both things.
        $trail = AuditLog::query()->whereIn('action', [
            AuditAction::USER_CREATED,
            AuditAction::USER_UPDATED,
        ])->get();

        $this->assertCount(2, $trail);
        foreach ($trail as $entry) {
            $this->assertSame($this->superAdmin->fullName(), $entry->actor_name);
        }
    }

    /**
     * A live session does not outlive the account it belongs to.
     *
     * Refusing the *login* is not enough — somebody deactivated at 4pm is
     * usually still signed in, and that is precisely the moment the committee
     * meant to end their access.
     */
    public function test_deactivating_an_account_stops_a_session_that_is_already_open(): void
    {
        $treasurer = User::factory()->withRole(Role::TREASURER)->create();

        $this->actingAs($treasurer, 'web')->getJson('/api/admin/donations')->assertOk();

        $treasurer->forceFill(['status' => User::STATUS_INACTIVE])->save();

        $this->getJson('/api/admin/donations')->assertStatus(403);
    }

    /**
     * The permission matrix, exercised through the API rather than read off the
     * seeder — because what protects an endpoint is the middleware on it, not
     * the table the console draws its menu from.
     */
    public function test_each_role_reaches_exactly_what_it_should(): void
    {
        $expectations = [
            Role::SUPER_ADMIN => ['/api/admin/users' => 200, '/api/admin/audit-logs' => 200, '/api/admin/donations' => 200],
            Role::ADMIN => ['/api/admin/users' => 200, '/api/admin/audit-logs' => 403, '/api/admin/donations' => 200],
            Role::TREASURER => ['/api/admin/users' => 403, '/api/admin/audit-logs' => 403, '/api/admin/donations' => 200],
            Role::CONTENT_MANAGER => ['/api/admin/users' => 403, '/api/admin/audit-logs' => 403, '/api/admin/donations' => 403],
            Role::VIEWER => ['/api/admin/users' => 403, '/api/admin/audit-logs' => 403, '/api/admin/donations' => 200],
        ];

        foreach ($expectations as $slug => $paths) {
            $user = User::factory()->withRole($slug)->create();

            foreach ($paths as $path => $expected) {
                $this->actingAs($user, 'web')
                    ->getJson($path)
                    ->assertStatus($expected, "{$slug} on {$path}");
            }
        }
    }

    /**
     * The console can be told anything; the server decides.
     *
     * Hiding a Flutter button is never the authorization control (spec, Phase
     * 2), so the check that matters is this one: a request the client would
     * never send is still refused.
     */
    public function test_an_account_cannot_promote_itself_by_asking(): void
    {
        $treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $superAdminRole = Role::query()->where('slug', Role::SUPER_ADMIN)->sole()->id;

        $this->actingAs($treasurer, 'web')
            ->putJson("/api/admin/users/{$treasurer->id}", ['role_id' => $superAdminRole])
            ->assertForbidden();

        $this->assertSame(Role::TREASURER, $treasurer->refresh()->role->slug);
    }
}

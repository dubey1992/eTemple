<?php

declare(strict_types=1);

namespace Tests\Feature\Donations;

use App\Models\Donation;
use App\Models\DonationSetting;
use App\Models\Role;
use App\Models\User;
use App\Support\Permission;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Donor privacy, and server-side authorization for the Phase 6 endpoints.
 *
 * The specification names donor privacy as a rule of this phase, and the
 * strongest form of it is that there is nowhere for the data to come out: the
 * public surface is one endpoint that says where to send money, and it carries
 * no donor, no amount and no count.
 *
 * Every authorization case calls the API directly with a role that should be
 * refused. Hiding a Flutter control is never the access control.
 */
class DonationPrivacyTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function actingAsRole(string $slug): User
    {
        $user = User::factory()->withRole($slug)->create();
        $this->actingAs($user, 'web');

        return $user;
    }

    /** @return array<string, mixed> */
    private function payload(): array
    {
        return [
            'donor_name' => 'घुसपैठ',
            'amount' => '100',
            'donation_date' => now()->subDay()->toDateString(),
            'payment_mode' => 'cash',
        ];
    }

    // --- privacy ------------------------------------------------------------

    public function test_there_is_no_public_donation_endpoint(): void
    {
        // Not a list, not a count, not a total, not "our latest donor". The
        // absence is the design (PHASE_6_PLAN assumption N5).
        Donation::factory()->confirmed()->create(['donor_name' => 'सीता देवी']);

        foreach ([
            '/api/public/donations',
            '/api/public/donations/1',
            '/api/public/donations/summary',
            '/api/public/donors',
        ] as $path) {
            $this->getJson($path)->assertNotFound();
        }
    }

    public function test_a_guest_cannot_read_the_register(): void
    {
        Donation::factory()->confirmed()->create();

        $this->getJson('/api/admin/donations')->assertUnauthorized();
        $this->getJson('/api/admin/donations/summary')->assertUnauthorized();
        $this->get('/api/admin/donations/1/receipt')->assertUnauthorized();
    }

    public function test_the_public_donation_details_carry_no_donor_information(): void
    {
        Donation::factory()->confirmed()->create([
            'donor_name' => 'सीता देवी',
            'donor_phone' => '9999999999',
        ]);

        DonationSetting::query()->create([
            'upi_id' => 'thakurbari@upi',
            'bank_name' => 'Demo Bank',
            'is_published' => true,
        ]);

        $response = $this->getJson('/api/public/donation-settings')->assertOk();

        $this->assertResponseDoesNotLeak($response, 'सीता देवी', '9999999999');
        $this->assertResponseCarries($response, 'thakurbari@upi');
    }

    public function test_the_public_details_stay_hidden_until_they_are_published(): void
    {
        DonationSetting::query()->create([
            'upi_id' => 'thakurbari@upi',
            'is_published' => false,
        ]);

        $this->getJson('/api/public/donation-settings')
            ->assertOk()
            ->assertJsonPath('data', null);
    }

    public function test_a_published_but_empty_block_is_still_not_shown(): void
    {
        // An empty box on the public page reads as a broken site rather than an
        // unconfigured one.
        DonationSetting::query()->create(['is_published' => true]);

        $this->getJson('/api/public/donation-settings')
            ->assertOk()
            ->assertJsonPath('data', null);
    }

    public function test_an_unconfigured_site_answers_with_an_empty_state_not_an_error(): void
    {
        $this->getJson('/api/public/donation-settings')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', null);
    }

    // --- authorization ------------------------------------------------------

    /** Roles the seeded matrix does not grant `donations.view`. */
    public static function rolesWithoutDonationsView(): array
    {
        return ['content manager' => [Role::CONTENT_MANAGER]];
    }

    /** Roles the seeded matrix does not grant `donations.manage`. */
    public static function rolesWithoutDonationsManage(): array
    {
        return [
            'content manager' => [Role::CONTENT_MANAGER],
            'viewer' => [Role::VIEWER],
        ];
    }

    #[DataProvider('rolesWithoutDonationsView')]
    public function test_a_role_without_donations_view_cannot_read_the_register(string $slug): void
    {
        // The specification says a Content Manager cannot see sensitive
        // financial detail, and the Phase 2 matrix already encodes that. This
        // is the assertion that it is still true now there is detail to see.
        Donation::factory()->confirmed()->create();
        $this->actingAsRole($slug);

        $this->getJson('/api/admin/donations')->assertForbidden();
        $this->getJson('/api/admin/donations/summary')->assertForbidden();
        $this->get('/api/admin/donations/1/receipt')->assertForbidden();
        $this->getJson('/api/admin/donation-settings')->assertForbidden();
    }

    #[DataProvider('rolesWithoutDonationsManage')]
    public function test_a_role_without_donations_manage_cannot_change_anything(string $slug): void
    {
        $donation = Donation::factory()->create();
        $this->actingAsRole($slug);

        $this->postJson('/api/admin/donations', $this->payload())->assertForbidden();
        $this->putJson("/api/admin/donations/{$donation->id}", $this->payload())->assertForbidden();
        $this->postJson("/api/admin/donations/{$donation->id}/confirm")->assertForbidden();
        $this->postJson("/api/admin/donations/{$donation->id}/reverse", [
            'reversal_reason' => 'घुसपैठ',
        ])->assertForbidden();

        $this->assertSame(0, Donation::query()->whereNotNull('receipt_number')->count());
        $this->assertTrue($donation->fresh()?->isPending());
    }

    public function test_a_viewer_may_read_the_register_but_not_change_it(): void
    {
        Donation::factory()->confirmed()->create();
        $this->actingAsRole(Role::VIEWER);

        $this->getJson('/api/admin/donations')->assertOk();
        $this->postJson('/api/admin/donations', $this->payload())->assertForbidden();
    }

    public function test_a_treasurer_holds_both_keys_by_default(): void
    {
        // The seeded matrix encodes the specification's role prose: the
        // treasurer runs the money.
        $this->actingAsRole(Role::TREASURER);

        $this->getJson('/api/admin/donations')->assertOk();
        $this->postJson('/api/admin/donations', $this->payload())->assertStatus(201);
    }

    public function test_changing_the_bank_details_needs_the_money_permission_not_the_content_one(): void
    {
        // The single most valuable attack on this site is changing the UPI id
        // devotees pay into. A Content Manager can rewrite the About page and
        // must not be able to redirect the temple's donations
        // (PHASE_6_PLAN assumption N6).
        $this->actingAsRole(Role::CONTENT_MANAGER);

        $this->putJson('/api/admin/donation-settings', [
            'upi_id' => 'attacker@upi',
            'is_published' => true,
        ])->assertForbidden();

        $this->assertSame(0, DonationSetting::query()->count());
    }

    public function test_a_viewer_can_see_the_bank_details_but_not_change_them(): void
    {
        $this->actingAsRole(Role::VIEWER);

        $this->getJson('/api/admin/donation-settings')->assertOk();
        $this->putJson('/api/admin/donation-settings', [
            'upi_id' => 'attacker@upi',
        ])->assertForbidden();
    }

    public function test_granting_donations_manage_takes_effect_immediately(): void
    {
        $user = $this->actingAsRole(Role::VIEWER);
        $this->postJson('/api/admin/donations', $this->payload())->assertForbidden();

        $role = $user->role;
        $role->permissions = [...$role->effectivePermissions(), Permission::DONATIONS_MANAGE];
        $role->save();

        $this->actingAs($user->refresh(), 'web');
        $this->postJson('/api/admin/donations', $this->payload())->assertStatus(201);
    }

    public function test_a_deactivated_account_loses_access_even_with_the_permission(): void
    {
        $user = User::factory()->withRole(Role::TREASURER)->create();
        $this->actingAs($user, 'web');
        $this->getJson('/api/admin/donations')->assertOk();

        $user->forceFill(['status' => User::STATUS_INACTIVE])->save();

        $this->actingAs($user->refresh(), 'web');
        $this->getJson('/api/admin/donations')->assertStatus(403);
    }

    public function test_a_super_admin_passes_every_check(): void
    {
        $this->actingAsRole(Role::SUPER_ADMIN);

        $this->postJson('/api/admin/donations', $this->payload())->assertStatus(201);
        $this->putJson('/api/admin/donation-settings', ['upi_id' => 'temple@upi'])->assertOk();
    }
}

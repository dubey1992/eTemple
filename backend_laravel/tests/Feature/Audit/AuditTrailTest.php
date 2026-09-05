<?php

declare(strict_types=1);

namespace Tests\Feature\Audit;

use App\Models\AuditLog;
use App\Models\Donation;
use App\Models\Enquiry;
use App\Models\Role;
use App\Models\User;
use App\Support\AuditAction;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use RuntimeException;
use Tests\TestCase;

/**
 * The trail itself: what it records, what it refuses, and who may read it.
 */
class AuditTrailTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    private function treasurer(): User
    {
        return User::factory()->withRole(Role::TREASURER)->create();
    }

    // --- append-only ---------------------------------------------------------

    /**
     * A trail that can be edited is not a trail.
     *
     * Enforced by the model rather than by a database grant, because the
     * deployment target is shared hosting where the application's own database
     * user needs full rights for migrations to run (PHASE_11_PLAN S3).
     */
    public function test_an_entry_cannot_be_changed_once_written(): void
    {
        $this->actingAs($this->treasurer(), 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())
            ->assertCreated();

        $entry = AuditLog::query()->sole();

        $this->expectException(RuntimeException::class);
        $entry->update(['action' => AuditAction::DONATION_REVERSED]);
    }

    public function test_an_entry_cannot_be_deleted(): void
    {
        $this->actingAs($this->treasurer(), 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())
            ->assertCreated();

        $this->expectException(RuntimeException::class);
        AuditLog::query()->sole()->delete();
    }

    /** There is no endpoint that writes to it, at any permission. */
    public function test_the_api_offers_no_way_to_write_to_the_trail(): void
    {
        $this->actingAs(User::factory()->withRole(Role::SUPER_ADMIN)->create(), 'web');

        // 405 where a route exists for another verb, 404 where none does.
        // Either way there is no way in; what must never happen is a 2xx.
        foreach ([
            ['post', '/api/admin/audit-logs'],
            ['put', '/api/admin/audit-logs/1'],
            ['delete', '/api/admin/audit-logs/1'],
            ['patch', '/api/admin/audit-logs/1'],
        ] as [$method, $path]) {
            $response = $this->json($method, $path, []);

            $this->assertContains(
                $response->getStatusCode(),
                [404, 405],
                "{$method} {$path} answered {$response->getStatusCode()}",
            );
        }
    }

    /**
     * And no export.
     *
     * Every report in Phase 10 has three. This has none on purpose: the trail
     * carries donor names and enquiry references, and a downloadable audit
     * trail is a personal-data leak with an official-sounding name.
     */
    public function test_the_trail_cannot_be_exported(): void
    {
        $this->actingAs(User::factory()->withRole(Role::SUPER_ADMIN)->create(), 'web');

        $this->getJson('/api/admin/audit-logs/export?format=csv')->assertStatus(404);
        $this->getJson('/api/admin/reports/audit-logs')->assertStatus(404);
    }

    // --- what a row may contain ----------------------------------------------

    /**
     * No password, hash or token ever reaches the table.
     *
     * A hash in an audit row is a hash somebody can take away and attack
     * offline, and it answers no question worth asking.
     */
    public function test_no_entry_ever_carries_a_password_or_a_token(): void
    {
        $superAdmin = User::factory()->withRole(Role::SUPER_ADMIN)->create();

        $this->actingAs($superAdmin, 'web')
            ->postJson('/api/admin/users', [
                'first_name' => 'सीता',
                'email' => 'sita@thakurbari.test',
                'role_id' => (int) Role::query()->where('slug', Role::VIEWER)->value('id'),
            ])
            ->assertCreated();

        $rows = AuditLog::query()->get();
        $this->assertNotEmpty($rows);

        foreach ($rows as $row) {
            $encoded = mb_strtolower((string) json_encode([$row->before_data, $row->after_data]));

            foreach (['password', 'token', 'secret', 'remember'] as $forbidden) {
                $this->assertStringNotContainsString($forbidden, $encoded);
            }
        }
    }

    /** An edit records what changed, not the whole record. */
    public function test_an_edit_records_only_the_fields_that_changed(): void
    {
        $treasurer = $this->treasurer();

        $created = $this->actingAs($treasurer, 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())
            ->assertCreated()
            ->json('data.id');

        $this->actingAs($treasurer, 'web')
            ->putJson("/api/admin/donations/{$created}", $this->donationPayload(['amount' => '750']))
            ->assertOk();

        $edit = AuditLog::query()->where('action', AuditAction::DONATION_UPDATED)->sole();

        $this->assertSame(['amount_paise'], array_keys($edit->after_data ?? []));
        $this->assertSame(50000, $edit->before_data['amount_paise'] ?? null);
        $this->assertSame(75000, $edit->after_data['amount_paise'] ?? null);
    }

    /** A save that changed nothing is not an event. */
    public function test_an_edit_that_changes_nothing_writes_no_entry(): void
    {
        $treasurer = $this->treasurer();

        $created = $this->actingAs($treasurer, 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())
            ->assertCreated()
            ->json('data.id');

        $this->actingAs($treasurer, 'web')
            ->putJson("/api/admin/donations/{$created}", $this->donationPayload())
            ->assertOk();

        $this->assertSame(
            0,
            AuditLog::query()->where('action', AuditAction::DONATION_UPDATED)->count(),
        );
    }

    /** The actor's name is copied, so the trail outlives the account. */
    public function test_an_entry_still_names_its_actor_after_the_account_is_gone(): void
    {
        $treasurer = $this->treasurer();

        $this->actingAs($treasurer, 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())
            ->assertCreated();

        $name = $treasurer->fullName();
        $treasurer->delete();

        $entry = AuditLog::query()->sole();
        $this->assertNull($entry->user_id);
        $this->assertSame($name, $entry->actor_name);
    }

    // --- the money trail -----------------------------------------------------

    public function test_the_donation_lifecycle_is_recorded_end_to_end(): void
    {
        $treasurer = $this->treasurer();

        $id = $this->actingAs($treasurer, 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())
            ->assertCreated()
            ->json('data.id');

        $this->actingAs($treasurer, 'web')
            ->postJson("/api/admin/donations/{$id}/confirm")->assertOk();
        $this->actingAs($treasurer, 'web')
            ->postJson("/api/admin/donations/{$id}/reverse", ['reversal_reason' => 'दोहरी प्रविष्टि'])
            ->assertOk();

        $actions = AuditLog::query()->orderBy('id')->pluck('action')->all();

        $this->assertSame([
            AuditAction::DONATION_RECORDED,
            AuditAction::DONATION_CONFIRMED,
            AuditAction::DONATION_REVERSED,
        ], $actions);

        // The reason travels with it: "why was this removed from the books" is
        // the first question, and it should not need a second lookup.
        $reversal = AuditLog::query()->where('action', AuditAction::DONATION_REVERSED)->sole();
        $this->assertSame('दोहरी प्रविष्टि', $reversal->context);
    }

    /**
     * Phase 10 could not answer "who took the donor register".
     *
     * This is the row that answers it — recorded even though an export is a
     * GET, because what makes an action worth auditing is its consequence.
     */
    public function test_taking_a_copy_of_the_donor_register_is_recorded(): void
    {
        Donation::factory()->count(2)->create();

        $this->actingAs($this->treasurer(), 'web')
            ->get('/api/admin/reports/donations/export?format=csv&include_personal=1')
            ->assertOk();

        $entry = AuditLog::query()->where('action', AuditAction::REPORT_EXPORTED)->sole();

        $this->assertStringContainsString('.csv', (string) $entry->context);
        $this->assertStringContainsString('personal', (string) $entry->context);
    }

    /** Opening a villager's message is the one read that is recorded. */
    public function test_opening_an_enquiry_is_recorded(): void
    {
        $enquiry = Enquiry::factory()->create();

        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create(), 'web')
            ->getJson("/api/admin/enquiries/{$enquiry->id}")
            ->assertOk();

        $this->assertSame(
            1,
            AuditLog::query()->where('action', AuditAction::ENQUIRY_VIEWED)->count(),
        );
    }

    // --- who may read it -----------------------------------------------------

    public function test_a_super_admin_may_read_the_trail(): void
    {
        $this->actingAs($this->treasurer(), 'web')
            ->postJson('/api/admin/donations', $this->donationPayload())->assertCreated();

        $this->actingAs(User::factory()->withRole(Role::SUPER_ADMIN)->create(), 'web')
            ->getJson('/api/admin/audit-logs')
            ->assertOk()
            ->assertJsonPath('data.0.action', AuditAction::DONATION_RECORDED)
            ->assertJsonPath('data.0.action_label', AuditAction::label(AuditAction::DONATION_RECORDED));
    }

    /**
     * Everybody else is refused, including the Admin.
     *
     * The trail carries personal details, so it is a stricter thing to hand out
     * than the login history beside it. A committee that wants to widen it can,
     * in one screen.
     */
    public function test_every_other_role_is_refused_including_the_admin(): void
    {
        foreach ([Role::ADMIN, Role::TREASURER, Role::CONTENT_MANAGER, Role::VIEWER] as $slug) {
            $this->actingAs(User::factory()->withRole($slug)->create(), 'web')
                ->getJson('/api/admin/audit-logs')
                ->assertStatus(403);
        }
    }

    public function test_an_anonymous_visitor_is_refused(): void
    {
        $this->getJson('/api/admin/audit-logs')->assertStatus(401);
        $this->getJson('/api/admin/audit-logs/actions')->assertStatus(401);
    }

    /** @param array<string, mixed> $overrides */
    private function donationPayload(array $overrides = []): array
    {
        return array_merge([
            'donor_name' => 'रामप्रसाद यादव',
            'amount' => '500',
            'donation_date' => now()->toDateString(),
            'purpose' => 'general',
            'payment_mode' => 'cash',
        ], $overrides);
    }
}

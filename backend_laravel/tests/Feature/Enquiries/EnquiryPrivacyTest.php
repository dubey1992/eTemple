<?php

declare(strict_types=1);

namespace Tests\Feature\Enquiries;

use App\Mail\EnquiryAcknowledgement;
use App\Models\Enquiry;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Mail;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Who may read a villager's message, and who may not.
 *
 * The specification names enquiry data alongside donor data as something that
 * must not be exposed publicly. As with Phase 6, the strongest form of that is
 * that there is nowhere for it to come out — so the first test here is that the
 * obvious public paths do not exist at all, rather than that they filter well.
 *
 * Every authorization case calls the API directly with a role that should be
 * refused. Hiding a Flutter control is never the access control.
 */
class EnquiryPrivacyTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public static function publicPaths(): array
    {
        return [
            'list' => ['/api/public/enquiries'],
            'one by id' => ['/api/public/enquiries/1'],
            'one by reference' => ['/api/public/enquiries/RKT%2FE%2F2026-27%2F0001'],
            'count' => ['/api/public/enquiries/count'],
            'recent' => ['/api/public/enquiries/recent'],
        ];
    }

    #[DataProvider('publicPaths')]
    public function test_no_public_path_reads_an_enquiry(string $path): void
    {
        Enquiry::factory()->create([
            'name' => 'गुप्त नाम',
            'mobile' => '9998887776',
            'message' => 'यह संदेश कभी सार्वजनिक नहीं होना चाहिए।',
        ]);

        $response = $this->getJson($path);

        $this->assertContains($response->status(), [404, 405], $path.' answered a public read');
        $this->assertStringNotContainsString('गुप्त नाम', $response->getContent());
        $this->assertStringNotContainsString('9998887776', $response->getContent());
    }

    public function test_an_anonymous_visitor_cannot_open_the_inbox(): void
    {
        Enquiry::factory()->create();

        $this->getJson('/api/admin/enquiries')
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    /**
     * @return array<string, array{string}>
     */
    public static function refusedRoles(): array
    {
        return [
            // Money, not messages: a Treasurer has no reason to read a
            // villager's complaint (PHASE_7_PLAN assumption N9).
            'treasurer' => [Role::TREASURER],
            // And a Viewer least of all: content.view is not consent to read
            // somebody's telephone number.
            'viewer' => [Role::VIEWER],
        ];
    }

    #[DataProvider('refusedRoles')]
    public function test_a_role_without_enquiries_manage_cannot_read_the_inbox(string $slug): void
    {
        $enquiry = Enquiry::factory()->create(['name' => 'गुप्त नाम']);
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        foreach ([
            '/api/admin/enquiries',
            '/api/admin/enquiries/summary',
            "/api/admin/enquiries/{$enquiry->id}",
        ] as $path) {
            $response = $this->getJson($path)->assertStatus(403);
            $this->assertStringNotContainsString('गुप्त नाम', $response->getContent());
        }
    }

    #[DataProvider('refusedRoles')]
    public function test_a_role_without_enquiries_manage_cannot_change_one(string $slug): void
    {
        $enquiry = Enquiry::factory()->create();
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'status' => Enquiry::STATUS_RESOLVED,
        ])->assertStatus(403);

        $this->assertSame(Enquiry::STATUS_NEW, $enquiry->refresh()->status);
    }

    /**
     * @return array<string, array{string}>
     */
    public static function allowedRoles(): array
    {
        return [
            'admin' => [Role::ADMIN],
            'content manager' => [Role::CONTENT_MANAGER],
            'super admin' => [Role::SUPER_ADMIN],
        ];
    }

    #[DataProvider('allowedRoles')]
    public function test_a_role_with_enquiries_manage_can_read_and_answer(string $slug): void
    {
        $enquiry = Enquiry::factory()->create();
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->getJson('/api/admin/enquiries')->assertOk();
        $this->putJson("/api/admin/enquiries/{$enquiry->id}/status", [
            'status' => Enquiry::STATUS_IN_PROGRESS,
        ])->assertOk();
    }

    public function test_a_blocked_member_loses_the_inbox_even_with_the_right_role(): void
    {
        Enquiry::factory()->create();

        $this->actingAs(User::factory()->withRole(Role::ADMIN)->create([
            'status' => User::STATUS_BLOCKED,
        ]), 'web');

        $this->getJson('/api/admin/enquiries')->assertStatus(403);
    }

    public function test_no_acknowledgement_is_sent_unless_the_committee_turned_it_on(): void
    {
        Mail::fake();
        config(['enquiries.acknowledgement.enabled' => false]);

        $this->submit('devotee@example.test');

        Mail::assertNothingQueued();
        $this->assertNull(Enquiry::query()->firstOrFail()->acknowledged_at);
    }

    public function test_the_acknowledgement_is_queued_once_per_address(): void
    {
        Mail::fake();
        config([
            'enquiries.acknowledgement.enabled' => true,
            'enquiries.challenge_threshold' => 99,
            'enquiries.acknowledgement.per_address_cooldown_minutes' => 60,
        ]);

        $this->submit('devotee@example.test');
        $this->submit('devotee@example.test');

        // Twice submitted, once mailed: the address was typed by whoever filled
        // the form and need not be theirs (assumption N3).
        Mail::assertQueuedCount(1);
        Mail::assertQueued(EnquiryAcknowledgement::class);
    }

    public function test_the_acknowledgement_carries_none_of_the_senders_words(): void
    {
        config(['enquiries.acknowledgement.enabled' => true]);

        $enquiry = Enquiry::factory()->create([
            'name' => 'ATTACKER-SUPPLIED-NAME',
            'message' => 'ATTACKER-SUPPLIED-MESSAGE',
            'email' => 'victim@example.test',
        ]);

        $body = (new EnquiryAcknowledgement($enquiry))->render();

        $this->assertStringNotContainsString('ATTACKER-SUPPLIED-NAME', $body);
        $this->assertStringNotContainsString('ATTACKER-SUPPLIED-MESSAGE', $body);
        $this->assertStringContainsString($enquiry->reference, $body);
    }

    private function submit(string $email): void
    {
        $token = $this->getJson('/api/public/enquiry-form')->json('data.token');
        $this->travel(10)->seconds();

        $this->postJson('/api/public/enquiries', [
            'name' => 'सीता देवी',
            'email' => $email,
            'category' => 'general',
            'message' => 'मंदिर में आरती का समय क्या है? कृपया बताइए।',
            'form_token' => $token,
        ])->assertCreated();
    }

    protected function tearDown(): void
    {
        Cache::flush();
        parent::tearDown();
    }
}

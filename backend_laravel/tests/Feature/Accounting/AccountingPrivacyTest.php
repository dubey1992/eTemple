<?php

declare(strict_types=1);

namespace Tests\Feature\Accounting;

use App\Models\AccountingCategory;
use App\Models\AccountingSetting;
use App\Models\Donation;
use App\Models\Role;
use App\Models\Transaction;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * What the transparency page must never carry.
 *
 * Publishing the accounts is the phase's purpose; publishing the people in them
 * is not. These cases assert the line — no donor name, no payee, no individual
 * entry, and no path to a bill.
 */
class AccountingPrivacyTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        AccountingSetting::query()->create([
            'is_published' => true,
            'opening_balance_paise' => 0,
        ]);
    }

    /**
     * The Phase 8 report named this phase's shaping constraint as "what may be
     * shown about a named donor". The answer is nothing, and this is the test
     * that says so (PHASE_9_PLAN assumption N9).
     *
     * `is_anonymous` is deliberately false on both donors below: a default is
     * not consent, and the page must not publish a name whether or not the flag
     * happens to allow it.
     */
    public function test_no_donor_name_appears_in_the_public_response(): void
    {
        Donation::factory()->confirmed()->ofRupees(5_000)->create([
            'donor_name' => 'रामप्रसाद यादव',
            'donor_phone' => '9876543210',
            'is_anonymous' => false,
            'donation_date' => now()->subDays(10)->toDateString(),
        ]);
        Donation::factory()->confirmed()->ofRupees(1_000)->create([
            'donor_name' => 'Sita Devi',
            'is_anonymous' => true,
            'donation_date' => now()->subDays(10)->toDateString(),
        ]);

        $body = $this->getJson('/api/public/transparency')->assertOk()->getContent();

        $this->assertStringNotContainsString('रामप्रसाद', $body);
        $this->assertStringNotContainsString('Sita Devi', $body);
        $this->assertStringNotContainsString('9876543210', $body);
        $this->assertStringNotContainsString('receipt', $body);
    }

    public function test_no_payee_reference_or_description_appears_in_the_public_response(): void
    {
        $category = AccountingCategory::factory()->expense()->create();

        Transaction::factory()->approved()->ofRupees(9_000)->create([
            'category_id' => $category->id,
            'transaction_date' => now()->subDays(10)->toDateString(),
            'payee_name' => 'शर्मा इलेक्ट्रिकल्स',
            'reference_number' => 'CHQ-884412',
            'description' => 'तीन पंखे और वायरिंग',
        ]);

        $body = $this->getJson('/api/public/transparency')->assertOk()->getContent();

        $this->assertStringNotContainsString('शर्मा', $body);
        $this->assertStringNotContainsString('CHQ-884412', $body);
        $this->assertStringNotContainsString('पंखे', $body);
    }

    public function test_there_is_no_public_route_to_an_individual_entry(): void
    {
        $category = AccountingCategory::factory()->expense()->create();
        $transaction = Transaction::factory()->approved()->create(['category_id' => $category->id]);

        foreach ([
            '/api/public/transactions',
            "/api/public/transactions/{$transaction->id}",
            '/api/public/accounting-categories',
            "/api/public/transparency/{$transaction->id}",
            "/api/admin/transactions/{$transaction->id}",   // authentication, not obscurity
        ] as $path) {
            $response = $this->getJson($path);

            $this->assertContains(
                $response->getStatusCode(),
                [401, 403, 404, 405],
                "{$path} answered {$response->getStatusCode()}",
            );
            $this->assertStringNotContainsString('payee', $response->getContent());
        }
    }

    /**
     * The bill is private, and the path to it is never serialized — not to a
     * Viewer, not to a Treasurer, not to the Super Admin
     * (assumption N5).
     */
    public function test_the_attachment_path_is_never_serialized(): void
    {
        Storage::fake('local');

        $category = AccountingCategory::factory()->expense()->create();
        $treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $this->actingAs($treasurer, 'web');

        $id = $this->post('/api/admin/transactions', [
            'amount' => '1200',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $category->id,
            'payment_mode' => 'cash',
            'attachment' => UploadedFile::fake()->image('bill.jpg', 400, 300),
        ])->assertCreated()->json('data.id');

        $stored = Transaction::query()->findOrFail($id);
        $this->assertNotNull($stored->attachment_path);

        foreach ([
            "/api/admin/transactions/{$id}",
            '/api/admin/transactions',
        ] as $path) {
            $body = $this->getJson($path)->assertOk()->getContent();

            $this->assertStringNotContainsString($stored->attachment_path, $body);
            $this->assertStringNotContainsString('attachment_path', $body);
        }

        // What a client gets instead: that there is one, and its name.
        $this->getJson("/api/admin/transactions/{$id}")
            ->assertJsonPath('data.has_attachment', true)
            ->assertJsonPath('data.attachment_name', 'bill.jpg');
    }

    public function test_a_bill_is_not_reachable_without_signing_in(): void
    {
        Storage::fake('local');

        $category = AccountingCategory::factory()->expense()->create();
        $treasurer = User::factory()->withRole(Role::TREASURER)->create();
        $this->actingAs($treasurer, 'web');

        $id = $this->post('/api/admin/transactions', [
            'amount' => '1200',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $category->id,
            'payment_mode' => 'cash',
            'attachment' => UploadedFile::fake()->image('bill.jpg', 400, 300),
        ])->assertCreated()->json('data.id');

        $path = Transaction::query()->findOrFail($id)->attachment_path;

        // It is on the private disk, and not on the public one.
        Storage::disk('local')->assertExists($path);

        $this->app->make('auth')->forgetGuards();
        $this->flushSession();

        $this->getJson("/api/admin/transactions/{$id}/attachment")->assertStatus(401);

        // And the storage path is not a URL somebody can walk to. The refusal
        // a web server picks for a path outside the public root is its own
        // business; what matters is that the bytes are never served.
        $walked = $this->get('/storage/'.$path);
        $this->assertNotSame(200, $walked->getStatusCode());
    }
}

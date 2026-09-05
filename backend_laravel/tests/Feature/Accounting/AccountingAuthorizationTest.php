<?php

declare(strict_types=1);

namespace Tests\Feature\Accounting;

use App\Models\AccountingCategory;
use App\Models\Role;
use App\Models\Transaction;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Who may read the temple's books, and who may write in them.
 *
 * Every case calls the API directly with the role under test. Hiding a Flutter
 * control is never the access control.
 */
class AccountingAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    private AccountingCategory $category;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->category = AccountingCategory::factory()->expense()->create();
    }

    public function test_an_anonymous_visitor_cannot_open_the_ledger(): void
    {
        $this->getJson('/api/admin/transactions')
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'UNAUTHENTICATED');
    }

    /** @return array<string, array{string}> */
    public static function readingRoles(): array
    {
        return [
            'admin' => [Role::ADMIN],
            'treasurer' => [Role::TREASURER],
            // accounts.view, so the books can be audited without being changed.
            'viewer' => [Role::VIEWER],
        ];
    }

    #[DataProvider('readingRoles')]
    public function test_accounts_view_is_enough_to_read(string $slug): void
    {
        Transaction::factory()->create(['category_id' => $this->category->id]);
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->getJson('/api/admin/transactions')->assertOk();
        $this->getJson('/api/admin/transactions/summary')->assertOk();
        $this->getJson('/api/admin/accounting-categories')->assertOk();
        $this->getJson('/api/admin/accounting-settings')->assertOk();
    }

    /**
     * The specification says a Content Manager never sees sensitive financial
     * detail, so the refusal is on **reading**, not only on writing.
     */
    public function test_a_content_manager_cannot_see_the_books_at_all(): void
    {
        Transaction::factory()->create(['category_id' => $this->category->id]);
        $this->actingAs(User::factory()->withRole(Role::CONTENT_MANAGER)->create(), 'web');

        foreach ([
            '/api/admin/transactions',
            '/api/admin/transactions/summary',
            '/api/admin/accounting-categories',
            '/api/admin/accounting-settings',
        ] as $path) {
            $this->getJson($path)
                ->assertStatus(403)
                ->assertJsonPath('error.code', 'FORBIDDEN');
        }
    }

    /** @return array<string, array{string}> */
    public static function refusedWriters(): array
    {
        return [
            'viewer' => [Role::VIEWER],
            'content manager' => [Role::CONTENT_MANAGER],
        ];
    }

    #[DataProvider('refusedWriters')]
    public function test_recording_approving_and_reversing_need_accounts_manage(string $slug): void
    {
        $transaction = Transaction::factory()->create(['category_id' => $this->category->id]);
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->category->id,
            'payment_mode' => 'cash',
        ])->assertStatus(403);

        $this->postJson("/api/admin/transactions/{$transaction->id}/approve")->assertStatus(403);

        $this->postJson("/api/admin/transactions/{$transaction->id}/reverse", [
            'reversal_reason' => 'गलती से',
        ])->assertStatus(403);

        $this->assertTrue($transaction->fresh()->isPending());
    }

    #[DataProvider('refusedWriters')]
    public function test_publishing_the_accounts_needs_accounts_manage(string $slug): void
    {
        $this->actingAs(User::factory()->withRole($slug)->create(), 'web');

        $this->putJson('/api/admin/accounting-settings', ['is_published' => true])
            ->assertStatus(403);

        $this->assertDatabaseMissing('accounting_settings', ['is_published' => true]);
    }

    public function test_a_viewer_may_read_a_bill_because_that_is_what_auditing_is(): void
    {
        $this->actingAs(User::factory()->withRole(Role::VIEWER)->create(), 'web');

        $transaction = Transaction::factory()->create(['category_id' => $this->category->id]);

        // Permitted through, and refused only because there is no bill on it —
        // a 404 about the file, not a 403 about the person.
        $this->getJson("/api/admin/transactions/{$transaction->id}/attachment")
            ->assertStatus(404)
            ->assertJsonPath('error.code', 'NOT_FOUND');
    }

    public function test_a_treasurer_may_run_the_whole_lifecycle(): void
    {
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web');

        $id = $this->postJson('/api/admin/transactions', [
            'amount' => '500',
            'transaction_date' => now()->subDay()->toDateString(),
            'category_id' => $this->category->id,
            'payment_mode' => 'cash',
        ])->assertCreated()->json('data.id');

        $this->postJson("/api/admin/transactions/{$id}/approve")->assertOk();
        $this->postJson("/api/admin/transactions/{$id}/reverse", [
            'reversal_reason' => 'दोबारा दर्ज',
        ])->assertOk();
    }

    public function test_the_public_endpoint_needs_nobody_to_sign_in(): void
    {
        $this->getJson('/api/public/transparency')->assertOk();
    }
}

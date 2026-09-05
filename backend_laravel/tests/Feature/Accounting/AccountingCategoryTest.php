<?php

declare(strict_types=1);

namespace Tests\Feature\Accounting;

use App\Models\AccountingCategory;
use App\Models\Role;
use App\Models\Transaction;
use App\Models\User;
use App\Support\TransactionType;
use Database\Seeders\AccountingCategorySeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The headings the books are filed under, and the rules that stop history being
 * rewritten by editing one.
 */
class AccountingCategoryTest extends TestCase
{
    use RefreshDatabase;

    private User $treasurer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->treasurer = User::factory()->withRole(Role::TREASURER)->create();
    }

    public function test_a_category_that_has_never_been_used_may_be_removed(): void
    {
        $category = AccountingCategory::factory()->expense()->create();
        $this->actingAs($this->treasurer, 'web');

        $this->deleteJson("/api/admin/accounting-categories/{$category->id}")
            ->assertStatus(204);

        $this->assertDatabaseMissing('accounting_categories', ['id' => $category->id]);
    }

    /**
     * Deleting a used heading would turn old entries into "₹12,000, heading:
     * —", which is exactly what a ledger exists to prevent
     * (PHASE_9_PLAN assumption N4).
     */
    public function test_a_category_in_use_is_refused_and_offered_deactivation_instead(): void
    {
        $category = AccountingCategory::factory()->expense()->create();
        Transaction::factory()->count(2)->create(['category_id' => $category->id]);

        $this->actingAs($this->treasurer, 'web');

        $response = $this->deleteJson("/api/admin/accounting-categories/{$category->id}")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'TRANSACTION_LOCKED');

        // The message names the count and says what to do instead.
        $this->assertStringContainsString('2', $response->json('error.message'));
        $this->assertStringContainsString('Deactivate', $response->json('error.message'));

        $this->assertDatabaseHas('accounting_categories', ['id' => $category->id]);

        // Deactivation works, and leaves the entries readable.
        $this->putJson("/api/admin/accounting-categories/{$category->id}", [
            'type' => $category->type,
            'name_hi' => $category->name_hi,
            'is_active' => false,
        ])->assertOk()->assertJsonPath('data.is_active', false);

        $this->assertSame(2, Transaction::query()->where('category_id', $category->id)->count());
    }

    /**
     * Flipping a used heading from expense to income would move every entry
     * filed under it to the other side of the books — silently, in figures the
     * village has already read.
     */
    public function test_the_type_of_a_used_category_cannot_be_changed(): void
    {
        $category = AccountingCategory::factory()->expense()->create();
        Transaction::factory()->create(['category_id' => $category->id]);

        $this->actingAs($this->treasurer, 'web');

        $this->putJson("/api/admin/accounting-categories/{$category->id}", [
            'type' => TransactionType::INCOME,
            'name_hi' => $category->name_hi,
        ])
            ->assertOk()
            // Ignored, not obeyed.
            ->assertJsonPath('data.type', TransactionType::EXPENSE);

        $this->assertSame(TransactionType::EXPENSE, $category->fresh()->type);
    }

    public function test_an_unused_category_may_still_change_side(): void
    {
        $category = AccountingCategory::factory()->expense()->create();
        $this->actingAs($this->treasurer, 'web');

        $this->putJson("/api/admin/accounting-categories/{$category->id}", [
            'type' => TransactionType::INCOME,
            'name_hi' => $category->name_hi,
        ])
            ->assertOk()
            ->assertJsonPath('data.type', TransactionType::INCOME);
    }

    public function test_the_donation_code_is_reserved(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/accounting-categories', [
            'code' => 'donation',
            'type' => TransactionType::INCOME,
            'name_hi' => 'दान',
        ])
            ->assertStatus(422)
            ->assertJsonStructure(['error' => ['details' => ['code']]]);

        $this->assertDatabaseMissing('accounting_categories', ['code' => 'donation']);
    }

    public function test_hindi_is_required_and_english_is_not(): void
    {
        $this->actingAs($this->treasurer, 'web');

        $this->postJson('/api/admin/accounting-categories', [
            'type' => TransactionType::EXPENSE,
            'name_en' => 'Flowers only',
        ])->assertStatus(422);

        $this->postJson('/api/admin/accounting-categories', [
            'type' => TransactionType::EXPENSE,
            'name_hi' => 'फूल एवं माला',
        ])
            ->assertCreated()
            // Absent means absent — never filled in with a copy of the Hindi.
            ->assertJsonPath('data.name_en', null);
    }

    public function test_the_seeded_headings_are_idempotent_and_contain_no_donation_category(): void
    {
        $this->seed(AccountingCategorySeeder::class);
        $first = AccountingCategory::query()->count();

        $this->seed(AccountingCategorySeeder::class);

        $this->assertSame($first, AccountingCategory::query()->count());
        $this->assertGreaterThan(0, $first);
        $this->assertDatabaseMissing('accounting_categories', ['code' => 'donation']);
    }

    public function test_a_renamed_heading_survives_reseeding(): void
    {
        $this->seed(AccountingCategorySeeder::class);

        AccountingCategory::query()->where('code', 'utilities')->update([
            'name_hi' => 'बिजली का बिल',
        ]);

        $this->seed(AccountingCategorySeeder::class);

        $this->assertSame(
            'बिजली का बिल',
            AccountingCategory::query()->where('code', 'utilities')->value('name_hi'),
        );
    }
}

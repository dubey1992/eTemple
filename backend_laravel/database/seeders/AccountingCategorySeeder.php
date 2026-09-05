<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\AccountingCategory;
use App\Support\TransactionType;
use Illuminate\Database\Seeder;

/**
 * Production-safe structural scaffolding, like {@see PageStructureSeeder}.
 *
 * These are **headings, not content**. A ledger with no categories cannot
 * record its first transaction, so the temple would begin by inventing a
 * classification scheme before it could enter an electricity bill. The set
 * below is the ordinary one for a village temple; every row is editable and
 * deactivatable, and none of it asserts anything about this temple's finances.
 *
 * The reserved `donation` code is deliberately **not** seeded: donated income
 * is counted from the donation register, and a category by that name would
 * invite somebody to enter it twice (PHASE_9_PLAN assumption N1).
 *
 * Idempotent — an existing category is never overwritten, so a committee that
 * has renamed "अन्य व्यय" keeps its name across deployments.
 */
class AccountingCategorySeeder extends Seeder
{
    /** @var list<array{code: string, type: string, name_hi: string, name_en: string}> */
    private const CATEGORIES = [
        // Income other than donations.
        ['code' => 'hall-hire', 'type' => TransactionType::INCOME, 'name_hi' => 'हॉल एवं परिसर किराया', 'name_en' => 'Hall and premises hire'],
        ['code' => 'interest', 'type' => TransactionType::INCOME, 'name_hi' => 'बैंक ब्याज', 'name_en' => 'Bank interest'],
        ['code' => 'grant', 'type' => TransactionType::INCOME, 'name_hi' => 'अनुदान', 'name_en' => 'Grants'],
        ['code' => 'other-income', 'type' => TransactionType::INCOME, 'name_hi' => 'अन्य आय', 'name_en' => 'Other income'],

        // Expenditure.
        ['code' => 'puja-materials', 'type' => TransactionType::EXPENSE, 'name_hi' => 'पूजा सामग्री', 'name_en' => 'Worship materials'],
        ['code' => 'utilities', 'type' => TransactionType::EXPENSE, 'name_hi' => 'बिजली एवं पानी', 'name_en' => 'Electricity and water'],
        ['code' => 'maintenance', 'type' => TransactionType::EXPENSE, 'name_hi' => 'रखरखाव एवं मरम्मत', 'name_en' => 'Upkeep and repairs'],
        ['code' => 'salaries', 'type' => TransactionType::EXPENSE, 'name_hi' => 'वेतन एवं मानदेय', 'name_en' => 'Salaries and honoraria'],
        ['code' => 'annadan', 'type' => TransactionType::EXPENSE, 'name_hi' => 'भंडारा एवं प्रसाद', 'name_en' => 'Community meals and prasad'],
        ['code' => 'festival', 'type' => TransactionType::EXPENSE, 'name_hi' => 'त्योहार एवं आयोजन', 'name_en' => 'Festivals and events'],
        ['code' => 'construction', 'type' => TransactionType::EXPENSE, 'name_hi' => 'निर्माण कार्य', 'name_en' => 'Construction'],
        ['code' => 'other-expense', 'type' => TransactionType::EXPENSE, 'name_hi' => 'अन्य व्यय', 'name_en' => 'Other expenditure'],
    ];

    public function run(): void
    {
        foreach (self::CATEGORIES as $index => $category) {
            AccountingCategory::query()->firstOrCreate(
                ['code' => $category['code']],
                [
                    'type' => $category['type'],
                    'name_hi' => $category['name_hi'],
                    'name_en' => $category['name_en'],
                    'sort_order' => $index * 10,
                    'is_active' => true,
                ],
            );
        }
    }
}

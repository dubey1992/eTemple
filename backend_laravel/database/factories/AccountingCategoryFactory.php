<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\AccountingCategory;
use App\Support\TransactionType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AccountingCategory>
 */
class AccountingCategoryFactory extends Factory
{
    protected $model = AccountingCategory::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'code' => 'cat-'.$this->faker->unique()->numberBetween(1, 999_999),
            'type' => TransactionType::EXPENSE,
            'name_hi' => 'पूजा सामग्री',
            'name_en' => 'Worship materials',
            'description_hi' => null,
            'description_en' => null,
            'sort_order' => 0,
            'is_active' => true,
        ];
    }

    public function income(): static
    {
        return $this->state(fn () => [
            'type' => TransactionType::INCOME,
            'name_hi' => 'हॉल किराया',
            'name_en' => 'Hall hire',
        ]);
    }

    public function expense(): static
    {
        return $this->state(fn () => ['type' => TransactionType::EXPENSE]);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }

    public function code(string $code): static
    {
        return $this->state(fn () => ['code' => $code]);
    }

    /** A category with no English name, for the Hindi-fallback tests. */
    public function hindiOnly(): static
    {
        return $this->state(fn () => ['name_en' => null, 'description_en' => null]);
    }
}

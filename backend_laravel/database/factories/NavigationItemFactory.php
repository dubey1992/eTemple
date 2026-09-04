<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\NavigationItem;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<NavigationItem>
 */
class NavigationItemFactory extends Factory
{
    protected $model = NavigationItem::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'label_hi' => 'मुख पृष्ठ',
            'label_en' => 'Home',
            'route' => '/',
            'sort_order' => 0,
            'is_visible' => true,
        ];
    }

    public function hidden(): static
    {
        return $this->state(fn () => ['is_visible' => false]);
    }
}

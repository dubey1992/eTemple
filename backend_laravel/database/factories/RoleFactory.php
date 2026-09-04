<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Role;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Role>
 */
class RoleFactory extends Factory
{
    protected $model = Role::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        $slug = $this->faker->unique()->slug(2);

        return [
            'slug' => $slug,
            'name' => ucwords(str_replace('-', ' ', $slug)),
            'description' => $this->faker->sentence(),
            'permissions' => null,
            'status' => Role::STATUS_ACTIVE,
        ];
    }

    public function superAdmin(): static
    {
        return $this->state(fn () => [
            'slug' => Role::SUPER_ADMIN,
            'name' => 'Super Admin',
        ]);
    }

    public function viewer(): static
    {
        return $this->state(fn () => [
            'slug' => Role::VIEWER,
            'name' => 'Viewer',
        ]);
    }
}

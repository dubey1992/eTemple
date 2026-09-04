<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    /** Password used by tests only; never a production default. */
    public const TEST_PASSWORD = 'password-for-tests';

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'first_name' => $this->faker->firstName(),
            'last_name' => $this->faker->lastName(),
            'email' => $this->faker->unique()->safeEmail(),
            'mobile' => null,
            'password' => self::TEST_PASSWORD,
            'role_id' => Role::query()->firstOrCreate(
                ['slug' => Role::VIEWER],
                ['name' => 'Viewer', 'status' => Role::STATUS_ACTIVE],
            )->id,
            'status' => User::STATUS_ACTIVE,
        ];
    }

    /**
     * Nullable audit columns are deliberately not mass-assignable, so set them
     * explicitly here. Without this a factory-built model lacks the attribute
     * entirely and Model::preventAccessingMissingAttributes() rejects any read
     * of it - which is a test artefact, since a model loaded from the database
     * always carries every column.
     */
    public function configure(): static
    {
        return $this->afterMaking(function (User $user) {
            $user->forceFill(['last_login_at' => null, 'remember_token' => null]);
        });
    }

    public function withRole(string $slug): static
    {
        return $this->state(fn () => [
            'role_id' => Role::query()->firstOrCreate(
                ['slug' => $slug],
                ['name' => ucwords(str_replace('-', ' ', $slug)), 'status' => Role::STATUS_ACTIVE],
            )->id,
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['status' => User::STATUS_INACTIVE]);
    }

    public function blocked(): static
    {
        return $this->state(fn () => ['status' => User::STATUS_BLOCKED]);
    }
}

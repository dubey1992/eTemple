<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\LoginAttempt;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<LoginAttempt>
 */
class LoginAttemptFactory extends Factory
{
    protected $model = LoginAttempt::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'user_id' => null,
            'email' => $this->faker->unique()->safeEmail(),
            'outcome' => LoginAttempt::OUTCOME_SUCCESS,
            'ip_address' => '127.0.0.1',
            'user_agent' => 'PHPUnit',
        ];
    }

    public function failed(): static
    {
        return $this->state(fn () => ['outcome' => LoginAttempt::OUTCOME_INVALID_CREDENTIALS]);
    }
}

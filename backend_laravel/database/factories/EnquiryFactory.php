<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Enquiry;
use App\Support\EnquiryCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Enquiry>
 */
class EnquiryFactory extends Factory
{
    protected $model = Enquiry::class;

    /**
     * The safe default: a new, unassigned enquiry with a Hindi reply requested.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'reference' => $this->uniqueReference(),
            'name' => 'सीता देवी',
            'mobile' => '9876500011',
            'email' => null,
            'category' => EnquiryCategory::GENERAL,
            'message' => 'मंदिर में सुबह की आरती किस समय होती है? कृपया बताएं।',
            'preferred_language' => 'hi',
            'status' => Enquiry::STATUS_NEW,
            'assigned_to' => null,
            'resolved_at' => null,
            'resolved_by' => null,
            'submitted_ip_hash' => null,
            'submitted_user_agent' => null,
            'acknowledged_at' => null,
        ];
    }

    public function inProgress(): static
    {
        return $this->state(fn () => ['status' => Enquiry::STATUS_IN_PROGRESS]);
    }

    public function resolved(): static
    {
        return $this->state(fn () => [
            'status' => Enquiry::STATUS_RESOLVED,
            'resolved_at' => now(),
        ]);
    }

    public function spam(): static
    {
        return $this->state(fn () => ['status' => Enquiry::STATUS_SPAM]);
    }

    /**
     * A reference that will not collide inside one test.
     *
     * Not the real generator: a factory that ran the sequence would couple
     * every test's fixtures to the numbering rules, and the numbering rules
     * have their own tests.
     */
    private function uniqueReference(): string
    {
        return 'RKT/E/TEST/'.str_pad((string) $this->faker->unique()->numberBetween(1, 999999), 6, '0', STR_PAD_LEFT);
    }
}

<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\SiteSetting;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SiteSetting>
 */
class SiteSettingFactory extends Factory
{
    protected $model = SiteSetting::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'tagline_hi' => 'भक्ति और सेवा का केंद्र',
            'tagline_en' => 'A place of devotion and service',
            'contact_phone' => null,
            'contact_email' => null,
        ];
    }

    public function configure(): static
    {
        return $this->afterMaking(function (SiteSetting $settings) {
            $settings->forceFill(['updated_by' => null]);
        });
    }
}

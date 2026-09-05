<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\TempleProfile;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TempleProfile>
 */
class TempleProfileFactory extends Factory
{
    protected $model = TempleProfile::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'name_hi' => 'परीक्षण मंदिर',
            'name_en' => 'Test Temple',
            'history_hi' => 'हिन्दी इतिहास का एक अनुच्छेद।',
            'history_en' => 'A paragraph of English history.',
            'mission_hi' => 'हिन्दी उद्देश्य।',
            'mission_en' => 'English mission.',
            'address_line1_hi' => 'तालाब के पास',
            'address_line1_en' => 'Near the village pond',
            'address_line2_hi' => null,
            'address_line2_en' => null,
            'village_hi' => 'परीक्षण ग्राम',
            'village_en' => 'Test Village',
            'panchayat_hi' => 'परीक्षण पंचायत',
            'panchayat_en' => 'Test Panchayat',
            'police_station_hi' => 'परीक्षण थाना',
            'police_station_en' => 'Test PS',
            'district_hi' => 'परीक्षण जिला',
            'district_en' => 'Test District',
            'state_hi' => 'बिहार',
            'state_en' => 'Bihar',
            'postal_code' => '813204',
            'country_hi' => 'भारत',
            'country_en' => 'India',
            'logo_url' => null,
            'map_url' => null,
            'established_year' => null,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (TempleProfile $profile) {
            $profile->forceFill(['updated_by' => null]);
        });
    }

    /** A profile that exists only in Hindi, to exercise the fallback rule. */
    public function hindiOnly(): static
    {
        return $this->state(fn () => [
            'name_en' => null,
            'history_en' => null,
            'mission_en' => null,
            'address_line1_en' => null,
            'village_en' => null,
            'panchayat_en' => null,
            'police_station_en' => null,
            'district_en' => null,
            'state_en' => null,
            'country_en' => null,
        ]);
    }

    /** A brand-new, never-configured profile. */
    public function empty(): static
    {
        return $this->state(fn () => [
            'name_hi' => null,
            'name_en' => null,
            'history_hi' => null,
            'history_en' => null,
            'mission_hi' => null,
            'mission_en' => null,
            'address_line1_hi' => null,
            'address_line1_en' => null,
            'village_hi' => null,
            'village_en' => null,
            'panchayat_hi' => null,
            'panchayat_en' => null,
            'police_station_hi' => null,
            'police_station_en' => null,
            'district_hi' => null,
            'district_en' => null,
            'state_hi' => null,
            'state_en' => null,
            'postal_code' => null,
            'country_hi' => null,
            'country_en' => null,
        ]);
    }
}

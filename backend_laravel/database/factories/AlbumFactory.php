<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Album;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Album>
 */
class AlbumFactory extends Factory
{
    protected $model = Album::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'title_hi' => 'परीक्षण एल्बम',
            'title_en' => 'Test album',
            'description_hi' => 'हिन्दी विवरण।',
            'description_en' => 'English description.',
            'slug' => $this->faker->unique()->slug(2),
            'cover_media_id' => null,
            'sort_order' => 0,
            'status' => Album::STATUS_DRAFT,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (Album $album) {
            $album->forceFill([
                'created_by' => $album->created_by ?? null,
                'updated_by' => $album->updated_by ?? null,
            ]);
        });
    }

    public function published(): static
    {
        return $this->state(fn () => ['status' => Album::STATUS_PUBLISHED]);
    }
}

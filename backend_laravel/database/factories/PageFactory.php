<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Page;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Page>
 */
class PageFactory extends Factory
{
    protected $model = Page::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'slug' => Str::slug($this->faker->unique()->words(2, true)),
            'title_hi' => 'हिन्दी शीर्षक',
            'title_en' => 'English title',
            'content_hi' => 'हिन्दी सामग्री का एक अनुच्छेद।',
            'content_en' => 'A paragraph of English content.',
            'meta_title_hi' => null,
            'meta_title_en' => null,
            'meta_description_hi' => null,
            'meta_description_en' => null,
            'status' => Page::STATUS_DRAFT,
            'published_at' => null,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (Page $page) {
            $page->forceFill(['updated_by' => null]);
        });
    }

    public function published(): static
    {
        return $this->state(fn () => [
            'status' => Page::STATUS_PUBLISHED,
            'published_at' => now()->subDay(),
        ]);
    }

    /** A page that exists only in Hindi, to exercise the fallback rule. */
    public function hindiOnly(): static
    {
        return $this->state(fn () => [
            'title_en' => null,
            'content_en' => null,
            'meta_title_en' => null,
            'meta_description_en' => null,
        ]);
    }
}

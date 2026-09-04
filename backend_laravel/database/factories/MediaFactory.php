<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Media;
use App\Support\MediaType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Media>
 */
class MediaFactory extends Factory
{
    protected $model = Media::class;

    /**
     * The safe default: an unpublished photograph. A test that wants something
     * public has to ask, the same way the committee does.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $stem = 'media/2026/09/'.$this->faker->unique()->lexify('????????');

        return [
            'album_id' => null,
            'media_type' => MediaType::PHOTO,
            'title_hi' => 'परीक्षण चित्र',
            'title_en' => 'Test photograph',
            'caption_hi' => 'हिन्दी शीर्षक।',
            'caption_en' => 'English caption.',
            'file_path' => $stem.'-lg.jpg',
            'large_path' => $stem.'-lg.jpg',
            'medium_path' => $stem.'-md.jpg',
            'thumb_path' => $stem.'-sm.jpg',
            'external_url' => null,
            'provider' => null,
            'provider_ref' => null,
            'thumbnail_url' => null,
            'mime_type' => 'image/jpeg',
            'byte_size' => 240_000,
            'width' => 1920,
            'height' => 1280,
            'original_name' => 'temple.jpg',
            'checksum' => hash('sha256', $stem),
            'sort_order' => 0,
            'status' => Media::STATUS_DRAFT,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (Media $media) {
            $media->forceFill([
                'uploaded_by' => $media->uploaded_by ?? null,
                'updated_by' => $media->updated_by ?? null,
            ]);
        });
    }

    public function published(): static
    {
        return $this->state(fn () => ['status' => Media::STATUS_PUBLISHED]);
    }

    /** A linked video: no stored file at all (assumption M1). */
    public function video(string $reference = 'dQw4w9WgXcQ'): static
    {
        return $this->state(fn () => [
            'media_type' => MediaType::VIDEO,
            'title_hi' => 'संध्या आरती दर्शन',
            'title_en' => 'Evening aarti darshan',
            'file_path' => null,
            'large_path' => null,
            'medium_path' => null,
            'thumb_path' => null,
            'mime_type' => null,
            'byte_size' => null,
            'width' => null,
            'height' => null,
            'original_name' => null,
            'checksum' => null,
            'external_url' => 'https://www.youtube.com/watch?v='.$reference,
            'provider' => 'youtube',
            'provider_ref' => $reference,
            'thumbnail_url' => 'https://i.ytimg.com/vi/'.$reference.'/hqdefault.jpg',
        ]);
    }

    /** A photograph small enough that no smaller variant was ever written. */
    public function singleVariant(): static
    {
        return $this->state(fn () => [
            'medium_path' => null,
            'thumb_path' => null,
            'width' => 400,
            'height' => 300,
        ]);
    }

    public function hindiOnly(): static
    {
        return $this->state(fn () => ['title_en' => null, 'caption_en' => null]);
    }
}

<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\AlbumFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A named group of photographs — "Janmashtami 2026" (spec Phase 5, optional).
 *
 * Deleting an album never deletes its photographs: an album is an arrangement,
 * and losing an arrangement must not lose the content (PHASE_5_PLAN assumption
 * M6). The `media.album_id` foreign key is `nullOnDelete` for exactly that.
 *
 * @property int $id
 * @property string $title_hi
 * @property string $slug
 * @property int|null $cover_media_id
 * @property string $status
 * @property int $sort_order
 */
class Album extends Model
{
    /** @use HasFactory<AlbumFactory> */
    use HasFactory;

    public const STATUS_DRAFT = 'draft';

    public const STATUS_PUBLISHED = 'published';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [self::STATUS_DRAFT, self::STATUS_PUBLISHED];
    }

    /** @var list<string> */
    protected $fillable = [
        'title_hi', 'title_en',
        'description_hi', 'description_en',
        'slug', 'cover_media_id', 'sort_order', 'status',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['sort_order' => 'integer'];
    }

    /** @return HasMany<Media, $this> */
    public function media(): HasMany
    {
        return $this->hasMany(Media::class);
    }

    /** @return BelongsTo<Media, $this> */
    public function cover(): BelongsTo
    {
        return $this->belongsTo(Media::class, 'cover_media_id');
    }

    public function isPublished(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }

    /**
     * @param  Builder<Album>  $query
     * @return Builder<Album>
     */
    public function scopePubliclyVisible(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PUBLISHED);
    }
}

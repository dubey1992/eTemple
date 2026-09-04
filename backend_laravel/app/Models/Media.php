<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\MediaType;
use Database\Factories\MediaFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

/**
 * One photograph or one linked video (spec Phase 5 entity).
 *
 * Paths are stored **disk-relative**; the absolute URL is derived on read from
 * the configured disk, so moving the site to a new domain or to object storage
 * is a config change rather than a data migration (PHASE_5_PLAN assumption M5).
 *
 * @property int $id
 * @property string $media_type
 * @property string $title_hi
 * @property string|null $file_path
 * @property string|null $thumb_path
 * @property string|null $medium_path
 * @property string|null $large_path
 * @property string|null $external_url
 * @property string $status
 * @property int $sort_order
 */
class Media extends Model
{
    /** @use HasFactory<MediaFactory> */
    use HasFactory;

    /** Laravel would otherwise pluralise this to `medias`. */
    protected $table = 'media';

    public const STATUS_DRAFT = 'draft';

    public const STATUS_PUBLISHED = 'published';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [self::STATUS_DRAFT, self::STATUS_PUBLISHED];
    }

    /** @var list<string> */
    protected $fillable = [
        'album_id',
        'media_type',
        'title_hi', 'title_en',
        'caption_hi', 'caption_en',
        'file_path', 'thumb_path', 'medium_path', 'large_path',
        'external_url', 'provider', 'provider_ref', 'thumbnail_url',
        'mime_type', 'byte_size', 'width', 'height',
        'original_name', 'checksum',
        'sort_order', 'status',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'byte_size' => 'integer',
            'width' => 'integer',
            'height' => 'integer',
            'sort_order' => 'integer',
        ];
    }

    /** @return BelongsTo<Album, $this> */
    public function album(): BelongsTo
    {
        return $this->belongsTo(Album::class);
    }

    /** @return BelongsTo<User, $this> */
    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function isPhoto(): bool
    {
        return $this->media_type === MediaType::PHOTO;
    }

    public function isVideo(): bool
    {
        return $this->media_type === MediaType::VIDEO;
    }

    public function isPublished(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }

    /**
     * Absolute URL for one stored variant, falling back down the sizes.
     *
     * An image smaller than a variant's bound was never upscaled, so `large`
     * legitimately resolves to `medium` for a small photograph (assumption M4).
     */
    public function variantUrl(string $variant): ?string
    {
        $path = match ($variant) {
            'thumb' => $this->thumb_path ?? $this->medium_path ?? $this->large_path,
            'medium' => $this->medium_path ?? $this->large_path ?? $this->thumb_path,
            default => $this->large_path ?? $this->medium_path ?? $this->thumb_path,
        };

        return self::url($path);
    }

    /**
     * The player URL for a linked video.
     *
     * Built from the stored provider reference, never from anything an admin
     * typed: an arbitrary iframe source out of an admin form is a stored-XSS
     * vector, and an 11-character video id is not (assumption M1). The
     * no-cookie host is used so a visitor reading the gallery is not tracked by
     * a third party before they have pressed play.
     */
    public function embedUrl(): ?string
    {
        if (! $this->isVideo() || $this->provider_ref === null) {
            return null;
        }

        return 'https://www.youtube-nocookie.com/embed/'.$this->provider_ref;
    }

    /** The canonical file URL — the largest stored variant of a photograph. */
    public function fileUrl(): ?string
    {
        return self::url($this->file_path ?? $this->large_path);
    }

    /**
     * Every URL this row occupies, for the deletion guard and for reference
     * checks against `poster_url`, `photo_url` and `logo_url`.
     *
     * @return list<string>
     */
    public function urls(): array
    {
        $urls = [
            self::url($this->file_path),
            self::url($this->large_path),
            self::url($this->medium_path),
            self::url($this->thumb_path),
            $this->external_url,
        ];

        return array_values(array_unique(array_filter(
            $urls,
            static fn (?string $url) => $url !== null && $url !== '',
        )));
    }

    /** Disk-relative paths, for deleting the stored bytes. @return list<string> */
    public function storedPaths(): array
    {
        return array_values(array_unique(array_filter([
            $this->file_path,
            $this->large_path,
            $this->medium_path,
            $this->thumb_path,
        ])));
    }

    /** Builds an absolute URL from a disk-relative path. */
    public static function url(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }

        // Already absolute: a video thumbnail supplied by the provider.
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return Storage::disk((string) config('media.disk'))->url($path);
    }

    /**
     * What a visitor may see: published only, filtered in the query rather than
     * the serializer, so a draft cannot leak through a presentation mistake
     * (assumption M9).
     *
     * @param  Builder<Media>  $query
     * @return Builder<Media>
     */
    public function scopePubliclyVisible(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PUBLISHED);
    }

    /**
     * The committee's arrangement first, then newest — so anything unarranged
     * still appears in a sensible order.
     *
     * @param  Builder<Media>  $query
     * @return Builder<Media>
     */
    public function scopeInGalleryOrder(Builder $query): Builder
    {
        return $query->orderBy('sort_order')->orderByDesc('id');
    }
}

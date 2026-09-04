<?php

declare(strict_types=1);

namespace App\Services\Media;

use App\Exceptions\MediaGuardException;
use App\Models\Album;
use App\Models\CommitteeMember;
use App\Models\Event;
use App\Models\Media;
use App\Models\Page;
use App\Models\TempleProfile;
use App\Models\User;
use App\Support\MediaType;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Business rules for the gallery: what a visitor sees, what an editor may
 * change, and — the part that matters — what may not be deleted.
 *
 * Uploading and stripping live in {@see ImageProcessor}; this class decides.
 */
class MediaService
{
    /** Largest page the public gallery will serve (PHASE_5_PLAN assumption M10). */
    public const MAX_PER_PAGE = 60;

    public const DEFAULT_PER_PAGE = 24;

    public function __construct(private readonly ImageProcessor $images) {}

    /**
     * The published gallery, paginated.
     *
     * An unbounded response is the same denial-of-service the Phase 4 window
     * cap prevents, and worse here because every row carries three URLs.
     *
     * @param  array{type?: string, album?: string, per_page?: int}  $filters
     * @return LengthAwarePaginator<int, Media>
     */
    public function publicList(array $filters = []): LengthAwarePaginator
    {
        $perPage = max(1, min(
            $filters['per_page'] ?? self::DEFAULT_PER_PAGE,
            self::MAX_PER_PAGE,
        ));

        $query = Media::query()->publiclyVisible();

        if (isset($filters['type']) && MediaType::exists($filters['type'])) {
            $query->where('media_type', $filters['type']);
        }

        if (isset($filters['album']) && $filters['album'] !== '') {
            // An album that is not published shows no photographs publicly,
            // even if the photographs themselves are published: the album is
            // the arrangement the committee has not finished.
            $album = Album::query()->publiclyVisible()
                ->where('slug', $filters['album'])->first();

            $query->where('album_id', $album?->id ?? 0);
        }

        return $query->inGalleryOrder()->paginate($perPage);
    }

    /** One published item, or null. A draft is indistinguishable from absent. */
    public function publiclyVisibleById(int $id): ?Media
    {
        return Media::query()->publiclyVisible()->whereKey($id)->first();
    }

    /**
     * Published albums, each with its cover, in display order.
     *
     * @return Collection<int, Album>
     */
    public function publicAlbums(): Collection
    {
        return Album::query()
            ->publiclyVisible()
            ->with('cover')
            ->withCount(['media' => fn (Builder $q) => $q->where('status', Media::STATUS_PUBLISHED)])
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->get();
    }

    /**
     * The whole library, including drafts.
     *
     * @param  array{status?: string, type?: string, album?: int}  $filters
     * @return Collection<int, Media>
     */
    public function adminList(array $filters = []): Collection
    {
        $query = Media::query();

        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['type'])) {
            $query->where('media_type', $filters['type']);
        }

        if (isset($filters['album'])) {
            $query->where('album_id', $filters['album']);
        }

        return $query->inGalleryOrder()->get();
    }

    /**
     * Stores an uploaded photograph.
     *
     * The file is validated and stripped before a row exists, so a refused
     * upload leaves nothing behind at all.
     *
     * @param  array<string, mixed>  $attributes
     */
    public function createPhoto(array $attributes, User $actor): Media
    {
        $file = $attributes['file'];
        $processed = $this->images->process($file, $this->images->directoryForNow());

        try {
            return DB::transaction(function () use ($attributes, $processed, $file, $actor) {
                $media = new Media;
                $this->applyShared($media, $attributes);

                $media->media_type = MediaType::PHOTO;
                $media->file_path = $processed->largePath;
                $media->large_path = $processed->largePath;
                $media->medium_path = $processed->mediumPath;
                $media->thumb_path = $processed->thumbPath;
                $media->mime_type = $processed->mimeType;
                $media->byte_size = $processed->byteSize;
                $media->width = $processed->width;
                $media->height = $processed->height;
                $media->checksum = $processed->checksum;
                // Kept as a label only. It is escaped on output and never
                // reaches a filesystem path (assumption M2).
                $media->original_name = mb_substr(
                    $file->getClientOriginalName(), 0, 255,
                );

                $media->uploaded_by = $actor->id;
                $media->updated_by = $actor->id;
                $media->save();

                return $media->fresh() ?? $media;
            });
        } catch (\Throwable $e) {
            // The bytes are on disk but no row will point at them. Remove them
            // rather than leave orphans nothing will ever clean up.
            $this->images->forget($processed->paths);

            throw $e;
        }
    }

    /**
     * Stores a linked video. Nothing is uploaded (assumption M1).
     *
     * @param  array<string, mixed>  $attributes
     */
    public function createVideo(array $attributes, User $actor): Media
    {
        $link = VideoLink::parse((string) $attributes['external_url']);

        return DB::transaction(function () use ($attributes, $link, $actor) {
            $media = new Media;
            $this->applyShared($media, $attributes);

            $media->media_type = MediaType::VIDEO;
            $media->external_url = $link->url;
            $media->provider = $link->provider;
            $media->provider_ref = $link->reference;
            // An admin-supplied poster wins; otherwise the provider's own.
            $media->thumbnail_url = $this->text($attributes, 'thumbnail_url') ?? $link->thumbnailUrl;

            $media->uploaded_by = $actor->id;
            $media->updated_by = $actor->id;
            $media->save();

            return $media->fresh() ?? $media;
        });
    }

    /**
     * Edits titles, captions, album, order and status.
     *
     * Replacing the *file* is deliberately not possible: every reference to a
     * photograph on this site is by URL, so swapping the bytes under a URL
     * would silently change a page, an event poster and a committee portrait at
     * once. Uploading a new item and repointing the reference is visible.
     *
     * @param  array<string, mixed>  $attributes
     */
    public function update(Media $media, array $attributes, User $actor): Media
    {
        return DB::transaction(function () use ($media, $attributes, $actor) {
            $this->applyShared($media, $attributes);

            if ($media->isVideo() && isset($attributes['external_url'])) {
                $link = VideoLink::parse((string) $attributes['external_url']);
                $media->external_url = $link->url;
                $media->provider = $link->provider;
                $media->provider_ref = $link->reference;
                $media->thumbnail_url = $this->text($attributes, 'thumbnail_url') ?? $link->thumbnailUrl;
            }

            $media->updated_by = $actor->id;
            $media->save();

            return $media->fresh() ?? $media;
        });
    }

    /**
     * Deletes an item, unless something on the site still points at it.
     *
     * @throws MediaGuardException 409 when in use
     */
    public function delete(Media $media): void
    {
        $references = $this->referencesTo($media);

        if ($references !== []) {
            throw MediaGuardException::inUse($references);
        }

        $paths = $media->storedPaths();

        DB::transaction(function () use ($media) {
            $media->delete();
        });

        // Only once the row is certainly gone: an orphan file is recoverable,
        // a row pointing at a deleted file is a broken page.
        $this->images->forget($paths);
    }

    /**
     * Everything on the site that points at this item.
     *
     * The list is returned rather than a bare boolean because "cannot delete"
     * without saying why is a dead end for a committee member who cannot read
     * the database (assumption M7).
     *
     * @return list<array{type: string, label: string, id: int|null}>
     */
    public function referencesTo(Media $media): array
    {
        $urls = $media->urls();
        if ($urls === []) {
            return [];
        }

        $references = [];

        $profile = TempleProfile::query()->whereIn('logo_url', $urls)->first();
        if ($profile !== null) {
            $references[] = [
                'type' => 'temple_logo',
                'label' => $profile->name_hi ?? 'Temple profile',
                'id' => $profile->id,
            ];
        }

        foreach (CommitteeMember::query()->whereIn('photo_url', $urls)->get() as $member) {
            $references[] = [
                'type' => 'committee_member',
                'label' => $member->name_hi,
                'id' => $member->id,
            ];
        }

        foreach (Event::query()->whereIn('poster_url', $urls)->get() as $event) {
            $references[] = [
                'type' => 'event_poster',
                'label' => $event->title_hi,
                'id' => $event->id,
            ];
        }

        foreach (Album::query()->where('cover_media_id', $media->id)->get() as $album) {
            $references[] = [
                'type' => 'album_cover',
                'label' => $album->title_hi,
                'id' => $album->id,
            ];
        }

        // A page body is free text with URLs embedded in it, so there is no
        // join to be had. At village scale the pages table has single-digit
        // rows, and a LIKE across them is cheaper than the schema it would take
        // to avoid one.
        foreach ($this->pagesReferencing($urls) as $page) {
            $references[] = [
                'type' => 'page',
                'label' => $page->title_hi,
                'id' => $page->id,
            ];
        }

        return $references;
    }

    /**
     * Moves items into a new order.
     *
     * The whole ordering is sent and applied in one transaction, so a dropped
     * request leaves the previous arrangement intact rather than half of a new
     * one.
     *
     * @param  list<int>  $orderedIds
     */
    public function reorder(array $orderedIds, User $actor): void
    {
        DB::transaction(function () use ($orderedIds, $actor) {
            foreach (array_values($orderedIds) as $position => $id) {
                Media::query()->whereKey($id)->update([
                    'sort_order' => $position,
                    'updated_by' => $actor->id,
                    'updated_at' => now(),
                ]);
            }
        });
    }

    // --- albums -------------------------------------------------------------

    /** @return Collection<int, Album> */
    public function adminAlbums(): Collection
    {
        return Album::query()
            ->with('cover')
            ->withCount('media')
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->get();
    }

    /** @param array<string, mixed> $attributes */
    public function createAlbum(array $attributes, User $actor): Album
    {
        return DB::transaction(function () use ($attributes, $actor) {
            $album = new Album;
            $this->applyAlbum($album, $attributes);
            $album->created_by = $actor->id;
            $album->updated_by = $actor->id;
            $album->save();

            return $album->fresh() ?? $album;
        });
    }

    /** @param array<string, mixed> $attributes */
    public function updateAlbum(Album $album, array $attributes, User $actor): Album
    {
        return DB::transaction(function () use ($album, $attributes, $actor) {
            $this->applyAlbum($album, $attributes);
            $album->updated_by = $actor->id;
            $album->save();

            return $album->fresh() ?? $album;
        });
    }

    /**
     * Deletes an album. Its photographs survive, unfiled.
     *
     * Deliberately not a cascade: an album is an arrangement, and losing an
     * arrangement must never lose the content (assumption M6).
     */
    public function deleteAlbum(Album $album): void
    {
        DB::transaction(function () use ($album) {
            Media::query()->where('album_id', $album->id)->update(['album_id' => null]);
            $album->delete();
        });
    }

    // --- internals ----------------------------------------------------------

    /** @param array<string, mixed> $attributes */
    private function applyShared(Media $media, array $attributes): void
    {
        foreach (['title_hi', 'title_en', 'caption_hi', 'caption_en'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $media->{$field} = $this->text($attributes, $field);
            }
        }

        if (array_key_exists('album_id', $attributes)) {
            $media->album_id = $attributes['album_id'] === null
                ? null
                : (int) $attributes['album_id'];
        }

        if (array_key_exists('sort_order', $attributes)) {
            $media->sort_order = (int) $attributes['sort_order'];
        }

        if (array_key_exists('status', $attributes)) {
            $media->status = (string) $attributes['status'];
        }

        $media->status ??= Media::STATUS_DRAFT;
    }

    /** @param array<string, mixed> $attributes */
    private function applyAlbum(Album $album, array $attributes): void
    {
        foreach (['title_hi', 'title_en', 'description_hi', 'description_en'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $album->{$field} = $this->text($attributes, $field);
            }
        }

        if (array_key_exists('cover_media_id', $attributes)) {
            $album->cover_media_id = $attributes['cover_media_id'] === null
                ? null
                : (int) $attributes['cover_media_id'];
        }

        if (array_key_exists('sort_order', $attributes)) {
            $album->sort_order = (int) $attributes['sort_order'];
        }

        if (array_key_exists('status', $attributes)) {
            $album->status = (string) $attributes['status'];
        }

        $album->slug = $this->uniqueSlug($album, $attributes);
        $album->status ??= Album::STATUS_DRAFT;
    }

    /** @param array<string, mixed> $attributes */
    private function uniqueSlug(Album $album, array $attributes): string
    {
        $requested = $this->text($attributes, 'slug');

        if ($requested === null && $album->slug !== null && $album->slug !== '') {
            return $album->slug;
        }

        // A Hindi title transliterates to nothing usable, so an album with no
        // explicit slug gets a stable generated one rather than an empty
        // string that would collide with the next album's.
        $base = $requested ?? Str::slug((string) ($attributes['title_en'] ?? ''));
        if ($base === '') {
            $base = 'album';
        }

        $slug = $base;
        $suffix = 2;
        while (
            Album::query()->where('slug', $slug)
                ->when($album->exists, fn (Builder $q) => $q->whereKeyNot($album->id))
                ->exists()
        ) {
            $slug = $base.'-'.$suffix;
            $suffix++;
        }

        return $slug;
    }

    /**
     * Pages whose body embeds one of these URLs.
     *
     * @param  list<string>  $urls
     * @return Collection<int, Page>
     */
    private function pagesReferencing(array $urls): Collection
    {
        return Page::query()->where(function (Builder $query) use ($urls) {
            foreach ($urls as $url) {
                $escaped = addcslashes($url, '%_\\');
                $query->orWhere('content_hi', 'like', '%'.$escaped.'%')
                    ->orWhere('content_en', 'like', '%'.$escaped.'%');
            }
        })->get();
    }

    /** @param array<string, mixed> $attributes */
    private function text(array $attributes, string $key): ?string
    {
        $value = $attributes[$key] ?? null;
        if (! is_string($value)) {
            return null;
        }

        $trimmed = trim($value);

        // Blank is stored as null, not '': the bilingual fallback keys on
        // absence, and an empty string is not absence.
        return $trimmed === '' ? null : $trimmed;
    }
}

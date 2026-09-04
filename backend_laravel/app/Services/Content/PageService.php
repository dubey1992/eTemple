<?php

declare(strict_types=1);

namespace App\Services\Content;

use App\Models\Page;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;

/**
 * Business rules for CMS pages. Controllers stay thin.
 */
class PageService
{
    /**
     * Fetch a published page by slug.
     *
     * The published filter is part of the query, so a draft can never be
     * returned by the public API even if a later change forgets to check.
     *
     * @throws ModelNotFoundException when the slug is unknown or still a draft
     */
    public function publishedBySlug(string $slug): Page
    {
        return Page::query()
            ->published()
            ->where('slug', $slug)
            ->firstOrFail();
    }

    /** @return LengthAwarePaginator<int, Page> */
    public function paginateForAdmin(int $perPage = 25): LengthAwarePaginator
    {
        return Page::query()
            ->orderBy('slug')
            ->paginate(min(max($perPage, 1), 100));
    }

    /**
     * Apply an admin edit.
     *
     * `slug` is deliberately not updatable: it is the page's public URL and the
     * key the application and any external link rely on.
     *
     * @param  array<string, mixed>  $attributes
     */
    public function update(Page $page, array $attributes, User $editor): Page
    {
        unset($attributes['slug']);

        $wasPublished = $page->isPublished();
        $page->fill($attributes);

        // published_at marks the first time the page went public and is never
        // moved or cleared afterwards, so it stays a truthful record.
        if (! $wasPublished && $page->status === Page::STATUS_PUBLISHED && $page->published_at === null) {
            $page->published_at = now();
        }

        $page->updated_by = $editor->id;
        $page->save();

        return $page->refresh();
    }
}

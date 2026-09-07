<?php

declare(strict_types=1);

namespace App\Services\Content;

use App\Models\Page;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
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

    /**
     * Every published page, for the public index.
     *
     * The home page asks for the `about` page on every visit. On a site where
     * nobody has written one yet that is a 404 per page load — harmless to the
     * visitor, who sees a correct empty state, but a real error in the browser
     * console and a request made on a guess. With this the client can ask what
     * exists before asking for it.
     *
     * Drafts are excluded by the query itself, exactly as in publishedBySlug:
     * an unpublished page must not be discoverable by listing either.
     *
     * @return Collection<int, Page>
     */
    public function publishedIndex(): Collection
    {
        return Page::query()
            ->published()
            ->orderBy('slug')
            ->get(['id', 'slug', 'title_hi', 'title_en', 'published_at', 'updated_at']);
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

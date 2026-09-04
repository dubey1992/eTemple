<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Page;
use Illuminate\Database\Seeder;

/**
 * Production-safe structural scaffolding.
 *
 * Creates the page rows the application routes to, as **drafts with empty
 * content**. This is structure, not content: the specification forbids shipping
 * invented temple text, so the committee publishes each page once they have
 * written it. Idempotent — existing pages are never overwritten.
 */
class PageStructureSeeder extends Seeder
{
    /** @var list<array{slug: string, title_hi: string, title_en: string}> */
    private const PAGES = [
        ['slug' => Page::SLUG_HOME, 'title_hi' => 'मुख पृष्ठ', 'title_en' => 'Home'],
        ['slug' => Page::SLUG_ABOUT, 'title_hi' => 'हमारे बारे में', 'title_en' => 'About us'],
    ];

    public function run(): void
    {
        foreach (self::PAGES as $page) {
            Page::query()->firstOrCreate(
                ['slug' => $page['slug']],
                [
                    'title_hi' => $page['title_hi'],
                    'title_en' => $page['title_en'],
                    // Empty on purpose: real content is entered by the committee.
                    'content_hi' => '',
                    'content_en' => null,
                    'status' => Page::STATUS_DRAFT,
                ],
            );
        }
    }
}

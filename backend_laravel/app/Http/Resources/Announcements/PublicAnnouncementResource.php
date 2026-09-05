<?php

declare(strict_types=1);

namespace App\Http\Resources\Announcements;

use App\Models\Announcement;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * An announcement as a visitor sees it.
 *
 * Carries the notice and nothing about how it came to be there: no author, no
 * status, no schedule, no record of what was sent to whom. The website's job is
 * to show the temple's current word; who wrote it and when they pressed send is
 * the committee's business.
 *
 * `end_at` travels because a client may reasonably stop showing a banner the
 * moment it expires without re-fetching. `start_at` does not: every row that
 * reaches this resource has already started, so it would say nothing.
 *
 * @mixin Announcement
 */
class PublicAnnouncementResource extends JsonResource
{
    public function __construct(Announcement $announcement, private readonly Language $language)
    {
        parent::__construct($announcement);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Announcement $announcement */
        $announcement = $this->resource;

        return [
            'id' => $this->id,
            'requested_language' => $this->language->value,
            'title' => LocalizedText::resolve(
                $announcement->title_hi, $announcement->title_en, $this->language
            )->toArray(),
            'message' => LocalizedText::resolve(
                $announcement->message_hi, $announcement->message_en, $this->language
            )->toArray(),
            'priority' => $this->priority,
            'link_url' => $this->link_url,
            'ends_at' => $announcement->end_at?->toIso8601String(),
        ];
    }
}

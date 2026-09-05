<?php

declare(strict_types=1);

namespace App\Http\Resources\Announcements;

use App\Models\Announcement;
use App\Support\AnnouncementChannel;
use App\Support\AnnouncementPriority;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * An announcement as the committee sees it.
 *
 * Both languages travel raw, because this is the editor and an editor must show
 * what is actually stored — a resolved value with the Hindi fallback applied
 * would make an empty English field look filled in, and the next save would
 * write the Hindi into it.
 *
 * `is_showing`, `is_scheduled` and `has_expired` are computed here rather than
 * stored, and they are what the list uses to say "on the website now" or
 * "starts Tuesday". Nothing writes them; a status changed by a scheduler goes
 * live only when the scheduler runs (PHASE_8_PLAN assumption N3).
 *
 * @mixin Announcement
 */
class AdminAnnouncementResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Announcement $announcement */
        $announcement = $this->resource;

        return [
            'id' => $this->id,

            'title_hi' => $this->title_hi,
            'title_en' => $this->title_en,
            'message_hi' => $this->message_hi,
            'message_en' => $this->message_en,

            'priority' => $this->priority,
            'priority_label' => AnnouncementPriority::label($announcement->priority),

            'start_at' => $announcement->start_at->toIso8601String(),
            'end_at' => $announcement->end_at?->toIso8601String(),
            'link_url' => $this->link_url,

            'status' => $this->status,
            'is_showing' => $announcement->isShowing(),
            'is_scheduled' => $announcement->isScheduled(),
            'has_expired' => $announcement->hasExpired(),

            // The send, and the fact that it can only happen once.
            'was_sent' => $announcement->wasSent(),
            'sent_at' => $announcement->sent_at?->toIso8601String(),
            'sent_by_name' => $this->whenLoaded('sender', fn () => $announcement->sender?->fullName()),
            'recipient_count' => $announcement->recipient_count,
            'channels' => $announcement->channels ?? [],
            'channel_labels' => array_map(
                AnnouncementChannel::label(...),
                $announcement->channels ?? [],
            ),

            'created_by_name' => $this->whenLoaded('author', fn () => $announcement->author?->fullName()),
            'created_at' => $announcement->created_at?->toIso8601String(),
            'updated_at' => $announcement->updated_at?->toIso8601String(),
        ];
    }
}

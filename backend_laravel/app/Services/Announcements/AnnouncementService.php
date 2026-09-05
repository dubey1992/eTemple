<?php

declare(strict_types=1);

namespace App\Services\Announcements;

use App\Exceptions\AnnouncementGuardException;
use App\Mail\AnnouncementNotification;
use App\Models\Announcement;
use App\Models\User;
use App\Support\AnnouncementChannel;
use App\Support\Permission;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;

/**
 * Everything announcements do.
 *
 * The three verbs are deliberately not one verb: **save**, **publish** and
 * **send** have different consequences and different undo. A save can be
 * corrected, a publish can be archived, and a send cannot be taken back — which
 * is why it is the only one with a 409 waiting for a second attempt.
 */
class AnnouncementService
{
    /**
     * What the public may see: published, inside its window, loudest first.
     *
     * @return Collection<int, Announcement>
     */
    public function currentlyShowing(int $limit = 5): Collection
    {
        return Announcement::query()
            ->currentlyShowing()
            ->inNoticeOrder()
            ->limit(max(1, $limit))
            ->get();
    }

    /**
     * The admin list.
     *
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, Announcement>
     */
    public function list(array $filters = []): LengthAwarePaginator
    {
        $perPage = max(1, min(
            (int) ($filters['per_page'] ?? config('announcements.default_per_page', 25)),
            (int) config('announcements.max_per_page', 100),
        ));

        $query = Announcement::query()->with([
            'author:id,first_name,last_name',
            'sender:id,first_name,last_name',
        ]);

        $status = $filters['status'] ?? null;
        if (is_string($status) && in_array($status, Announcement::statuses(), true)) {
            $query->where('status', $status);
        } elseif (($filters['include_archived'] ?? false) !== true) {
            // Archived notices are kept, not shown by default — the same
            // treatment spam gets in the enquiry inbox.
            $query->where('status', '!=', Announcement::STATUS_ARCHIVED);
        }

        if (isset($filters['priority']) && is_string($filters['priority'])) {
            $query->where('priority', $filters['priority']);
        }

        if (isset($filters['search']) && is_string($filters['search']) && trim($filters['search']) !== '') {
            $term = '%'.addcslashes(trim($filters['search']), '%_\\').'%';
            $query->where(function (Builder $inner) use ($term) {
                $inner->where('title_hi', 'like', $term)
                    ->orWhere('title_en', 'like', $term)
                    ->orWhere('message_hi', 'like', $term)
                    ->orWhere('message_en', 'like', $term);
            });
        }

        return $query->orderByDesc('start_at')->orderByDesc('id')->paginate($perPage);
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes, User $actor): Announcement
    {
        $announcement = new Announcement;
        $this->apply($announcement, $attributes);

        // New announcements are drafts. Nothing reaches the website, and
        // certainly nothing reaches an inbox, until somebody says so.
        $announcement->status = Announcement::STATUS_DRAFT;
        $announcement->created_by = $actor->id;
        $announcement->updated_by = $actor->id;
        $announcement->save();

        return $announcement->fresh(['author']) ?? $announcement;
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Announcement $announcement, array $attributes, User $actor): Announcement
    {
        $this->apply($announcement, $attributes);
        $announcement->updated_by = $actor->id;
        $announcement->save();

        return $announcement->fresh(['author', 'sender']) ?? $announcement;
    }

    public function publish(Announcement $announcement, User $actor): Announcement
    {
        $announcement->status = Announcement::STATUS_PUBLISHED;
        $announcement->updated_by = $actor->id;
        $announcement->save();

        return $announcement->fresh(['author', 'sender']) ?? $announcement;
    }

    /**
     * Takes it off the website. Keeps the row, and whatever record of sending
     * it carries — an archived announcement that was sent still says so.
     */
    public function archive(Announcement $announcement, User $actor): Announcement
    {
        $announcement->status = Announcement::STATUS_ARCHIVED;
        $announcement->updated_by = $actor->id;
        $announcement->save();

        return $announcement->fresh(['author', 'sender']) ?? $announcement;
    }

    /**
     * Sends the announcement. Once.
     *
     * Every refusal here is about something that cannot be undone:
     *
     *  * a draft or an archived notice is not the temple's current word, so it
     *    is not what should land in an inbox;
     *  * a channel with no provider behind it would silently send nothing;
     *  * and an announcement already sent stays sent — a message cannot be
     *    unsent, so the second press is refused rather than obeyed
     *    (PHASE_8_PLAN assumptions N1, N5, N6).
     *
     * @param  list<string>  $channels
     *
     * @throws AnnouncementGuardException
     */
    public function send(Announcement $announcement, array $channels, User $actor): Announcement
    {
        if ($announcement->wasSent()) {
            throw AnnouncementGuardException::alreadySent();
        }

        if ($announcement->isArchived()) {
            throw AnnouncementGuardException::cannotSendArchived();
        }

        if (! $announcement->isPublished()) {
            throw AnnouncementGuardException::cannotSendDraft();
        }

        $channels = array_values(array_unique(array_filter($channels)));

        if ($channels === []) {
            throw AnnouncementGuardException::noChannelChosen();
        }

        foreach ($channels as $channel) {
            if (! AnnouncementChannel::isEnabled($channel)) {
                throw AnnouncementGuardException::channelNotAvailable($channel);
            }
        }

        $recipients = in_array(AnnouncementChannel::EMAIL, $channels, true)
            ? $this->committeeRecipients()
            : [];

        // The row is written first and inside a transaction, so a mail server
        // that hangs cannot leave the temple unsure whether it sent. The count
        // is what the queue was handed — not a delivery guarantee, which no
        // mail system can offer (assumption N7).
        DB::transaction(function () use ($announcement, $channels, $actor, $recipients) {
            $announcement->channels = $channels;
            $announcement->sent_at = Carbon::now();
            $announcement->sent_by = $actor->id;
            $announcement->recipient_count = count($recipients);
            $announcement->save();
        });

        foreach ($recipients as $address) {
            Mail::to($address)->queue(new AnnouncementNotification($announcement));
        }

        return $announcement->fresh(['author', 'sender']) ?? $announcement;
    }

    /**
     * Who an announcement e-mail goes to.
     *
     * **Committee accounts, and nobody else.** There is no subscriber list in
     * this project, and the addresses that do exist must not become one: a
     * villager who left an e-mail on an enquiry gave it to get an answer to
     * their question, not to join a mailing list. Using it here would be
     * consent laundering (PHASE_8_PLAN assumption N4).
     *
     * Blocked and inactive accounts are excluded — an account that cannot sign
     * in is not one the temple should be writing to.
     *
     * @return list<string>
     */
    public function committeeRecipients(): array
    {
        return User::query()
            ->where('status', User::STATUS_ACTIVE)
            ->whereNotNull('email')
            ->orderBy('id')
            ->pluck('email')
            ->all();
    }

    /**
     * @param  array<string, mixed>  $attributes
     *
     * @throws AnnouncementGuardException
     */
    private function apply(Announcement $announcement, array $attributes): void
    {
        $announcement->fill($attributes);

        $start = $announcement->start_at ?? Carbon::now();
        $announcement->start_at = $start;

        if ($announcement->end_at !== null
            && $announcement->end_at->lessThanOrEqualTo($start)) {
            throw AnnouncementGuardException::endsBeforeItStarts();
        }

        $limit = max(1, (int) config('announcements.max_schedule_days', 730));
        if ($start->greaterThan(Carbon::now()->addDays($limit))) {
            throw AnnouncementGuardException::scheduledTooFarAhead($limit);
        }
    }

    /**
     * Whether an account may be told about announcements at all.
     *
     * Kept beside the recipient list so the two cannot drift: the permission
     * that decides who can *write* one is not the permission that decides who
     * hears about it.
     */
    public function canManage(User $user): bool
    {
        return $user->isSuperAdmin() || $user->hasPermission(Permission::ANNOUNCEMENTS_MANAGE);
    }
}

<?php

declare(strict_types=1);

namespace App\Mail;

use App\Models\Announcement;
use App\Services\Temple\TempleProfileService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * An announcement, in a committee member's inbox.
 *
 * Unlike Phase 7's acknowledgement, this one **does** carry the temple's own
 * words — that is the entire point of it. The difference is who wrote them: an
 * announcement is written by a committee member with `announcements.manage`,
 * not typed by an anonymous stranger.
 *
 * It is still escaped on the way in. The author is trusted to write the notice;
 * they are not trusted to have avoided a `<` by accident, and a mail client is
 * as willing to interpret markup as a browser.
 *
 * Both languages are sent in one message. The recipients are the temple's own
 * committee, who between them read both, and a per-recipient language
 * preference is a column no account has.
 */
class AnnouncementNotification extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(private readonly Announcement $announcement) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: $this->announcement->title_hi);
    }

    public function content(): Content
    {
        $profile = app(TempleProfileService::class)->current();
        $templeName = trim((string) ($profile->name_hi ?: $profile->name_en)) ?: 'मंदिर';

        $blocks = [
            $this->announcement->title_hi,
            '',
            $this->announcement->message_hi,
        ];

        // English only when it was actually written. Repeating the Hindi under
        // an "English" heading would be worse than leaving it out.
        if (($this->announcement->title_en ?? '') !== ''
            || ($this->announcement->message_en ?? '') !== '') {
            $blocks[] = '';
            $blocks[] = '---';
            $blocks[] = '';
            $blocks[] = $this->announcement->title_en ?? $this->announcement->title_hi;
            $blocks[] = '';
            $blocks[] = $this->announcement->message_en ?? '';
        }

        if (($this->announcement->link_url ?? '') !== '') {
            $blocks[] = '';
            $blocks[] = $this->announcement->link_url;
        }

        $blocks[] = '';
        $blocks[] = '— '.$templeName;

        return new Content(
            htmlString: '<div style="font-family: sans-serif; white-space: pre-wrap; line-height: 1.6;">'
                .e(implode("\n", $blocks))
                .'</div>',
        );
    }
}

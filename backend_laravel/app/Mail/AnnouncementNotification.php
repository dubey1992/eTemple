<?php

declare(strict_types=1);

namespace App\Mail;

use App\Models\Announcement;
use App\Support\MailBranding;
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
 * as willing to interpret markup as a browser. The template's `{{ }}` does it.
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
        return new Content(
            view: 'mail.announcement',
            text: 'mail.text.announcement',
            with: [
                'branding' => MailBranding::current(),
                'subject' => $this->announcement->title_hi,
                'announcement' => $this->announcement,
            ],
        );
    }
}

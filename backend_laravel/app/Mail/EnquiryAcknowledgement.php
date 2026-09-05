<?php

declare(strict_types=1);

namespace App\Mail;

use App\Models\Enquiry;
use App\Support\EnquiryCategory;
use App\Support\MailBranding;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * "We have your message" — the optional acknowledgement (spec Phase 7).
 *
 * ## What is deliberately not in it
 *
 * Not one word the visitor typed. Not their name, not their message, not their
 * subject line. The reason is that the address this is sent to is supplied by
 * whoever filled the form, and they need not be its owner: an attacker types a
 * victim's address and our server delivers whatever text the attacker chose,
 * from the temple's own domain, with the temple's reputation behind it.
 *
 * So the mail is a fixed bilingual body plus a reference number, a category
 * label from a fixed catalogue, and the temple's own published details — every
 * part of it under the committee's control (PHASE_7_PLAN N3).
 *
 * It is queued, so a slow SMTP server cannot hold a public request open.
 */
class EnquiryAcknowledgement extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(private readonly Enquiry $enquiry) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'आपका संदेश प्राप्त हुआ / We have received your message — '.$this->enquiry->reference,
        );
    }

    public function content(): Content
    {
        $data = [
            'branding' => MailBranding::current(),
            'subject' => $this->envelope()->subject,
            'reference' => $this->enquiry->reference,
            'category' => EnquiryCategory::label($this->enquiry->category),
        ];

        return new Content(
            view: 'mail.enquiry-acknowledgement',
            text: 'mail.text.enquiry-acknowledgement',
            with: $data,
        );
    }
}

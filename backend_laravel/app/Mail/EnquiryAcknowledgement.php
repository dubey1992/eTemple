<?php

declare(strict_types=1);

namespace App\Mail;

use App\Models\Enquiry;
use App\Services\Temple\TempleProfileService;
use App\Support\EnquiryCategory;
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
 * label from a fixed catalogue, and the temple's own published contact details
 * — every part of it under the committee's control (PHASE_7_PLAN N3).
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
        $profile = app(TempleProfileService::class)->current();

        $templeName = trim((string) ($profile->name_hi ?: $profile->name_en)) ?: 'मंदिर';
        $category = EnquiryCategory::label($this->enquiry->category);

        $lines = [
            'नमस्ते,',
            '',
            $templeName.' को भेजा गया आपका संदेश हमें प्राप्त हो गया है। समिति के सदस्य शीघ्र ही आपसे संपर्क करेंगे।',
            '',
            'संदर्भ संख्या / Reference: '.$this->enquiry->reference,
            'विषय / Subject: '.$category,
            '',
            '---',
            '',
            'Namaste,',
            '',
            'Your message to '.$templeName.' has reached us. A member of the committee will be in touch shortly.',
            '',
            'Please quote the reference above if you telephone the temple.',
            '',
            'This is an automated acknowledgement; replies to this address are not read.',
        ];

        return new Content(
            htmlString: '<pre style="font-family: sans-serif; white-space: pre-wrap;">'
                .e(implode("\n", $lines))
                .'</pre>',
        );
    }
}

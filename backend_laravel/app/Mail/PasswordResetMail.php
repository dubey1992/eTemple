<?php

declare(strict_types=1);

namespace App\Mail;

use App\Models\User;
use App\Support\MailBranding;
use App\Support\PasswordResetLink;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * The password reset link, in the temple's own words.
 *
 * Replaces Laravel's built-in notification, which is in English, carries the
 * framework's wording and signs itself with `APP_NAME`. A committee member in
 * Amarpur Pankhoriya should not have to read "Regards, Laravel" to get back
 * into the donation register.
 *
 * **Not queued, on purpose.** Every other mail here is; this one is not,
 * because a reset that sits in a queue nobody is running is indistinguishable
 * from a reset that failed, and the person waiting for it is locked out. The
 * endpoint that sends it is rate-limited, so blocking on SMTP is bounded.
 */
class PasswordResetMail extends Mailable
{
    use SerializesModels;

    public function __construct(
        private readonly User $user,
        private readonly string $token,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'पासवर्ड बदलने का अनुरोध / Password reset request',
        );
    }

    public function content(): Content
    {
        $data = [
            'branding' => MailBranding::current(),
            'subject' => $this->envelope()->subject,
            'name' => trim((string) $this->user->first_name) ?: (string) $this->user->email,
            'url' => PasswordResetLink::forUser($this->user, $this->token),
            'expiresInMinutes' => PasswordResetLink::expiresInMinutes(),
        ];

        return new Content(
            view: 'mail.password-reset',
            text: 'mail.text.password-reset',
            with: $data,
        );
    }
}

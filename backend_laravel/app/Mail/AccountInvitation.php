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
 * "An account has been made for you."
 *
 * A separate message from {@see PasswordResetMail}, because it is a separate
 * event. A new committee member who has never had a password used to receive a
 * mail telling them somebody had requested a *reset* of it — confusing at best,
 * and at worst indistinguishable from the phishing it resembles.
 *
 * It names the account and the role, so the reader can tell a real invitation
 * from a forged one: a stranger does not know that the secretary added them as
 * Treasurer this morning.
 *
 * No password is ever sent, here or anywhere. The account is created with an
 * unusable random hash and the member sets their own (PHASE_2_PLAN C5).
 *
 * Not queued, for the same reason as the reset: somebody is waiting for it.
 */
class AccountInvitation extends Mailable
{
    use SerializesModels;

    public function __construct(
        private readonly User $user,
        private readonly string $token,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'आपका खाता बनाया गया है / Your account has been created',
        );
    }

    public function content(): Content
    {
        $role = $this->user->role;

        $data = [
            'branding' => MailBranding::current(),
            'subject' => $this->envelope()->subject,
            'name' => trim((string) $this->user->first_name) ?: (string) $this->user->email,
            'email' => (string) $this->user->email,
            // The role's own name, so an invitation says what the account may
            // do rather than leaving the reader to guess.
            'role' => trim((string) ($role?->name ?? '')) ?: '—',
            'url' => PasswordResetLink::forUser($this->user, $this->token),
            'expiresInMinutes' => PasswordResetLink::expiresInMinutes(),
        ];

        return new Content(
            view: 'mail.account-created',
            text: 'mail.text.account-created',
            with: $data,
        );
    }
}

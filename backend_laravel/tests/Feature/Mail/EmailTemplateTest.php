<?php

declare(strict_types=1);

namespace Tests\Feature\Mail;

use App\Mail\AccountInvitation;
use App\Mail\AnnouncementNotification;
use App\Mail\EnquiryAcknowledgement;
use App\Mail\PasswordResetMail;
use App\Models\Announcement;
use App\Models\Enquiry;
use App\Models\Role;
use App\Models\TempleProfile;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * What actually goes out under the temple's name.
 *
 * These render the real templates rather than mocking them, because every
 * defect this file guards against is invisible until somebody opens their
 * inbox: a mail with no plain-text part, a temple name compiled into the
 * application, an acknowledgement quoting words a stranger typed, or an
 * invitation telling a brand-new member that somebody reset their password.
 */
class EmailTemplateTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);

        TempleProfile::factory()->create([
            'name_hi' => 'राधा कृष्ण ठाकुरबाड़ी',
            'village_hi' => 'अमरपुर पंखोरिया',
            'district_hi' => 'भागलपुर',
            'state_hi' => 'बिहार',
            'postal_code' => '813204',
        ]);
    }

    private function user(): User
    {
        return User::factory()->withRole(Role::TREASURER)->create([
            'first_name' => 'त्रिभुवन',
            'email' => 'treasurer@thakurbari.test',
        ]);
    }

    /** @return array<string, array{string}> */
    public static function everyMail(): array
    {
        return [
            'enquiry acknowledgement' => ['acknowledgement'],
            'announcement' => ['announcement'],
            'password reset' => ['reset'],
            'account invitation' => ['invitation'],
        ];
    }

    private function make(string $kind): object
    {
        return match ($kind) {
            'acknowledgement' => new EnquiryAcknowledgement(
                Enquiry::factory()->create(['reference' => 'RKT/E/2026/0001']),
            ),
            'announcement' => new AnnouncementNotification(
                Announcement::factory()->create([
                    'title_hi' => 'जन्माष्टमी महोत्सव',
                    'message_hi' => 'सभी ग्रामवासियों से सहयोग का अनुरोध है।',
                ]),
            ),
            'reset' => new PasswordResetMail($this->user(), 'test-token'),
            default => new AccountInvitation($this->user(), 'test-token'),
        };
    }

    /**
     * Every message has a plain-text alternative.
     *
     * Some clients show it, some readers prefer it, and a mail with no text
     * part scores worse with spam filters — which for the only automated mail a
     * temple sends is the difference between arriving and not.
     */
    #[DataProvider('everyMail')]
    public function test_every_mail_has_both_an_html_and_a_text_part(string $kind): void
    {
        $mail = $this->make($kind);

        $mail->assertSeeInHtml('राधा कृष्ण ठाकुरबाड़ी', false);
        $mail->assertSeeInText('राधा कृष्ण ठाकुरबाड़ी', false);
    }

    /**
     * The temple signs its own mail.
     *
     * The name comes from the CMS profile, never from `APP_NAME` or a compiled
     * string — the specification forbids hardcoded temple content, and an
     * e-mail is where a wrong name is hardest to notice.
     */
    #[DataProvider('everyMail')]
    public function test_no_mail_signs_itself_with_the_framework(string $kind): void
    {
        $mail = $this->make($kind);

        $mail->assertDontSeeInHtml('Laravel');
        $mail->assertDontSeeInText('Laravel');
    }

    /** The address block is the temple's own, resolved from the profile. */
    public function test_the_address_in_the_footer_comes_from_the_profile(): void
    {
        $this->make('announcement')->assertSeeInHtml('अमरपुर पंखोरिया, भागलपुर, बिहार, 813204', false);
    }

    /**
     * Not one word the sender typed reaches the acknowledgement.
     *
     * The address it goes to was supplied by whoever filled the form and need
     * not be theirs. Echoing their words would let a stranger send chosen text
     * from the temple's own domain to somebody else's inbox.
     */
    public function test_the_acknowledgement_quotes_nothing_the_sender_typed(): void
    {
        $enquiry = Enquiry::factory()->create([
            'reference' => 'RKT/E/2026/0007',
            'name' => 'चालाक व्यक्ति',
            'message' => 'CLICK THIS LINK — send money to evil.example immediately.',
        ]);

        $mail = new EnquiryAcknowledgement($enquiry);

        foreach (['चालाक व्यक्ति', 'CLICK THIS LINK', 'evil.example'] as $theirs) {
            $mail->assertDontSeeInHtml($theirs, false);
            $mail->assertDontSeeInText($theirs, false);
        }

        // What it does carry: the reference, so a telephone call can find it.
        $mail->assertSeeInHtml('RKT/E/2026/0007');
        $mail->assertSeeInText('RKT/E/2026/0007');
    }

    /**
     * An announcement carries the committee's words, escaped.
     *
     * The author is trusted to write the notice. They are not trusted to have
     * avoided a `<` by accident, and a mail client interprets markup as
     * readily as a browser.
     */
    public function test_an_announcement_carries_its_words_but_not_its_markup(): void
    {
        $mail = new AnnouncementNotification(Announcement::factory()->create([
            'title_hi' => 'सूचना',
            'message_hi' => 'ध्यान दें <script>alert(1)</script> और सहयोग करें।',
        ]));

        $mail->assertSeeInHtml('और सहयोग करें', false);
        $mail->assertDontSeeInHtml('<script>alert(1)</script>', false);
    }

    /**
     * A new member is invited, not told their password was reset.
     *
     * They have never had one. The old behaviour sent the reset mail, which is
     * confusing at best and reads like phishing at worst.
     */
    public function test_an_invitation_reads_as_an_invitation(): void
    {
        $mail = new AccountInvitation($this->user(), 'test-token');

        $mail->assertSeeInHtml('खाता बना दिया गया है', false);
        $mail->assertSeeInHtml('An account has been created for you', false);
        // It names the account and the role, so a real invitation can be told
        // apart from a forged one.
        $mail->assertSeeInHtml('treasurer@thakurbari.test');
        $mail->assertSeeInHtml('Treasurer');

        // The wording, not the URL: the link it carries is necessarily a
        // /reset-password one, because that is the screen where a password is
        // set. What must not appear is the *reset* message.
        $mail->assertDontSeeInHtml('Password reset request', false);
        $mail->assertDontSeeInHtml('पासवर्ड बदलने का अनुरोध', false);
    }

    /**
     * The reset never claims the reader asked for it.
     *
     * It cannot know, and telling somebody "you requested this" when they did
     * not is how a phishing habit is taught. It says what to do if it was not
     * them instead.
     */
    public function test_the_reset_says_what_to_do_if_it_was_not_you(): void
    {
        $mail = new PasswordResetMail($this->user(), 'test-token');

        $mail->assertSeeInHtml('If you did not', false);
        $mail->assertSeeInHtml('यदि यह अनुरोध आपने नहीं किया है', false);
        $mail->assertDontSeeInHtml('You requested', false);
    }

    /**
     * Both links point at the Flutter client, and carry the token.
     *
     * A link to a Blade route would 404: this API serves no HTML.
     */
    #[DataProvider('linkedMail')]
    public function test_a_password_link_points_at_the_client(string $kind): void
    {
        $mail = $this->make($kind);

        $mail->assertSeeInHtml('/reset-password?token=test-token', false);
        $mail->assertSeeInHtml('email=treasurer%40thakurbari.test', false);
        // The URL is repeated as text: clients strip buttons, and a reader is
        // entitled to see where a link about their password goes.
        $mail->assertSeeInText('/reset-password?token=test-token', false);
    }

    /** @return array<string, array{string}> */
    public static function linkedMail(): array
    {
        return ['password reset' => ['reset'], 'account invitation' => ['invitation']];
    }

    /** An unconfigured temple still gets a legible message. */
    public function test_a_temple_with_no_profile_still_sends_a_readable_mail(): void
    {
        TempleProfile::query()->delete();

        $mail = new PasswordResetMail($this->user(), 'test-token');

        $mail->assertSeeInHtml('मंदिर', false);
        $mail->assertSeeInHtml('/reset-password?token=test-token', false);
    }
}

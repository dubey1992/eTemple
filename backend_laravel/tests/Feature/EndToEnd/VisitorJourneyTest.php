<?php

declare(strict_types=1);

namespace Tests\Feature\EndToEnd;

use App\Models\AuditLog;
use App\Models\Enquiry;
use App\Models\Event;
use App\Models\Media;
use App\Models\Page;
use App\Models\Role;
use App\Models\TempleProfile;
use App\Models\User;
use App\Support\AuditAction;
use App\Support\EnquiryCategory;
use Carbon\CarbonImmutable;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * A villager opens the site on a phone, reads it, and writes to the temple.
 *
 * Everything here is done the way a browser with no login does it, in the order
 * a person does it, because the questions worth asking of the public half are
 * sequential: does the site work at all before anybody has filled it in, does a
 * draft leak while a page is half-written, and does a message sent from the
 * contact form reach the committee without becoming readable by the next
 * visitor.
 */
class VisitorJourneyTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        config(['enquiries.min_fill_seconds' => 4]);
    }

    /**
     * The first visitor, on the day the site goes live and before the committee
     * has written anything.
     *
     * A temple site that 500s on an empty database is a site that cannot be
     * handed over, because the committee's first act is to look at it.
     */
    public function test_the_whole_public_site_answers_on_a_freshly_installed_temple(): void
    {
        foreach ([
            '/api/public/site-settings',
            '/api/public/temple-profile',
            '/api/public/committee',
            '/api/public/events',
            '/api/public/media',
            '/api/public/albums',
            '/api/public/announcements',
            '/api/public/donation-settings',
            '/api/public/transparency',
            '/api/public/enquiry-form',
        ] as $path) {
            $this->getJson($path)->assertOk();
        }
    }

    /**
     * Hindi is the default and English is behind a switch, and a half-translated
     * site still reads as a site rather than as blanks.
     */
    public function test_a_visitor_reads_the_temple_in_either_language_and_never_sees_a_blank(): void
    {
        TempleProfile::query()->create([
            'name_hi' => 'राधा कृष्ण ठाकुरवाड़ी',
            'name_en' => null,                       // deliberately not translated yet
            'village_hi' => 'अमरपुर पंखोरिया',
            'village_en' => 'Amarpur Pankhoriya',
        ]);

        $hindi = $this->getJson('/api/public/temple-profile')->assertOk();
        $hindi->assertJsonPath('data.name.value', 'राधा कृष्ण ठाकुरवाड़ी')
            ->assertJsonPath('data.name.fallback_used', false);

        $english = $this->getJson('/api/public/temple-profile?lang=en')->assertOk();

        // The English reader gets the Hindi name rather than an empty heading,
        // and the response says so, so the client can mark it.
        $english->assertJsonPath('data.name.value', 'राधा कृष्ण ठाकुरवाड़ी')
            ->assertJsonPath('data.name.language', 'hi')
            ->assertJsonPath('data.name.fallback_used', true);

        // The address falls back part by part, so a half-translated one still
        // reads as an address rather than as a row of blanks: the village has
        // an English spelling and is served in English.
        $english->assertJsonPath('data.address.village', 'Amarpur Pankhoriya');
        $this->getJson('/api/public/temple-profile')
            ->assertJsonPath('data.address.village', 'अमरपुर पंखोरिया');
    }

    /**
     * Everything unfinished stays unfinished, across four modules at once.
     *
     * Each of these has its own test. What this adds is that they are all true
     * *simultaneously*, on one site, in one request each — which is the state
     * the committee will actually be in: some things published, most not.
     */
    public function test_nothing_unpublished_reaches_a_visitor_anywhere(): void
    {
        Page::factory()->create(['slug' => 'half-written', 'content_hi' => 'अधूरा मसौदा']);
        Event::factory()->create([
            'title_hi' => 'अघोषित कार्यक्रम',
            'start_at' => CarbonImmutable::parse('2026-12-01 18:00'),
        ]);
        Media::factory()->create(['title_hi' => 'अप्रकाशित चित्र', 'status' => Media::STATUS_DRAFT]);

        $this->getJson('/api/public/pages/half-written')->assertNotFound();

        $events = $this->getJson('/api/public/events')->assertOk();
        $this->assertResponseDoesNotLeak($events, 'अघोषित कार्यक्रम');

        $media = $this->getJson('/api/public/media')->assertOk();
        $this->assertResponseDoesNotLeak($media, 'अप्रकाशित चित्र');
    }

    /**
     * The message a villager sends: written on the public form, answered by the
     * committee, and readable by nobody else at any point in between.
     */
    public function test_a_message_reaches_the_committee_and_no_one_else(): void
    {
        // 1. The visitor's browser fetches the form and waits, as a person does.
        $token = $this->getJson('/api/public/enquiry-form')->assertOk()->json('data.token');
        $this->travel(10)->seconds();

        $sent = $this->postJson('/api/public/enquiries', [
            'name' => 'रामप्रसाद यादव',
            'mobile' => '9876500011',
            'category' => EnquiryCategory::PUJA_BOOKING,
            'message' => 'क्या अगले रविवार को सत्यनारायण पूजा कराई जा सकती है?',
            'preferred_language' => 'hi',
            'form_token' => $token,
        ])->assertCreated();

        $reference = $sent->json('data.reference');
        $this->assertNotEmpty($reference);

        // 2. The acknowledgement carries a reference and nothing else. In
        //    particular it does not echo the sender's own words back — the
        //    address it went to was typed by a stranger.
        $this->assertResponseDoesNotLeak($sent, '9876500011', 'सत्यनारायण');

        // 3. No public path reads it back, at any status.
        $enquiryId = Enquiry::query()->sole()->id;
        foreach ([
            '/api/public/enquiries',
            "/api/public/enquiries/{$enquiryId}",
            "/api/public/enquiries/{$reference}",
        ] as $path) {
            $response = $this->getJson($path);
            $this->assertContains($response->status(), [404, 405]);
            $this->assertResponseDoesNotLeak($response, 'रामप्रसाद', '9876500011');
        }

        // 4. The committee reads it — and reading it is itself recorded,
        //    because what is being read is somebody's telephone number.
        $admin = User::factory()->withRole(Role::ADMIN)->create();
        $this->actingAs($admin, 'web')
            ->getJson("/api/admin/enquiries/{$enquiryId}")
            ->assertOk()
            ->assertJsonPath('data.name', 'रामप्रसाद यादव');

        $viewed = AuditLog::query()->where('action', AuditAction::ENQUIRY_VIEWED)->sole();
        $this->assertSame($admin->fullName(), $viewed->actor_name);

        // 5. And a treasurer, who has no business in the inbox, is refused.
        $this->actingAs(User::factory()->withRole(Role::TREASURER)->create(), 'web')
            ->getJson("/api/admin/enquiries/{$enquiryId}")
            ->assertForbidden();
    }

    /**
     * The form's defences are in the request path, not merely present in the
     * code — asserted by trying to skip them the way a script would.
     */
    public function test_the_contact_form_refuses_a_submission_that_skipped_the_form(): void
    {
        $this->postJson('/api/public/enquiries', [
            'name' => 'bot',
            'mobile' => '9000000000',
            'category' => EnquiryCategory::PUJA_BOOKING,
            'message' => 'buy cheap watches',
        ])->assertStatus(422);

        // An instant submission is not a person, even with a real ticket.
        $token = $this->getJson('/api/public/enquiry-form')->assertOk()->json('data.token');

        $this->postJson('/api/public/enquiries', [
            'name' => 'bot',
            'mobile' => '9000000000',
            'category' => EnquiryCategory::PUJA_BOOKING,
            'message' => 'buy cheap watches',
            'form_token' => $token,
        ])->assertStatus(422);

        $this->assertSame(0, Enquiry::query()->count());
    }
}

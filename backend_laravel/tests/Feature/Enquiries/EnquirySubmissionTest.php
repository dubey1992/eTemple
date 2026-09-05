<?php

declare(strict_types=1);

namespace Tests\Feature\Enquiries;

use App\Models\Enquiry;
use App\Support\EnquiryCategory;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/**
 * The public contact form, from the outside.
 *
 * Everything here goes through the HTTP endpoints exactly as an anonymous
 * visitor's browser would, because that is the only way to know that the
 * anti-spam layers are actually in the path rather than merely present.
 */
class EnquirySubmissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);

        // The time floor is real, and every test here would otherwise have to
        // sleep through it. Travelling past it is the same assertion.
        config(['enquiries.min_fill_seconds' => 4]);
    }

    /** Fetches a form and returns its token, having waited out the time floor. */
    private function token(): string
    {
        $response = $this->getJson('/api/public/enquiry-form')->assertOk();

        $this->travel(10)->seconds();

        return $response->json('data.token');
    }

    /** @return array<string, mixed> */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'रामप्रसाद यादव',
            'mobile' => '9876500011',
            'category' => EnquiryCategory::PUJA_BOOKING,
            'message' => 'क्या अगले रविवार को सत्यनारायण पूजा कराई जा सकती है?',
            'preferred_language' => 'hi',
        ], $overrides);
    }

    public function test_the_form_endpoint_describes_the_form_without_a_challenge_at_first(): void
    {
        $response = $this->getJson('/api/public/enquiry-form')->assertOk();

        $response->assertJsonPath('data.challenge', null);
        $this->assertNotEmpty($response->json('data.token'));
        $this->assertSame(4, $response->json('data.min_fill_seconds'));

        // The categories travel with their labels so a client that has not been
        // taught a new one still shows a word rather than a code.
        $this->assertSame(
            EnquiryCategory::all(),
            array_column($response->json('data.categories'), 'code'),
        );
    }

    public function test_a_devotee_can_send_a_message_and_is_given_a_reference(): void
    {
        $response = $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
        ]))->assertCreated();

        $reference = $response->json('data.reference');
        $this->assertMatchesRegularExpression('#^RKT/E/\d{4}-\d{2}/0001$#', $reference);

        $enquiry = Enquiry::query()->firstOrFail();
        $this->assertSame('रामप्रसाद यादव', $enquiry->name);
        $this->assertSame(Enquiry::STATUS_NEW, $enquiry->status);
        $this->assertSame('hi', $enquiry->preferred_language);

        // The address is kept as an HMAC, never in the clear (assumption N10).
        $this->assertNotNull($enquiry->submitted_ip_hash);
        $this->assertSame(64, strlen($enquiry->submitted_ip_hash));
        $this->assertStringNotContainsString('127.0.0.1', $enquiry->submitted_ip_hash);
    }

    public function test_the_response_carries_the_reference_and_nothing_else(): void
    {
        $response = $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'message' => 'यह संदेश किसी भी सार्वजनिक उत्तर में नहीं लौटना चाहिए।',
        ]))->assertCreated();

        // Echoing the stored row back would make this endpoint a reflector
        // (assumption N1).
        $this->assertSame(
            ['reference', 'message'],
            array_keys($response->json('data')),
        );
        $this->assertStringNotContainsString(
            'सार्वजनिक उत्तर',
            $response->getContent(),
        );
    }

    public function test_references_run_in_sequence(): void
    {
        // The numbering is what is under test here, not the escalation: past
        // the default threshold the third message would be asked a question,
        // which is a different test's subject.
        config(['enquiries.challenge_threshold' => 99]);

        $references = [];

        for ($i = 0; $i < 3; $i++) {
            // Each submission needs its own ticket: a token is spent once.
            $references[] = $this->postJson('/api/public/enquiries', $this->payload([
                'form_token' => $this->token(),
            ]))->assertCreated()->json('data.reference');
        }

        $this->assertSame(
            ['0001', '0002', '0003'],
            array_map(static fn (string $r): string => substr($r, -4), $references),
        );
    }

    public function test_a_message_needs_a_way_to_reply_to_it(): void
    {
        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'mobile' => null,
            'email' => null,
        ]))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->assertSame(0, Enquiry::query()->count());

        // Either channel on its own is enough.
        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'mobile' => null,
            'email' => 'devotee@example.test',
        ]))->assertCreated();
    }

    public function test_the_message_is_length_bounded_on_the_server(): void
    {
        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'message' => 'बहुत छोटा',
        ]))->assertStatus(422);

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'message' => str_repeat('क', 2001),
        ]))->assertStatus(422);

        $this->assertSame(0, Enquiry::query()->count());
    }

    public function test_an_unknown_category_is_refused(): void
    {
        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'category' => 'whatever-the-client-felt-like',
        ]))->assertStatus(422);

        $this->assertSame(0, Enquiry::query()->count());
    }

    public function test_a_submission_without_a_token_is_refused(): void
    {
        $this->postJson('/api/public/enquiries', $this->payload())
            ->assertStatus(422);

        $this->assertSame(0, Enquiry::query()->count());
    }

    public function test_a_forged_token_is_refused_without_touching_the_cache(): void
    {
        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => 'made-up-nonce.made-up-signature',
        ]))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ENQUIRY_FORM_EXPIRED');

        $this->assertSame(0, Enquiry::query()->count());
    }

    public function test_a_form_filled_in_faster_than_a_person_could_type_is_refused(): void
    {
        $token = $this->getJson('/api/public/enquiry-form')->json('data.token');

        // No travel: the submission arrives in the same instant as the form.
        $this->postJson('/api/public/enquiries', $this->payload(['form_token' => $token]))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ENQUIRY_FORM_EXPIRED');

        $this->assertSame(0, Enquiry::query()->count());
    }

    public function test_a_stale_token_is_refused(): void
    {
        config(['enquiries.token_lifetime_minutes' => 5]);

        $token = $this->getJson('/api/public/enquiry-form')->json('data.token');

        $this->travel(6)->minutes();

        $this->postJson('/api/public/enquiries', $this->payload(['form_token' => $token]))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ENQUIRY_FORM_EXPIRED');
    }

    public function test_a_token_can_be_spent_only_once(): void
    {
        $token = $this->token();

        $this->postJson('/api/public/enquiries', $this->payload(['form_token' => $token]))
            ->assertCreated();

        // The same ticket again: one harvested token is worth one message.
        $this->postJson('/api/public/enquiries', $this->payload(['form_token' => $token]))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ENQUIRY_FORM_EXPIRED');

        $this->assertSame(1, Enquiry::query()->count());
    }

    public function test_the_honeypot_stores_nothing_and_says_nothing(): void
    {
        $response = $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
            'website' => 'http://cheap-pills.example',
        ]))->assertCreated();

        // Indistinguishable from a real submission, apart from carrying no
        // reference — and nothing reached the database (assumption N2).
        $this->assertNull($response->json('data.reference'));
        $this->assertSame(0, Enquiry::query()->count());
    }

    public function test_the_form_starts_asking_a_question_once_the_threshold_is_crossed(): void
    {
        config(['enquiries.challenge_threshold' => 2]);

        for ($i = 0; $i < 2; $i++) {
            $this->postJson('/api/public/enquiries', $this->payload([
                'form_token' => $this->token(),
            ]))->assertCreated();
        }

        $form = $this->getJson('/api/public/enquiry-form')->assertOk();

        $this->assertNotNull($form->json('data.challenge'));
        $this->assertNotEmpty($form->json('data.challenge.question_hi'));
        $this->assertNotEmpty($form->json('data.challenge.question_en'));
    }

    public function test_a_ticket_taken_before_the_threshold_is_not_a_way_past_it(): void
    {
        config(['enquiries.challenge_threshold' => 1]);

        // A clean ticket, fetched before any submission has been made.
        $early = $this->token();

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
        ]))->assertCreated();

        // The threshold is now crossed, and the old ticket carries no answer.
        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $early,
        ]))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ENQUIRY_CHALLENGE_REQUIRED');

        $this->assertSame(1, Enquiry::query()->count());
    }

    public function test_a_wrong_answer_to_the_question_is_refused(): void
    {
        config(['enquiries.challenge_threshold' => 1]);

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
        ]))->assertCreated();

        $form = $this->getJson('/api/public/enquiry-form')->assertOk();
        $this->assertNotNull($form->json('data.challenge'));
        $this->travel(10)->seconds();

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $form->json('data.token'),
            'challenge_answer' => '99',
        ]))->assertStatus(422);

        $this->assertSame(1, Enquiry::query()->count());
    }

    public function test_the_right_answer_is_accepted_in_either_script(): void
    {
        config(['enquiries.challenge_threshold' => 1]);

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
        ]))->assertCreated();

        $form = $this->getJson('/api/public/enquiry-form')->assertOk();
        $this->travel(10)->seconds();

        $answer = $this->solve($form->json('data.challenge.question_en'));

        // Typed on a Hindi keyboard: १२ must be as acceptable as 12.
        $devanagari = strtr($answer, [
            '0' => '०', '1' => '१', '2' => '२', '3' => '३', '4' => '४',
            '5' => '५', '6' => '६', '7' => '७', '8' => '८', '9' => '९',
        ]);

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $form->json('data.token'),
            'challenge_answer' => $devanagari,
        ]))->assertCreated();

        $this->assertSame(2, Enquiry::query()->count());
    }

    public function test_the_daily_ceiling_stops_a_patient_abuser(): void
    {
        config([
            'enquiries.daily_limit_per_ip' => 2,
            'enquiries.challenge_threshold' => 99,
        ]);

        for ($i = 0; $i < 2; $i++) {
            $this->postJson('/api/public/enquiries', $this->payload([
                'form_token' => $this->token(),
            ]))->assertCreated();
        }

        $this->postJson('/api/public/enquiries', $this->payload([
            'form_token' => $this->token(),
        ]))
            ->assertStatus(429)
            ->assertJsonPath('error.code', 'TOO_MANY_REQUESTS');

        $this->assertSame(2, Enquiry::query()->count());
    }

    public function test_the_challenge_window_does_not_extend_itself_forever(): void
    {
        config([
            'enquiries.challenge_threshold' => 2,
            'enquiries.challenge_window_minutes' => 30,
        ]);

        for ($i = 0; $i < 2; $i++) {
            $this->postJson('/api/public/enquiries', $this->payload([
                'form_token' => $this->token(),
            ]))->assertCreated();
        }

        $this->assertNotNull($this->getJson('/api/public/enquiry-form')->json('data.challenge'));

        // Past the window: a visitor who wrote twice an hour ago is not made to
        // do arithmetic for the rest of the day.
        $this->travel(31)->minutes();

        $this->assertNull($this->getJson('/api/public/enquiry-form')->json('data.challenge'));
    }

    /** Reads the arithmetic question the server asked, so the test can answer it. */
    private function solve(string $question): string
    {
        $words = [
            'one' => 1, 'two' => 2, 'three' => 3, 'four' => 4, 'five' => 5,
            'six' => 6, 'seven' => 7, 'eight' => 8, 'nine' => 9,
        ];

        preg_match('/What is (\w+) plus (\w+)\?/', $question, $matches);

        return (string) ($words[$matches[1]] + $words[$matches[2]]);
    }

    protected function tearDown(): void
    {
        Cache::flush();
        parent::tearDown();
    }
}

<?php

declare(strict_types=1);

namespace Tests\Feature\Content;

use App\Models\Announcement;
use App\Models\DonationSetting;
use App\Models\Event;
use App\Models\Page;
use App\Models\Role;
use App\Models\TempleProfile;
use App\Models\User;
use App\Support\EventType;
use Database\Seeders\DevelopmentContentSeeder;
use Database\Seeders\PageStructureSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The committee's approved copy, as the seeder loads it.
 *
 * This is not a test of the seeder for its own sake. Every assertion here is a
 * difference somebody found by reading the live site against the approved
 * prototype (`docs/PROTOTYPE_CONTENT_MATCH.md`), and each one is cheap to
 * reintroduce by editing a string.
 */
class ApprovedContentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(PageStructureSeeder::class);
        $this->seed(DevelopmentContentSeeder::class);
    }

    /**
     * The committee spells it without the nukta.
     *
     * `ग़ैर` and `गैर` look nearly identical at reading size and sort
     * differently, so this is the kind of thing that survives a proof-read and
     * only a byte comparison catches.
     */
    public function test_non_profit_is_spelt_the_way_the_committee_writes_it(): void
    {
        $written = [
            TempleProfile::query()->sole()->history_hi,
            Page::query()->where('slug', Page::SLUG_ABOUT)->sole()->content_hi,
            Page::query()->where('slug', Page::SLUG_HOME)->sole()->meta_description_hi,
        ];

        foreach ($written as $text) {
            $this->assertStringNotContainsString('ग़ैर-लाभकारी', (string) $text);
            $this->assertStringContainsString('गैर-लाभकारी', (string) $text);
        }
    }

    /** The address exists in both scripts, so neither page shows the other's. */
    public function test_the_address_is_written_in_both_scripts(): void
    {
        $profile = TempleProfile::query()->sole();

        $this->assertSame('अमरपुर पंखोरिया', $profile->village_hi);
        $this->assertSame('Amarpur Pankhoriya', $profile->village_en);
        $this->assertSame('कुर्मा', $profile->panchayat_hi);
        $this->assertSame('रसूलपुर एकचारी', $profile->police_station_hi);
        $this->assertSame('भागलपुर', $profile->district_hi);
        $this->assertSame('बिहार', $profile->state_hi);
        // One postal code, because 813204 is 813204 in either language.
        $this->assertSame('813204', $profile->postal_code);
    }

    /**
     * The three About cards, in the shape the public site renders as cards.
     *
     * A paragraph of `<emoji> <heading> — <text>`. If somebody reflows this
     * page into one paragraph the grid quietly becomes a wall of text, which is
     * exactly what happened before.
     */
    public function test_the_about_page_still_carries_three_card_paragraphs(): void
    {
        $body = (string) Page::query()->where('slug', Page::SLUG_ABOUT)->sole()->content_hi;

        $paragraphs = preg_split('/\n\s*\n/', trim($body)) ?: [];
        $cards = array_values(array_filter(
            $paragraphs,
            static fn (string $p) => str_contains($p, ' — '),
        ));

        $this->assertCount(3, $cards);
        $this->assertStringContainsString('हमारी विरासत', $cards[0]);
        $this->assertStringContainsString('ग्राम सहभागिता', $cards[1]);
        $this->assertStringContainsString('सेवा और भक्ति', $cards[2]);
    }

    /** The prototype's notice band is a real, published, scheduled record. */
    public function test_the_notice_is_a_published_announcement(): void
    {
        $notice = Announcement::query()->sole();

        $this->assertSame('आज की सूचना', $notice->title_hi);
        $this->assertSame(Announcement::STATUS_PUBLISHED, $notice->status);
        // Both sentences: the aarti time and the Janmashtami request. The
        // second one went missing once already.
        $this->assertStringContainsString('6:30', (string) $notice->message_hi);
        $this->assertStringContainsString('जन्माष्टमी', (string) $notice->message_hi);

        $this->getJson('/api/public/announcements')
            ->assertOk()
            ->assertJsonPath('data.0.title.value', 'आज की सूचना');
    }

    /**
     * The donation block has its wording and nothing payable.
     *
     * The prototype's `temple@upi` and `Demo Bank` must never be seeded: a
     * donor who acts on an invented account number loses money. So the block
     * stays invisible until the committee enters something real, and this test
     * is what keeps a future "let's make the demo look complete" change honest.
     */
    public function test_the_donation_block_is_worded_but_has_nothing_payable(): void
    {
        $settings = DonationSetting::query()->sole();

        $this->assertNotEmpty($settings->intro_hi);
        $this->assertNull($settings->upi_id);
        $this->assertNull($settings->bank_name);
        $this->assertNull($settings->account_number);
        $this->assertFalse($settings->isPubliclyVisible());
    }

    /** Bhandara is community service, not "other". */
    public function test_the_bhandara_is_filed_as_community_service(): void
    {
        $bhandara = Event::query()->where('title_hi', 'भंडारा एवं प्रसाद')->sole();

        $this->assertSame(EventType::COMMUNITY_SERVICE, $bhandara->event_type);
        $this->assertTrue(EventType::exists(EventType::COMMUNITY_SERVICE));
    }

    /**
     * A caller still sending the retired single-language field is refused.
     *
     * The alternative is a 200 with nothing saved, which is exactly the silent
     * narrowing this project refuses everywhere else — and the hardest kind of
     * bug to find, because the request looked like it worked.
     */
    public function test_the_retired_address_field_is_refused_not_ignored(): void
    {
        $editor = User::factory()->withRole(Role::ADMIN)->create();

        $this->actingAs($editor, 'web')
            ->putJson('/api/admin/temple-profile', ['village' => 'Somewhere Else'])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->assertSame('अमरपुर पंखोरिया', TempleProfile::query()->sole()->village_hi);
    }

    /** The public API serves the address in the language that was asked for. */
    public function test_the_public_address_follows_the_requested_language(): void
    {
        $this->getJson('/api/public/temple-profile')
            ->assertOk()
            ->assertJsonPath('data.address.village', 'अमरपुर पंखोरिया')
            ->assertJsonPath('data.address.district', 'भागलपुर');

        $this->getJson('/api/public/temple-profile?lang=en')
            ->assertOk()
            ->assertJsonPath('data.address.village', 'Amarpur Pankhoriya')
            ->assertJsonPath('data.address.district', 'Bhagalpur');
    }

    /**
     * A half-translated address still reads as an address.
     *
     * The English half falls back to the Hindi, part by part, exactly as every
     * other field does — rather than leaving a hole in the middle of a postal
     * address.
     */
    public function test_an_unwritten_english_part_falls_back_to_the_hindi(): void
    {
        TempleProfile::query()->sole()->forceFill(['district_en' => null])->save();

        $this->getJson('/api/public/temple-profile?lang=en')
            ->assertOk()
            ->assertJsonPath('data.address.village', 'Amarpur Pankhoriya')
            ->assertJsonPath('data.address.district', 'भागलपुर');
    }
}

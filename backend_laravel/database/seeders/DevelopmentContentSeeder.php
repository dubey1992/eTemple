<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\CommitteeMember;
use App\Models\DonationSetting;
use App\Models\Event;
use App\Models\NavigationItem;
use App\Models\Page;
use App\Models\SiteSetting;
use App\Models\TempleProfile;
use App\Support\EventType;
use Illuminate\Database\Seeder;

/**
 * Loads the committee's approved copy into the CMS.
 *
 * Every string here is taken from the approved prototype
 * (`radha-krishna-thakurbari-prototype.html`), so a reviewer opening the site
 * sees the wording they signed off on rather than placeholder text.
 *
 * Verbatim, with three exceptions, all recorded in
 * `docs/PROTOTYPE_CONTENT_MATCH.md`: the prototype's demo bank and UPI details
 * are not seeded at all, and the two sentences that describe the mock rather
 * than the temple are rewritten to describe the temple.
 *
 * It is still seed data and still refuses to run in production: on a real
 * deployment the committee owns this content and a seeder must never overwrite
 * what they have written. Loading the approved copy into production is a
 * deliberate one-off step, recorded in the deployment checklist.
 */
class DevelopmentContentSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            $this->command?->warn('[seed] Skipped: this seeder never runs in production.');

            return;
        }

        $this->seedProfile();
        $this->seedSettings();
        $this->seedPages();
        $this->seedNotice();
        $this->seedDonationIntro();
        $this->seedEvents();
        $this->seedCommittee();
        $this->seedNavigation();

        $this->command?->info('[seed] Approved prototype content loaded into the CMS.');
    }

    private function seedProfile(): void
    {
        $profile = TempleProfile::query()->oldest('id')->first()
            ?? TempleProfile::query()->create([]);

        $profile->forceFill([
            'name_hi' => 'राधा कृष्ण ठाकुरबाड़ी',
            'name_en' => 'Radha Krishna Thakurbari',

            // The hero paragraph.
            'mission_hi' => 'अमरपुर पंखोरिया ग्राम स्थित यह ठाकुरबाड़ी ग्रामवासियों की आस्था, '
                .'सेवा, सहयोग और सांस्कृतिक एकता का केंद्र है।',
            'mission_en' => 'Located in Amarpur Pankhoriya, this temple is a center of faith, '
                .'service, community participation and cultural unity.',

            // The "मंदिर परिचय" lead paragraph.
            'history_hi' => 'राधा कृष्ण ठाकुरबाड़ी एक सामुदायिक एवं गैर-लाभकारी धार्मिक स्थल है, '
                .'जिसका संचालन ग्रामवासियों के सहयोग से किया जाता है।',
            'history_en' => 'Radha Krishna Thakurbari is a community-run, non-profit religious '
                .'place managed with the support of villagers.',

            // Both scripts. The strip above the header used to show the Roman
            // spelling on a Hindi page, which is the wrong language on the
            // front page of a village temple's website.
            'village_hi' => 'अमरपुर पंखोरिया',
            'village_en' => 'Amarpur Pankhoriya',
            'panchayat_hi' => 'कुर्मा',
            'panchayat_en' => 'Kurma',
            'police_station_hi' => 'रसूलपुर एकचारी',
            'police_station_en' => 'Rasulpur Ekchari',
            'district_hi' => 'भागलपुर',
            'district_en' => 'Bhagalpur',
            'state_hi' => 'बिहार',
            'state_en' => 'Bihar',
            'postal_code' => '813204',
            'country_hi' => 'भारत',
            'country_en' => 'India',
        ])->save();
    }

    private function seedSettings(): void
    {
        $settings = SiteSetting::query()->oldest('id')->first()
            ?? SiteSetting::query()->create([]);

        $settings->forceFill([
            // The line the prototype puts in the strip above the header.
            'tagline_hi' => 'ग्रामवासियों द्वारा संचालित गैर-लाभकारी मंदिर',
            'tagline_en' => 'A non-profit temple managed by the villagers',

            'footer_text_hi' => 'अमरपुर पंखोरिया ग्रामवासियों द्वारा संचालित एक गैर-लाभकारी '
                .'धार्मिक एवं सामुदायिक मंदिर।',
            'footer_text_en' => 'A non-profit religious and community temple managed by the '
                .'villagers of Amarpur Pankhoriya.',
        ])->save();
    }

    private function seedPages(): void
    {
        Page::query()->where('slug', Page::SLUG_HOME)->update([
            'title_hi' => 'राधा कृष्ण ठाकुरबाड़ी',
            'title_en' => 'Radha Krishna Thakurbari',
            'content_hi' => 'अमरपुर पंखोरिया ग्राम स्थित यह ठाकुरबाड़ी ग्रामवासियों की आस्था, '
                .'सेवा, सहयोग और सांस्कृतिक एकता का केंद्र है।',
            'content_en' => 'Located in Amarpur Pankhoriya, this temple is a center of faith, '
                .'service, community participation and cultural unity.',
            'meta_title_hi' => 'राधा कृष्ण ठाकुरबाड़ी | अमरपुर पंखोरिया',
            'meta_title_en' => 'Radha Krishna Thakurbari | Amarpur Pankhoriya',
            'meta_description_hi' => 'राधा कृष्ण ठाकुरबाड़ी, अमरपुर पंखोरिया — ग्रामवासियों '
                .'द्वारा संचालित गैर-लाभकारी मंदिर।',
            'meta_description_en' => 'Radha Krishna Thakurbari, Amarpur Pankhoriya — a '
                .'non-profit temple managed by the villagers.',
            'status' => Page::STATUS_PUBLISHED,
            'published_at' => now(),
        ]);

        // The prototype's three "मंदिर परिचय" cards. A paragraph shaped
        // `<emoji> <heading> — <text>` renders as a card on the public site, so
        // these stay ordinary CMS content the committee can edit, add to or
        // remove without a release.
        Page::query()->where('slug', Page::SLUG_ABOUT)->update([
            'title_hi' => 'मंदिर परिचय',
            'title_en' => 'About the Temple',
            'content_hi' => 'राधा कृष्ण ठाकुरबाड़ी एक सामुदायिक एवं गैर-लाभकारी धार्मिक स्थल है, '
                ."जिसका संचालन ग्रामवासियों के सहयोग से किया जाता है।\n\n"
                .'🛕 हमारी विरासत — मंदिर के इतिहास, स्थापना और स्थानीय परंपराओं को आने वाली '
                ."पीढ़ियों के लिए संरक्षित करना।\n\n"
                .'🤝 ग्राम सहभागिता — पूजा, त्योहार, सेवा और विकास कार्य ग्रामवासियों के सामूहिक '
                ."सहयोग से संचालित होते हैं।\n\n"
                .'🪔 सेवा और भक्ति — नियमित पूजा, आरती, भजन-कीर्तन और धार्मिक आयोजनों के माध्यम से '
                .'आध्यात्मिक वातावरण।',
            'content_en' => 'Radha Krishna Thakurbari is a community-run, non-profit religious '
                ."place managed with the support of villagers.\n\n"
                ."🛕 Our Heritage — preserving the temple's history, foundation and local "
                ."traditions for future generations.\n\n"
                .'🤝 Village Participation — worship, festivals, service and development '
                ."activities are organized through community support.\n\n"
                .'🪔 Service and Devotion — a spiritual environment through regular puja, aarti, '
                .'bhajan-kirtan and religious programs.',
            'status' => Page::STATUS_PUBLISHED,
            'published_at' => now(),
        ]);
    }

    /**
     * The prototype's notice band, as the announcement it actually is.
     *
     * The prototype hardcodes this into the page. Here it is a scheduled,
     * publishable record: the committee takes it down when Janmashtami is over
     * without anybody touching the site.
     */
    private function seedNotice(): void
    {
        Announcement::query()->delete();

        $notice = Announcement::query()->create([
            'title_hi' => 'आज की सूचना',
            'title_en' => "Today's Notice",
            'message_hi' => 'संध्या आरती प्रतिदिन शाम 6:30 बजे। जन्माष्टमी महोत्सव की तैयारी '
                .'हेतु सभी ग्रामवासियों से सहयोग का अनुरोध है।',
            'message_en' => 'Evening Aarti is held daily at 6:30 PM. Villagers are requested '
                .'to support preparations for the Janmashtami celebration.',
            'priority' => 'important',
            'start_at' => now()->subDay(),
        ]);

        // Publishing is a decision rather than a fillable column, so it is set
        // here rather than passed in.
        $notice->forceFill(['status' => Announcement::STATUS_PUBLISHED])->save();
    }

    /**
     * The wording of the donation block — and nothing payable.
     *
     * The prototype's `temple@upi` and `Demo Bank` are invented payment details
     * and are deliberately absent: a donor who acts on them loses money. So the
     * block stays invisible until the committee enters a real UPI ID or bank
     * account, which is the Phase 6 rule and the right one.
     *
     * The prototype's own sentence describes the mock ("details *can be
     * displayed* here"); this says what the temple does.
     */
    private function seedDonationIntro(): void
    {
        $settings = DonationSetting::query()->oldest('id')->first()
            ?? DonationSetting::query()->create([]);

        $settings->forceFill([
            'intro_hi' => 'मंदिर UPI, बैंक ट्रांसफर और नकद — तीनों माध्यमों से सहयोग स्वीकार '
                .'करता है। सत्यापन के बाद डिजिटल रसीद उपलब्ध कराई जाती है।',
            'intro_en' => 'The temple accepts support by UPI, bank transfer and cash. A digital '
                .'receipt is issued once the donation has been verified.',
            'note_hi' => 'दान से प्राप्त राशि का उपयोग पूजा व्यवस्था, रखरखाव, त्योहार और सेवा '
                .'कार्यों में किया जाता है, और उसका लेखा-जोखा वेबसाइट पर प्रकाशित होता है।',
            'note_en' => 'Donations are used for worship arrangements, maintenance, festivals '
                .'and community service, and the accounts are published on this website.',
        ])->save();
    }

    /**
     * The prototype's three event cards.
     *
     * The daily aarti named in its notice banner is added as the recurring rule
     * it actually is, rather than as a sentence somebody has to keep up to date.
     */
    private function seedEvents(): void
    {
        Event::query()->delete();

        Event::query()->create([
            'event_type' => EventType::AARTI,
            'title_hi' => 'संध्या आरती',
            'title_en' => 'Evening Aarti',
            'description_hi' => 'संध्या आरती प्रतिदिन शाम 6:30 बजे।',
            'description_en' => 'Evening aarti is held daily at 6:30 PM.',
            'venue_hi' => 'मुख्य मंदिर',
            'venue_en' => 'Main shrine',
            'start_at' => now()->subMonths(6)->setTime(18, 30),
            'end_at' => now()->subMonths(6)->setTime(19, 15),
            'recurrence' => Event::RECURRENCE_DAILY,
            'status' => Event::STATUS_PUBLISHED,
        ]);

        Event::query()->create([
            'event_type' => EventType::BHAJAN_KIRTAN,
            'title_hi' => 'भजन एवं कीर्तन',
            'title_en' => 'Bhajan & Kirtan',
            'description_hi' => 'ग्रामवासियों के साथ सामूहिक भजन-कीर्तन एवं संध्या आरती।',
            'description_en' => 'Community bhajan-kirtan followed by evening aarti.',
            'venue_hi' => 'मंदिर प्रांगण',
            'venue_en' => 'Temple courtyard',
            'start_at' => now()->subMonths(3)->setTime(19, 0),
            'end_at' => now()->subMonths(3)->setTime(21, 0),
            'recurrence' => Event::RECURRENCE_WEEKLY,
            // Tuesday and Saturday.
            'recurrence_days' => [2, 6],
            'status' => Event::STATUS_PUBLISHED,
        ]);

        Event::query()->create([
            'event_type' => EventType::FESTIVAL,
            'title_hi' => 'श्री कृष्ण जन्माष्टमी',
            'title_en' => 'Shri Krishna Janmashtami',
            'description_hi' => 'विशेष पूजा, भजन-कीर्तन, प्रसाद वितरण और ग्राम सहभागिता। '
                .'जन्माष्टमी महोत्सव की तैयारी हेतु सभी ग्रामवासियों से सहयोग का अनुरोध है।',
            'description_en' => 'Special puja, bhajan-kirtan, prasad distribution and village '
                .'participation.',
            'venue_hi' => 'मंदिर परिसर',
            'venue_en' => 'Temple premises',
            'start_at' => now()->addDays(21)->setTime(17, 0),
            'end_at' => now()->addDays(22)->setTime(1, 0),
            'is_featured' => true,
            'status' => Event::STATUS_PUBLISHED,
        ]);

        Event::query()->create([
            'event_type' => EventType::COMMUNITY_SERVICE,
            'title_hi' => 'भंडारा एवं प्रसाद',
            'title_en' => 'Bhandara & Prasad',
            'description_hi' => 'विशेष अवसरों पर श्रद्धालुओं के लिए प्रसाद एवं सामूहिक भोजन '
                .'की व्यवस्था।',
            'description_en' => 'Prasad and community meals for devotees on special occasions.',
            'venue_hi' => 'मंदिर परिसर',
            'venue_en' => 'Temple premises',
            'start_at' => now()->addDays(21)->setTime(12, 0),
            'end_at' => now()->addDays(21)->setTime(15, 0),
            'status' => Event::STATUS_PUBLISHED,
        ]);
    }

    /**
     * The prototype's four committee seats.
     *
     * The names are the prototype's own placeholder ("सदस्य नाम"): the committee
     * has not published who holds each seat, and inventing villagers would be
     * worse than showing the seat unfilled. No personal detail is consented,
     * so none is published — the cards show the designation only.
     */
    private function seedCommittee(): void
    {
        CommitteeMember::query()->delete();

        $seats = [
            ['अध्यक्ष', 'President'],
            ['सचिव', 'Secretary'],
            ['कोषाध्यक्ष', 'Treasurer'],
            ['सदस्य', 'Member'],
        ];

        foreach ($seats as $index => [$hindi, $english]) {
            CommitteeMember::query()->create([
                'name_hi' => 'सदस्य नाम',
                'name_en' => 'Member Name',
                'designation_hi' => $hindi,
                'designation_en' => $english,
                'is_published' => true,
                'sort_order' => $index,
            ]);
        }
    }

    private function seedNavigation(): void
    {
        NavigationItem::query()->delete();

        foreach ([
            ['label_hi' => 'मुख्य पृष्ठ', 'label_en' => 'Home', 'route' => '/', 'sort_order' => 0],
            ['label_hi' => 'मंदिर परिचय', 'label_en' => 'About', 'route' => '/about', 'sort_order' => 1],
            ['label_hi' => 'कार्यक्रम', 'label_en' => 'Events', 'route' => '/events', 'sort_order' => 2],
            ['label_hi' => 'दान', 'label_en' => 'Donate', 'route' => '/donate', 'sort_order' => 3],
            ['label_hi' => 'गैलरी', 'label_en' => 'Gallery', 'route' => '/gallery', 'sort_order' => 4],
            ['label_hi' => 'मंदिर समिति', 'label_en' => 'Committee', 'route' => '/committee', 'sort_order' => 5],
            ['label_hi' => 'संपर्क', 'label_en' => 'Contact', 'route' => '/contact', 'sort_order' => 6],
        ] as $item) {
            NavigationItem::query()->create($item + ['is_visible' => true]);
        }
    }
}

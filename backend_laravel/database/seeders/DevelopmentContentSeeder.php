<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\CommitteeMember;
use App\Models\Event;
use App\Models\NavigationItem;
use App\Models\Page;
use App\Models\SiteSetting;
use App\Models\TempleProfile;
use App\Support\EventType;
use Illuminate\Database\Seeder;

/**
 * DEVELOPMENT / DEMO CONTENT ONLY.
 *
 * Fills the scaffolded pages, the site settings and the navigation menu with
 * sample text so the site can be exercised locally. Every string here is
 * placeholder copy, NOT approved temple content, and this seeder refuses to run
 * in production so it can never leak into the real site.
 */
class DevelopmentContentSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            $this->command?->warn('[dev-seed] Skipped: DevelopmentContentSeeder never runs in production.');

            return;
        }

        Page::query()->where('slug', Page::SLUG_HOME)->update([
            'title_hi' => 'राधा कृष्ण ठाकुरबाड़ी',
            'title_en' => 'Radha Krishna Thakurbari',
            'content_hi' => "यह नमूना सामग्री है। समिति द्वारा वास्तविक विवरण जोड़ा जाएगा।\n\n"
                .'मंदिर प्रतिदिन प्रातः और संध्या आरती के लिए खुला रहता है।',
            'content_en' => "This is sample content. The committee will add the real details.\n\n"
                .'The temple is open daily for morning and evening aarti.',
            'meta_title_hi' => 'राधा कृष्ण ठाकुरबाड़ी, अमरपुर पंखोरिया',
            'meta_title_en' => 'Radha Krishna Thakurbari, Amarpur Pankhoriya',
            'meta_description_hi' => 'अमरपुर पंखोरिया गाँव का राधा कृष्ण मंदिर — दर्शन, आरती और सेवा की जानकारी।',
            'meta_description_en' => 'The Radha Krishna temple of Amarpur Pankhoriya village.',
            'status' => Page::STATUS_PUBLISHED,
            'published_at' => now(),
        ]);

        Page::query()->where('slug', Page::SLUG_ABOUT)->update([
            'title_hi' => 'हमारे बारे में',
            'title_en' => 'About us',
            // Hindi only on purpose, so the English fallback path is visible locally.
            'content_hi' => 'यह नमूना पाठ है। मंदिर की स्थापना, इतिहास और सेवा कार्यों का विवरण '
                .'समिति द्वारा जोड़ा जाएगा।',
            'content_en' => null,
            'status' => Page::STATUS_PUBLISHED,
            'published_at' => now(),
        ]);

        $settings = SiteSetting::query()->oldest('id')->first() ?? SiteSetting::query()->create([]);
        $settings->forceFill([
            'tagline_hi' => 'भक्ति, सेवा और ग्राम समुदाय का केंद्र',
            'tagline_en' => 'A centre of devotion, service and village community',
            'footer_text_hi' => 'यह एक विकास-परिवेश की नमूना पंक्ति है।',
            'footer_text_en' => 'This is a sample development-environment line.',
            'contact_email' => 'committee@thakurbari.local',
        ])->save();

        // The temple's own identity and address, authoritative since Phase 3.
        $profile = TempleProfile::query()->oldest('id')->first()
            ?? TempleProfile::query()->create([]);
        $profile->forceFill([
            'name_hi' => 'राधा कृष्ण ठाकुरबाड़ी',
            'name_en' => 'Radha Krishna Thakurbari',
            'history_hi' => 'यह नमूना पाठ है। मंदिर की स्थापना और इतिहास समिति द्वारा जोड़ा जाएगा।',
            // Hindi only on purpose, so the English fallback path is visible locally.
            'history_en' => null,
            'mission_hi' => 'भक्ति, सेवा और ग्राम समुदाय की सेवा।',
            'mission_en' => 'Devotion, service, and service to the village community.',
            'village' => 'Amarpur Pankhoriya',
            'panchayat' => 'Kurma',
            'police_station' => 'Rasulpur Ekchari',
            'district' => 'Bhagalpur',
            'state' => 'Bihar',
            'postal_code' => '813204',
            'country' => 'India',
        ])->save();

        // Sample committee members. The consent gate is exercised deliberately:
        // one member has consented and is fully visible, one has consented to
        // nothing, and one is not published at all.
        CommitteeMember::query()->delete();
        CommitteeMember::query()->create([
            'name_hi' => 'नमूना अध्यक्ष',
            'name_en' => 'Sample President',
            'designation_hi' => 'अध्यक्ष',
            'designation_en' => 'President',
            'phone' => '+91 90000 00001',
            'email' => 'president@thakurbari.local',
            'tenure_start' => now()->subYears(2)->toDateString(),
            'is_published' => true,
            'sort_order' => 0,
        ])->forceFill([
            'contact_consent_at' => now()->subMonths(3),
            'show_phone_publicly' => true,
            'show_email_publicly' => true,
        ])->save();

        CommitteeMember::query()->create([
            'name_hi' => 'नमूना कोषाध्यक्ष',
            'name_en' => 'Sample Treasurer',
            'designation_hi' => 'कोषाध्यक्ष',
            'designation_en' => 'Treasurer',
            'phone' => '+91 90000 00002',
            'tenure_start' => now()->subYear()->toDateString(),
            'is_published' => true,
            'sort_order' => 1,
        ]);

        CommitteeMember::query()->create([
            'name_hi' => 'नमूना सदस्य (अप्रकाशित)',
            'designation_hi' => 'सदस्य',
            'tenure_start' => now()->subMonths(6)->toDateString(),
            'is_published' => false,
            'sort_order' => 2,
        ]);

        NavigationItem::query()->delete();
        foreach ([
            ['label_hi' => 'मुख पृष्ठ', 'label_en' => 'Home', 'route' => '/', 'sort_order' => 0],
            ['label_hi' => 'हमारे बारे में', 'label_en' => 'About', 'route' => '/about', 'sort_order' => 1],
            ['label_hi' => 'प्रबंध समिति', 'label_en' => 'Committee', 'route' => '/committee', 'sort_order' => 2],
            ['label_hi' => 'कार्यक्रम', 'label_en' => 'Events', 'route' => '/events', 'sort_order' => 3],
        ] as $item) {
            NavigationItem::query()->create($item + ['is_visible' => true]);
        }

        // Sample calendar. The aarti is deliberately one recurring row rather
        // than a row a day — that is the whole point of the recurrence rule.
        Event::query()->delete();
        Event::query()->create([
            'event_type' => EventType::AARTI,
            'title_hi' => 'संध्या आरती',
            'title_en' => 'Evening aarti',
            'description_hi' => 'प्रतिदिन संध्या आरती एवं प्रसाद वितरण।',
            'description_en' => 'Daily evening aarti followed by prasad.',
            'venue_hi' => 'मुख्य मंदिर',
            'venue_en' => 'Main shrine',
            'start_at' => now()->subMonths(6)->setTime(18, 30),
            'end_at' => now()->subMonths(6)->setTime(19, 15),
            'recurrence' => Event::RECURRENCE_DAILY,
            'status' => Event::STATUS_PUBLISHED,
        ]);

        Event::query()->create([
            'event_type' => EventType::BHAJAN_KIRTAN,
            'title_hi' => 'साप्ताहिक भजन-कीर्तन',
            'title_en' => 'Weekly bhajan-kirtan',
            'venue_hi' => 'मंदिर प्रांगण',
            'start_at' => now()->subMonths(3)->setTime(19, 0),
            'end_at' => now()->subMonths(3)->setTime(21, 0),
            'recurrence' => Event::RECURRENCE_WEEKLY,
            // Tuesday and Saturday.
            'recurrence_days' => [2, 6],
            'status' => Event::STATUS_PUBLISHED,
        ]);

        Event::query()->create([
            'event_type' => EventType::FESTIVAL,
            'title_hi' => 'जन्माष्टमी महोत्सव',
            'title_en' => 'Janmashtami festival',
            'description_hi' => 'यह नमूना विवरण है। वास्तविक कार्यक्रम समिति द्वारा जोड़ा जाएगा।',
            'description_en' => null,
            'venue_hi' => 'मंदिर परिसर',
            'start_at' => now()->addDays(21)->setTime(17, 0),
            'end_at' => now()->addDays(22)->setTime(1, 0),
            'is_featured' => true,
            'status' => Event::STATUS_PUBLISHED,
        ]);

        Event::query()->create([
            'event_type' => EventType::PUJA,
            'title_hi' => 'नमूना मसौदा कार्यक्रम',
            'start_at' => now()->addDays(30)->setTime(10, 0),
            'status' => Event::STATUS_DRAFT,
        ]);

        $this->command?->info(
            '[dev-seed] Sample public content, temple profile, committee, calendar, '
            .'settings and navigation ready.'
        );
    }
}

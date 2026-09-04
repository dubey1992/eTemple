<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\NavigationItem;
use App\Models\Page;
use App\Models\SiteSetting;
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
            'village' => 'Amarpur Pankhoriya',
            'panchayat' => 'Kurma',
            'police_station' => 'Rasulpur Ekchari',
            'district' => 'Bhagalpur',
            'state' => 'Bihar',
            'postal_code' => '813204',
            'country' => 'India',
        ])->save();

        NavigationItem::query()->delete();
        foreach ([
            ['label_hi' => 'मुख पृष्ठ', 'label_en' => 'Home', 'route' => '/', 'sort_order' => 0],
            ['label_hi' => 'हमारे बारे में', 'label_en' => 'About', 'route' => '/about', 'sort_order' => 1],
        ] as $item) {
            NavigationItem::query()->create($item + ['is_visible' => true]);
        }

        $this->command?->info('[dev-seed] Sample public content, settings and navigation ready.');
    }
}

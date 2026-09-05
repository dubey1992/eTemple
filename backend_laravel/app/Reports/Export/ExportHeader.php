<?php

declare(strict_types=1);

namespace App\Reports\Export;

use App\Models\User;
use App\Reports\ReportResult;
use App\Services\Temple\TempleProfileService;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Support\Carbon;

/**
 * The block every export carries at its top.
 *
 * A printed sheet passed round a meeting with no date and no statement of its
 * filters is a sheet somebody will misread — "these are last year's figures, not
 * this year's" is not a discovery to make afterwards
 * (PHASE_10_PLAN assumption N7).
 *
 * It is built once, here, so all three formats say the same thing.
 */
class ExportHeader
{
    public function __construct(private readonly TempleProfileService $temple) {}

    /**
     * @return list<array{0: string, 1: string}> label/value pairs, in order
     */
    public function lines(ReportResult $result, User $actor): array
    {
        $english = $result->language === Language::English;

        $lines = [
            [$english ? 'Temple' : 'मंदिर', $this->templeName($result->language)],
            [$english ? 'Report' : 'रिपोर्ट', $result->title()],
        ];

        if ($result->filters !== []) {
            $lines[] = [
                $english ? 'Filters' : 'छाँट',
                implode(' · ', $result->filters),
            ];
        }

        $lines[] = [
            $english ? 'Generated' : 'तैयार किया',
            Carbon::now()->toDayDateTimeString().' — '.$actor->fullName(),
        ];

        // Said in words, on the file itself, so whoever opens it in six months
        // knows what they are holding (assumption N2).
        if ($result->includesPersonal) {
            $lines[] = [
                $english ? 'Contains personal data' : 'व्यक्तिगत जानकारी सम्मिलित',
                $english
                    ? 'This file contains names and contact details. Handle and share it accordingly.'
                    : 'इस फ़ाइल में नाम एवं संपर्क विवरण हैं। इसे सावधानी से रखें और साझा करें।',
            ];
        }

        if ($result->truncated) {
            $lines[] = [
                $english ? 'Incomplete' : 'अपूर्ण',
                $english
                    ? 'This export reached the row limit. Choose a shorter period to get the rest.'
                    : 'यह निर्यात पंक्ति सीमा तक पहुँच गया। शेष के लिए छोटी अवधि चुनें।',
            ];
        }

        return $lines;
    }

    private function templeName(Language $language): string
    {
        $profile = $this->temple->current();

        return LocalizedText::resolve($profile->name_hi, $profile->name_en, $language)->value
            ?? '';
    }

    /**
     * A safe, dated file name.
     *
     * ASCII only, deliberately: a Devanagari file name survives a modern
     * browser and then arrives mangled through e-mail, a shared drive or an
     * older Android phone, which is where a committee's files actually travel.
     */
    public function filename(ReportResult $result, string $extension): string
    {
        return sprintf(
            '%s-%s.%s',
            $result->report->key(),
            Carbon::now()->format('Y-m-d'),
            $extension,
        );
    }
}

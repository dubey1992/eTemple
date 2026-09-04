<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\CommitteeMember;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CommitteeMember>
 */
class CommitteeMemberFactory extends Factory
{
    protected $model = CommitteeMember::class;

    /**
     * The safe default: a member with personal details on file, unpublished and
     * without consent. A test that wants publication has to ask for it, which
     * is the same way the product behaves.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name_hi' => 'परीक्षण सदस्य',
            'name_en' => 'Test Member',
            'designation_hi' => 'अध्यक्ष',
            'designation_en' => 'President',
            'bio_hi' => null,
            'bio_en' => null,
            'phone' => '+91 90000 00000',
            'email' => 'member@example.test',
            'photo_url' => 'https://cdn.example.test/member.jpg',
            'tenure_start' => now()->subYear()->toDateString(),
            'tenure_end' => null,
            'is_published' => false,
            'show_phone_publicly' => false,
            'show_email_publicly' => false,
            'show_photo_publicly' => false,
            'sort_order' => 0,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (CommitteeMember $member) {
            $member->forceFill([
                'contact_consent_at' => $member->contact_consent_at,
                'consent_recorded_by' => $member->consent_recorded_by ?? null,
                'created_by' => $member->created_by ?? null,
                'updated_by' => $member->updated_by ?? null,
            ]);
        });
    }

    public function published(): static
    {
        return $this->state(fn () => ['is_published' => true]);
    }

    /** Consent on record, but nothing yet chosen to show. */
    public function consented(): static
    {
        return $this->state(fn () => ['contact_consent_at' => now()->subMonth()]);
    }

    /**
     * Consent on record and every personal detail cleared for publication.
     *
     * The combination the public endpoint is allowed to reveal in full.
     */
    public function fullyPublic(): static
    {
        return $this->state(fn () => [
            'is_published' => true,
            'contact_consent_at' => now()->subMonth(),
            'show_phone_publicly' => true,
            'show_email_publicly' => true,
            'show_photo_publicly' => true,
        ]);
    }

    /** A member whose term has ended: kept as history, off the public list. */
    public function pastMember(): static
    {
        return $this->state(fn () => [
            'is_published' => true,
            'tenure_start' => now()->subYears(4)->toDateString(),
            'tenure_end' => now()->subYear()->toDateString(),
        ]);
    }

    public function hindiOnly(): static
    {
        return $this->state(fn () => [
            'name_en' => null,
            'designation_en' => null,
            'bio_en' => null,
        ]);
    }
}

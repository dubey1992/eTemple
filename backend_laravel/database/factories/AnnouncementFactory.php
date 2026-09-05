<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Announcement;
use App\Support\AnnouncementPriority;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Announcement>
 */
class AnnouncementFactory extends Factory
{
    protected $model = Announcement::class;

    /**
     * The safe default: a **draft**, showing nowhere and sent to nobody.
     *
     * A test that wants an announcement on the website has to publish it, and
     * one that wants it sent has to send it — the same two decisions a person
     * makes. No test can accidentally assert against a notice that was never
     * put out.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title_hi' => 'जन्माष्टमी महोत्सव',
            'title_en' => null,
            'message_hi' => 'इस वर्ष जन्माष्टमी का आयोजन मंदिर प्रांगण में होगा। सभी ग्रामवासी आमंत्रित हैं।',
            'message_en' => null,
            'priority' => AnnouncementPriority::NORMAL,
            'start_at' => now()->subHour(),
            'end_at' => null,
            'channels' => null,
            'status' => Announcement::STATUS_DRAFT,
            'link_url' => null,
            'created_by' => null,
            'updated_by' => null,
            'sent_at' => null,
            'sent_by' => null,
            'recipient_count' => null,
        ];
    }

    /** Published and inside its window: on the website now. */
    public function showing(): static
    {
        return $this->state(fn () => [
            'status' => Announcement::STATUS_PUBLISHED,
            'start_at' => now()->subHour(),
            'end_at' => null,
        ]);
    }

    /** Published, but its window has not opened. */
    public function scheduled(): static
    {
        return $this->state(fn () => [
            'status' => Announcement::STATUS_PUBLISHED,
            'start_at' => now()->addDays(3),
            'end_at' => now()->addDays(10),
        ]);
    }

    /** Published, but its window has closed. */
    public function expired(): static
    {
        return $this->state(fn () => [
            'status' => Announcement::STATUS_PUBLISHED,
            'start_at' => now()->subDays(10),
            'end_at' => now()->subDay(),
        ]);
    }

    public function archived(): static
    {
        return $this->state(fn () => ['status' => Announcement::STATUS_ARCHIVED]);
    }

    public function urgent(): static
    {
        return $this->state(fn () => ['priority' => AnnouncementPriority::URGENT]);
    }

    public function important(): static
    {
        return $this->state(fn () => ['priority' => AnnouncementPriority::IMPORTANT]);
    }
}

<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Event;
use App\Support\EventType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Event>
 */
class EventFactory extends Factory
{
    protected $model = Event::class;

    /**
     * The safe default: a one-off draft. A test that wants something public has
     * to ask, the same way the committee does.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'event_type' => EventType::PUJA,
            'title_hi' => 'परीक्षण कार्यक्रम',
            'title_en' => 'Test event',
            'description_hi' => 'हिन्दी विवरण।',
            'description_en' => 'English description.',
            'venue_hi' => 'मंदिर प्रांगण',
            'venue_en' => 'Temple courtyard',
            'start_at' => now()->addDays(3)->setTime(18, 0),
            'end_at' => now()->addDays(3)->setTime(20, 0),
            'recurrence' => Event::RECURRENCE_NONE,
            'recurrence_days' => null,
            'recurrence_until' => null,
            'poster_url' => null,
            'is_featured' => false,
            'status' => Event::STATUS_DRAFT,
        ];
    }

    /** Nullable audit columns are not mass-assignable; keep the model table-shaped. */
    public function configure(): static
    {
        return $this->afterMaking(function (Event $event) {
            $event->forceFill([
                'created_by' => $event->created_by ?? null,
                'updated_by' => $event->updated_by ?? null,
            ]);
        });
    }

    public function published(): static
    {
        return $this->state(fn () => ['status' => Event::STATUS_PUBLISHED]);
    }

    public function cancelled(): static
    {
        return $this->state(fn () => ['status' => Event::STATUS_CANCELLED]);
    }

    public function featured(): static
    {
        return $this->state(fn () => [
            'status' => Event::STATUS_PUBLISHED,
            'is_featured' => true,
        ]);
    }

    public function past(): static
    {
        return $this->state(fn () => [
            'status' => Event::STATUS_PUBLISHED,
            'start_at' => now()->subDays(10)->setTime(18, 0),
            'end_at' => now()->subDays(10)->setTime(20, 0),
        ]);
    }

    /** The daily aarti: one row, not a row a day. */
    public function dailyAarti(): static
    {
        return $this->state(fn () => [
            'event_type' => EventType::AARTI,
            'title_hi' => 'संध्या आरती',
            'title_en' => 'Evening aarti',
            'status' => Event::STATUS_PUBLISHED,
            'start_at' => now()->subMonths(6)->setTime(18, 30),
            'end_at' => now()->subMonths(6)->setTime(19, 0),
            'recurrence' => Event::RECURRENCE_DAILY,
        ]);
    }

    /** @param  list<int>  $days ISO weekdays, 1 = Monday */
    public function weeklyOn(array $days): static
    {
        return $this->state(fn () => [
            'event_type' => EventType::BHAJAN_KIRTAN,
            'status' => Event::STATUS_PUBLISHED,
            'recurrence' => Event::RECURRENCE_WEEKLY,
            'recurrence_days' => $days,
        ]);
    }

    public function hindiOnly(): static
    {
        return $this->state(fn () => [
            'title_en' => null,
            'description_en' => null,
            'venue_en' => null,
        ]);
    }
}

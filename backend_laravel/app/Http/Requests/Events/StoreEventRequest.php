<?php

declare(strict_types=1);

namespace App\Http\Requests\Events;

use App\Models\Event;
use App\Support\EventType;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validation for creating and editing an event.
 *
 * Hindi title, a type, a start and a status are required; a calendar entry with
 * no name or no date is not an event. The `end_at >= start_at` rule is repeated
 * in EventService so it holds however the record is reached.
 */
class StoreEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::EVENTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'event_type' => ['required', Rule::in(EventType::all())],
            'title_hi' => ['required', 'string', 'max:200'],
            'title_en' => ['nullable', 'string', 'max:200'],
            'description_hi' => ['nullable', 'string', 'max:20000'],
            'description_en' => ['nullable', 'string', 'max:20000'],
            'venue_hi' => ['nullable', 'string', 'max:200'],
            'venue_en' => ['nullable', 'string', 'max:200'],

            'start_at' => ['required', 'date'],
            'end_at' => ['nullable', 'date', 'after_or_equal:start_at'],

            'recurrence' => ['nullable', Rule::in(Event::recurrences())],
            'recurrence_days' => ['nullable', 'array', 'max:7'],
            'recurrence_days.*' => ['integer', 'min:1', 'max:7'],
            'recurrence_until' => ['nullable', 'date'],

            // A URL, not an upload, until Phase 5 builds media handling.
            'poster_url' => ['nullable', 'url', 'max:500'],

            'is_featured' => ['nullable', 'boolean'],
            'status' => ['required', Rule::in(Event::statuses())],
        ];
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Requests\Enquiries;

use App\Support\EnquiryCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * A message from the public contact form.
 *
 * The only request in this application that anybody at all may make, so the
 * rules are tighter than anywhere else: every field is bounded, the category
 * comes from a fixed catalogue, and the anti-spam fields are shaped here before
 * the service ever sees them.
 *
 * `authorize()` returns true because there is nobody to authorize — the
 * protection is the spam guard, the rate limit and the form token, not a
 * permission (PHASE_7_PLAN assumption N2).
 */
class StoreEnquiryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        $min = (int) config('enquiries.min_message_length', 20);
        $max = (int) config('enquiries.max_message_length', 2000);

        return [
            'name' => ['required', 'string', 'min:2', 'max:120'],

            // Individually optional; the pair is not. `EnquiryService` and the
            // rule below both refuse a submission with neither, because an
            // enquiry nobody can answer is not an enquiry (assumption N6).
            'mobile' => ['nullable', 'string', 'max:20', 'regex:/^[0-9+\-\s()]{6,20}$/'],
            'email' => ['nullable', 'email:rfc', 'max:190'],

            'category' => ['required', Rule::in(EnquiryCategory::all())],
            'message' => ['required', 'string', 'min:'.$min, 'max:'.$max],
            'preferred_language' => ['nullable', Rule::in(['hi', 'en'])],

            // Anti-spam. The token is required; the answer only when the server
            // has decided this address must answer one.
            'form_token' => ['required', 'string', 'max:200'],
            'challenge_answer' => ['nullable', 'string', 'max:20'],

            // The honeypot. A field no human sees, so anything in it is a bot —
            // handled in the controller, which answers as though it succeeded
            // rather than telling the script it was spotted.
            'website' => ['nullable', 'string', 'max:200'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'message.min' => 'Please write a little more so the committee can understand your question.',
            'message.max' => 'That message is too long. Please shorten it, or telephone the temple.',
            'mobile.regex' => 'That does not look like a telephone number.',
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'name' => is_string($this->input('name')) ? trim($this->input('name')) : $this->input('name'),
            // Empty strings arrive from a form field the visitor left alone;
            // they mean "not given", and `nullable` would otherwise fail them.
            'mobile' => $this->blankToNull('mobile'),
            'email' => $this->blankToNull('email'),
            'challenge_answer' => $this->blankToNull('challenge_answer'),
        ]);
    }

    private function blankToNull(string $key): ?string
    {
        $value = $this->input($key);

        if (! is_string($value)) {
            return null;
        }

        return trim($value) === '' ? null : trim($value);
    }
}

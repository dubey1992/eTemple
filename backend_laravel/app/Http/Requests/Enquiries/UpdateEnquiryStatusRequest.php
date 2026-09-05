<?php

declare(strict_types=1);

namespace App\Http\Requests\Enquiries;

use App\Models\Enquiry;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Moving an enquiry along, or handing it to somebody.
 *
 * The *shape* only. That the assignee can actually open the inbox is checked in
 * `EnquiryService` against the live permission matrix, not here: a rule that
 * only asks "is this a user id" would happily send an enquiry to a Treasurer
 * who cannot read it (PHASE_7_PLAN assumption N11).
 */
class UpdateEnquiryStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ENQUIRIES_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'status' => ['sometimes', Rule::in(Enquiry::statuses())],
            'assigned_to' => ['sometimes', 'nullable', 'integer', 'exists:users,id'],
        ];
    }
}

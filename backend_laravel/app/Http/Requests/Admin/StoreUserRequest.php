<?php

declare(strict_types=1);

namespace App\Http\Requests\Admin;

use App\Models\User;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Creating a committee account.
 *
 * No password field: the account is created without a usable one and the member
 * sets their own through the mailed reset link (PHASE_2_PLAN assumption C5).
 */
class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::USERS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'first_name' => ['required', 'string', 'max:100'],
            'last_name' => ['nullable', 'string', 'max:100'],
            'email' => ['required', 'string', 'email:rfc', 'max:191', Rule::unique('users', 'email')],
            'mobile' => ['nullable', 'string', 'max:20'],
            'role_id' => ['required', 'integer', Rule::exists('roles', 'id')->where('status', 'active')],
            'status' => ['sometimes', Rule::in([User::STATUS_ACTIVE, User::STATUS_INACTIVE, User::STATUS_BLOCKED])],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('email'))) {
            $this->merge(['email' => mb_strtolower(trim($this->input('email')))]);
        }
    }
}

<?php

declare(strict_types=1);

namespace App\Services\Admin;

use App\Exceptions\AdminGuardException;
use App\Models\Role;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

/**
 * Committee account management, including the guards that stop an administrator
 * locking themselves — or everyone — out of the temple's own site.
 */
class UserService
{
    /**
     * @param  array{search?: string|null, role?: string|null, status?: string|null}  $filters
     * @return LengthAwarePaginator<int, User>
     */
    public function paginate(array $filters = [], int $perPage = 25): LengthAwarePaginator
    {
        return User::query()
            ->with('role')
            ->when(
                ($filters['search'] ?? null) !== null,
                fn (Builder $q) => $q->where(function (Builder $inner) use ($filters) {
                    $term = '%'.$filters['search'].'%';
                    $inner->where('first_name', 'like', $term)
                        ->orWhere('last_name', 'like', $term)
                        ->orWhere('email', 'like', $term);
                }),
            )
            ->when(
                ($filters['role'] ?? null) !== null,
                fn (Builder $q) => $q->whereRelation('role', 'slug', $filters['role']),
            )
            ->when(
                ($filters['status'] ?? null) !== null,
                fn (Builder $q) => $q->where('status', $filters['status']),
            )
            ->orderBy('first_name')
            ->orderBy('id')
            ->paginate(min(max($perPage, 1), 100));
    }

    /**
     * Create an account and mail a reset link.
     *
     * The creator never chooses a password. The account is stored with an
     * unusable random hash and the new member sets their own password through
     * the reset link, so a plaintext password is never passed around the
     * committee over WhatsApp (PHASE_2_PLAN assumption C5).
     *
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): User
    {
        $user = new User;
        $user->fill([
            'first_name' => $attributes['first_name'],
            'last_name' => $attributes['last_name'] ?? null,
            'email' => mb_strtolower(trim((string) $attributes['email'])),
            'mobile' => $attributes['mobile'] ?? null,
            'role_id' => $attributes['role_id'],
            'status' => $attributes['status'] ?? User::STATUS_ACTIVE,
            // Random and never disclosed: nothing can authenticate with it.
            'password' => Str::random(64),
        ]);
        $user->forceFill(['last_login_at' => null, 'remember_token' => null]);
        $user->save();

        $this->sendPasswordResetLink($user);

        return $user->refresh()->load('role');
    }

    /**
     * Apply an edit, refusing the changes that would remove administration.
     *
     * @param  array<string, mixed>  $attributes
     */
    public function update(User $user, array $attributes, User $editor): User
    {
        $isSelf = $user->is($editor);

        if (array_key_exists('role_id', $attributes)
            && (int) $attributes['role_id'] !== $user->role_id) {
            if ($isSelf) {
                throw AdminGuardException::cannotChangeOwnRole();
            }
            $this->assertNotLastSuperAdmin($user, 'role_id');
        }

        if (array_key_exists('status', $attributes)
            && $attributes['status'] !== $user->status) {
            if ($isSelf) {
                throw AdminGuardException::cannotChangeOwnStatus();
            }
            if ($attributes['status'] !== User::STATUS_ACTIVE) {
                $this->assertNotLastSuperAdmin($user, 'status');
            }
        }

        foreach (['first_name', 'role_id', 'status'] as $field) {
            if (isset($attributes[$field])) {
                $user->{$field} = $attributes[$field];
            }
        }

        // Nullable columns: an explicit null in the payload is a real edit,
        // so presence of the key is what matters, not truthiness.
        foreach (['last_name', 'mobile'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $user->{$field} = $attributes[$field];
            }
        }

        if (isset($attributes['email'])) {
            $user->email = mb_strtolower(trim((string) $attributes['email']));
        }

        $user->save();

        return $user->refresh()->load('role');
    }

    public function sendPasswordResetLink(User $user): void
    {
        Password::broker()->sendResetLink(['email' => $user->email]);
    }

    /**
     * Refuse to demote or disable the only remaining active Super Admin.
     *
     * @throws AdminGuardException
     */
    private function assertNotLastSuperAdmin(User $user, string $field): void
    {
        if (! $user->isSuperAdmin() || ! $user->isActive()) {
            return;
        }

        $remaining = User::query()
            ->whereRelation('role', 'slug', Role::SUPER_ADMIN)
            ->where('status', User::STATUS_ACTIVE)
            ->whereKeyNot($user->getKey())
            ->count();

        if ($remaining === 0) {
            throw AdminGuardException::lastSuperAdmin($field);
        }
    }
}

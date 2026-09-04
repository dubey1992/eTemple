<?php

declare(strict_types=1);

namespace App\Services\Admin;

use App\Models\LoginAttempt;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class LoginHistoryService
{
    /**
     * Recent sign-in attempts for one account, newest first.
     *
     * @return LengthAwarePaginator<int, LoginAttempt>
     */
    public function forUser(User $user, int $perPage = 25): LengthAwarePaginator
    {
        return LoginAttempt::query()
            ->where('user_id', $user->getKey())
            ->latest('created_at')
            ->latest('id')
            ->paginate(min(max($perPage, 1), 100));
    }
}

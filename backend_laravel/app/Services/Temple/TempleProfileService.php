<?php

declare(strict_types=1);

namespace App\Services\Temple;

use App\Models\TempleProfile;
use App\Models\User;

/**
 * Business rules for the temple-profile singleton.
 *
 * This row is authoritative for the temple's name and address. Phase 1 kept the
 * address in site_settings and the Flutter client rendered the name from its ARB
 * files; both now read from here (PHASE_3_PLAN assumptions D2 and D3).
 */
class TempleProfileService
{
    /**
     * The one profile row, created empty on first access.
     *
     * Empty is the correct initial state: the specification forbids shipping
     * invented temple content, so an unconfigured site shows empty states until
     * the committee fills it in.
     */
    public function current(): TempleProfile
    {
        return TempleProfile::query()->oldest('id')->firstOr(
            callback: static fn () => TempleProfile::query()->create([]),
        );
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(array $attributes, User $editor): TempleProfile
    {
        $profile = $this->current();
        $profile->fill($attributes);
        $profile->updated_by = $editor->id;
        $profile->save();

        return $profile->refresh();
    }
}

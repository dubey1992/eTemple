<?php

declare(strict_types=1);

namespace App\Services\Temple;

use App\Models\TempleProfile;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;

/**
 * Business rules for the temple-profile singleton.
 *
 * This row is authoritative for the temple's name and address. Phase 1 kept the
 * address in site_settings and the Flutter client rendered the name from its ARB
 * files; both now read from here (PHASE_3_PLAN assumptions D2 and D3).
 */
class TempleProfileService
{
    public function __construct(private readonly AuditLogger $audit) {}

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
        // The values as they stand, for exactly the keys about to be
        // written. Only the ones that really change reach the trail.
        $before = $profile->only(array_keys($attributes));
        $profile->fill($attributes);
        $profile->updated_by = $editor->id;
        $profile->save();

        // Settings are the site's own configuration; a change here is
        // visible to every visitor, so it leaves a trace.
        $this->audit->recordChange(
            action: AuditAction::TEMPLE_PROFILE_UPDATED,
            entity: $profile,
            before: $before,
            after: $profile->only(array_keys($before)),
        );

        return $profile->refresh();
    }
}

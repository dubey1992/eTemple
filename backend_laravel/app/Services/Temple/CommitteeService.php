<?php

declare(strict_types=1);

namespace App\Services\Temple;

use App\Exceptions\CommitteeGuardException;
use App\Models\CommitteeMember;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Business rules for the management committee, including the consent gate on
 * members' personal details.
 *
 * The gate has three independent layers and this class is the first two:
 *
 *   1. a visibility flag cannot be set while consent is unrecorded — 422;
 *   2. withdrawing consent clears every visibility flag in the same
 *      transaction, so a stale `true` cannot survive the withdrawal;
 *   3. (in PublicCommitteeMemberResource) the serializer asks again before it
 *      emits any personal field.
 *
 * Three layers for one rule is deliberate. These rows describe named villagers,
 * and the cost of getting it wrong is publishing somebody's phone number
 * without their permission.
 */
class CommitteeService
{
    public function __construct(private readonly AuditLogger $audit) {}

    /**
     * The members a visitor may see: published, still serving, in display order.
     *
     * @return Collection<int, CommitteeMember>
     */
    public function publicList(): Collection
    {
        return CommitteeMember::query()
            ->publiclyVisible()
            ->inDisplayOrder()
            ->get();
    }

    /**
     * Every member, including unpublished and past ones.
     *
     * Committee membership is village history; a term ending is not a reason to
     * lose the record.
     *
     * @return Collection<int, CommitteeMember>
     */
    public function adminList(): Collection
    {
        return CommitteeMember::query()
            ->inDisplayOrder()
            ->with(['consentRecordedBy:id,first_name,last_name'])
            ->get();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes, User $actor): CommitteeMember
    {
        return DB::transaction(function () use ($attributes, $actor) {
            $member = new CommitteeMember;
            $this->apply($member, $attributes, $actor);
            $member->created_by = $actor->id;
            $member->updated_by = $actor->id;
            $member->save();

            return $member->refresh();
        });
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(CommitteeMember $member, array $attributes, User $actor): CommitteeMember
    {
        return DB::transaction(function () use ($member, $attributes, $actor) {
            $this->apply($member, $attributes, $actor);
            $member->updated_by = $actor->id;
            $member->save();

            return $member->refresh();
        });
    }

    /**
     * Remove a member permanently.
     *
     * Distinct from ending a tenure, which retires somebody while keeping the
     * record. This is erasure, and it exists because a person may ask for their
     * personal data to be deleted and "we can only hide it" is not an answer
     * (PHASE_3_PLAN assumption D7).
     */
    public function delete(CommitteeMember $member): void
    {
        $this->audit->record(
            action: AuditAction::COMMITTEE_MEMBER_DELETED,
            entity: $member,
            before: ['name_hi' => $member->name_hi, 'designation_hi' => $member->designation_hi],
            label: $member->name_hi,
        );

        $member->delete();
    }

    /**
     * Apply an editor's input, enforcing the consent gate and the tenure rule.
     *
     * @param  array<string, mixed>  $attributes
     */
    private function apply(CommitteeMember $member, array $attributes, User $actor): void
    {
        $requestedFlags = [];
        foreach (array_keys(CommitteeMember::CONSENT_GATED) as $flag) {
            if (array_key_exists($flag, $attributes)) {
                $requestedFlags[$flag] = (bool) $attributes[$flag];
            }
            unset($attributes[$flag]);
        }

        $consentRequested = array_key_exists('has_consent', $attributes)
            ? (bool) $attributes['has_consent']
            : null;
        unset($attributes['has_consent']);

        $member->fill($attributes);

        $this->assertTenureIsOrdered($member);

        $hasConsent = $this->resolveConsent($member, $consentRequested, $actor);

        foreach (CommitteeMember::CONSENT_GATED as $flag => $_column) {
            $wanted = $requestedFlags[$flag] ?? (bool) $member->{$flag};

            if ($wanted && ! $hasConsent) {
                // An explicit request to publish a detail without consent is a
                // contradiction and is refused by name. A flag merely left over
                // from before is cleared silently below.
                if (($requestedFlags[$flag] ?? false) === true) {
                    throw CommitteeGuardException::consentRequired($flag);
                }
            }

            $member->{$flag} = $wanted && $hasConsent;
        }
    }

    /**
     * Record or withdraw consent, returning whether it is on file afterwards.
     *
     * An existing consent timestamp is never refreshed: the date somebody gave
     * their permission is a fact about the past, not a "last touched" column.
     */
    private function resolveConsent(CommitteeMember $member, ?bool $requested, User $actor): bool
    {
        if ($requested === null) {
            return $member->hasConsent();
        }

        if ($requested === false) {
            $member->contact_consent_at = null;
            $member->consent_recorded_by = null;

            return false;
        }

        if (! $member->hasConsent()) {
            $member->contact_consent_at = Carbon::now();
            $member->consent_recorded_by = $actor->id;
        }

        return true;
    }

    private function assertTenureIsOrdered(CommitteeMember $member): void
    {
        if ($member->tenure_start === null || $member->tenure_end === null) {
            return;
        }

        if ($member->tenure_end->isBefore($member->tenure_start)) {
            throw CommitteeGuardException::tenureEndsBeforeItStarts();
        }
    }
}

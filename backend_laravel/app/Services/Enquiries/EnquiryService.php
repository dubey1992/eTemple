<?php

declare(strict_types=1);

namespace App\Services\Enquiries;

use App\Exceptions\EnquiryGuardException;
use App\Mail\EnquiryAcknowledgement;
use App\Models\Enquiry;
use App\Models\User;
use App\Support\Permission;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\QueryException;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use RuntimeException;

/**
 * Everything the enquiry inbox does.
 *
 * Controllers here are thin by rule; this is where the rules live — that a
 * reference is unique, that an enquiry can only be assigned to somebody able to
 * act on it, that `resolved_at` means what it says, and that an acknowledgement
 * cannot be sent twice or weaponised.
 */
class EnquiryService
{
    /** Enough to survive a realistic race on the reference sequence. */
    private const MAX_REFERENCE_ATTEMPTS = 10;

    public function __construct(
        private readonly EnquiryReferenceGenerator $references,
        private readonly EnquirySpamGuard $spam,
    ) {}

    /**
     * Stores a message from the public form.
     *
     * The reference is claimed against the unique index and retried on
     * collision, for the same reason receipt numbers are (PHASE_6_PLAN N2): two
     * visitors submitting in the same second both compute the same next
     * sequence, and only the database can settle which of them gets it.
     *
     * @param  array{name: string, mobile: ?string, email: ?string, category: string, message: string, preferred_language: string}  $attributes
     */
    public function record(array $attributes, string $ipHash, ?string $userAgent): Enquiry
    {
        $enquiry = new Enquiry;
        $enquiry->fill($attributes);
        $enquiry->status = Enquiry::STATUS_NEW;
        $enquiry->submitted_ip_hash = $ipHash;
        // Truncated, not validated: a user agent is a free-text header, and the
        // column is 255 characters. Anything longer is a client being strange.
        $enquiry->submitted_user_agent = $userAgent === null
            ? null
            : mb_substr($userAgent, 0, 255);

        for ($attempt = 0; $attempt < self::MAX_REFERENCE_ATTEMPTS; $attempt++) {
            $enquiry->reference = $this->references->next();

            try {
                $enquiry->save();

                $this->spam->recordSubmission($ipHash);
                $this->acknowledge($enquiry);

                return $enquiry;
            } catch (QueryException $exception) {
                if (! $this->isUniqueViolation($exception)) {
                    throw $exception;
                }
            }
        }

        throw new RuntimeException(
            'Could not issue a unique enquiry reference after '.self::MAX_REFERENCE_ATTEMPTS.' attempts.',
        );
    }

    /**
     * The inbox.
     *
     * Spam is excluded unless it is asked for by name, so the default view is
     * what somebody actually has to deal with.
     *
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, Enquiry>
     */
    public function list(array $filters = []): LengthAwarePaginator
    {
        $perPage = max(1, min(
            (int) ($filters['per_page'] ?? config('enquiries.default_per_page', 25)),
            (int) config('enquiries.max_per_page', 100),
        ));

        return $this->filtered($filters)
            ->with(['assignee:id,first_name,last_name', 'resolver:id,first_name,last_name'])
            ->inInboxOrder()
            ->paginate($perPage);
    }

    /**
     * How many are waiting, by status.
     *
     * Counted by the database over the whole table rather than over a page, and
     * with the status filter dropped — a summary that honoured it would report
     * "new: 0" to somebody who was looking at the resolved tab.
     *
     * @param  array<string, mixed>  $filters
     * @return array{new: int, in_progress: int, resolved: int, spam: int, open: int}
     */
    public function summary(array $filters = []): array
    {
        $base = fn () => $this->filtered(
            array_diff_key($filters, ['status' => null]),
            includeSpam: true,
        );

        $counts = [
            'new' => (int) $base()->where('status', Enquiry::STATUS_NEW)->count(),
            'in_progress' => (int) $base()->where('status', Enquiry::STATUS_IN_PROGRESS)->count(),
            'resolved' => (int) $base()->where('status', Enquiry::STATUS_RESOLVED)->count(),
            'spam' => (int) $base()->where('status', Enquiry::STATUS_SPAM)->count(),
        ];

        return $counts + ['open' => $counts['new'] + $counts['in_progress']];
    }

    /**
     * Moves an enquiry along, and records who moved it.
     *
     * `resolved_at` is stamped on the way in and cleared on the way out, so it
     * always answers "when was this closed" rather than "when was it last
     * touched" (PHASE_7_PLAN assumption N7).
     *
     * @param  array{status?: string, assigned_to?: int|null}  $attributes
     */
    public function updateStatus(Enquiry $enquiry, array $attributes, User $actor): Enquiry
    {
        if (array_key_exists('assigned_to', $attributes)) {
            $assignee = $attributes['assigned_to'];

            if ($assignee !== null) {
                $this->assertCanHandleEnquiries((int) $assignee);
            }

            $enquiry->assigned_to = $assignee;
        }

        if (array_key_exists('status', $attributes)) {
            $status = $attributes['status'];

            if ($status === Enquiry::STATUS_RESOLVED) {
                // Re-resolving an already resolved enquiry keeps the original
                // closing time: it was closed when it was closed.
                $enquiry->resolved_at ??= now();
                $enquiry->resolved_by ??= $actor->id;
            } else {
                $enquiry->resolved_at = null;
                $enquiry->resolved_by = null;
            }

            $enquiry->status = $status;
        }

        $enquiry->save();

        return $enquiry->fresh(['assignee', 'resolver']) ?? $enquiry;
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return Builder<Enquiry>
     */
    private function filtered(array $filters, bool $includeSpam = false): Builder
    {
        $query = Enquiry::query();

        $status = $filters['status'] ?? null;
        if (is_string($status) && in_array($status, Enquiry::statuses(), true)) {
            $query->where('status', $status);
        } elseif (! $includeSpam) {
            $query->notSpam();
        }

        if (isset($filters['category']) && is_string($filters['category'])) {
            $query->where('category', $filters['category']);
        }

        // The period. Added for the Phase 10 report, and put here rather than
        // in the report because a filter the caller asks for and the service
        // silently ignores is worse than one that does not exist: the rows
        // would be all-time data under a heading naming a period
        // (PHASE_10_PLAN assumption N9).
        if (isset($filters['from'])) {
            $query->whereDate('created_at', '>=', $filters['from']);
        }

        if (isset($filters['to'])) {
            $query->whereDate('created_at', '<=', $filters['to']);
        }

        if (isset($filters['assigned_to'])) {
            $assigned = $filters['assigned_to'];
            $assigned === 'unassigned'
                ? $query->whereNull('assigned_to')
                : $query->where('assigned_to', (int) $assigned);
        }

        if (isset($filters['search']) && is_string($filters['search']) && trim($filters['search']) !== '') {
            $term = '%'.addcslashes(trim($filters['search']), '%_\\').'%';

            $query->where(function (Builder $inner) use ($term) {
                $inner->where('reference', 'like', $term)
                    ->orWhere('name', 'like', $term)
                    ->orWhere('mobile', 'like', $term)
                    ->orWhere('email', 'like', $term)
                    ->orWhere('message', 'like', $term);
            });
        }

        return $query;
    }

    /**
     * Assignment only to somebody who can open the inbox.
     *
     * Checked on the server against the live permission matrix rather than
     * against a list the client sent: assigning an enquiry to a Treasurer, who
     * cannot read it, is a silent black hole (assumption N11).
     *
     * @throws EnquiryGuardException
     */
    private function assertCanHandleEnquiries(int $userId): void
    {
        $user = User::query()->with('role')->find($userId);

        if ($user === null || ! $user->isActive()) {
            throw EnquiryGuardException::assigneeCannotHandleEnquiries();
        }

        if (! $user->isSuperAdmin() && ! $user->hasPermission(Permission::ENQUIRIES_MANAGE)) {
            throw EnquiryGuardException::assigneeCannotHandleEnquiries();
        }
    }

    /**
     * Queues the acknowledgement, if the committee has turned it on.
     *
     * Three guards, all of them about the same risk: the address was typed by
     * whoever filled the form and need not belong to them (assumption N3).
     * Enabled deliberately, at most once per address per hour, and never twice
     * for one enquiry.
     *
     * A mail failure must not fail the submission. The message is already
     * safely stored; losing the courtesy note is not worth telling a villager
     * their enquiry did not go through.
     */
    private function acknowledge(Enquiry $enquiry): void
    {
        if (! config('enquiries.acknowledgement.enabled', false)) {
            return;
        }

        $email = $enquiry->email;
        if ($email === null || $email === '' || $enquiry->acknowledged_at !== null) {
            return;
        }

        $cooldown = max(1, (int) config('enquiries.acknowledgement.per_address_cooldown_minutes', 60));
        $key = 'enquiry-ack:'.hash('sha256', mb_strtolower($email));

        if (! Cache::add($key, true, now()->addMinutes($cooldown))) {
            return;
        }

        try {
            Mail::to($email)->queue(new EnquiryAcknowledgement($enquiry));

            $enquiry->acknowledged_at = now();
            $enquiry->save();
        } catch (\Throwable $exception) {
            Log::warning('Enquiry acknowledgement could not be queued.', [
                'reference' => $enquiry->reference,
                'exception' => $exception->getMessage(),
            ]);
        }
    }

    private function isUniqueViolation(QueryException $exception): bool
    {
        return in_array((string) ($exception->errorInfo[0] ?? ''), ['23000', '23505'], true);
    }
}
